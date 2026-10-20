using System;
using System.Runtime.InteropServices;
using System.Runtime.Versioning;
using Godot;

/// <summary>Copies a screen area (Win32 coordinates) with our own window kept out of the copy.</summary>
[SupportedOSPlatform("windows")]
internal static class ScreenCapture
{
    private const uint SrcCopy = 0x00CC0020;
    private const uint WdaNone = 0x0;
    /// <summary>Shown on the monitor, left out of captures (Windows 10 2004 and later).</summary>
    private const uint WdaExcludeFromCapture = 0x11;
    private const uint BiRgb = 0;
    private const uint DibRgbColors = 0;
    private const ushort BitsPerPixel = 32;
    private const int BytesPerPixel = 4;
    private const byte Opaque = 255;

    [StructLayout(LayoutKind.Sequential)]
    private struct BitmapInfoHeader
    {
        public int Size;
        public int Width;
        public int Height; // negative: rows run top to bottom
        public ushort Planes;
        public ushort BitCount;
        public uint Compression;
        public uint SizeImage;
        public int XPelsPerMeter;
        public int YPelsPerMeter;
        public uint ClrUsed;
        public uint ClrImportant;
    }

    /// <summary>The screen's pixels in <paramref name="area"/>, leaving out <paramref name="ownWindow"/> where Windows allows it.</summary>
    public static Image Copy(Rect2I area, IntPtr ownWindow)
    {
        bool excluded = ownWindow != IntPtr.Zero && SetWindowDisplayAffinity(ownWindow, WdaExcludeFromCapture);
        if (excluded)
            DwmFlush(); // wait for a composition without it
        try
        {
            return CopyPixels(area);
        }
        finally
        {
            if (excluded)
                SetWindowDisplayAffinity(ownWindow, WdaNone);
        }
    }

    private static Image CopyPixels(Rect2I area)
    {
        int width = area.Size.X, height = area.Size.Y;
        IntPtr screen = GetDC(IntPtr.Zero);
        IntPtr memory = CreateCompatibleDC(screen);
        var header = new BitmapInfoHeader
        {
            Size = Marshal.SizeOf<BitmapInfoHeader>(), Width = width, Height = -height, Planes = 1,
            BitCount = BitsPerPixel, Compression = BiRgb,
        };
        IntPtr bitmap = CreateDIBSection(screen, ref header, DibRgbColors, out IntPtr bits, IntPtr.Zero, 0);
        IntPtr previous = SelectObject(memory, bitmap);
        try
        {
            BitBlt(memory, 0, 0, width, height, screen, area.Position.X, area.Position.Y, SrcCopy);
            GdiFlush();
            var pixels = new byte[width * height * BytesPerPixel];
            Marshal.Copy(bits, pixels, 0, pixels.Length);
            for (int i = 0; i < pixels.Length; i += BytesPerPixel)
            {
                (pixels[i], pixels[i + 2]) = (pixels[i + 2], pixels[i]); // BGRA to RGBA
                pixels[i + 3] = Opaque;
            }
            return Image.CreateFromData(width, height, false, Image.Format.Rgba8, pixels);
        }
        finally
        {
            SelectObject(memory, previous);
            DeleteObject(bitmap);
            DeleteDC(memory);
            ReleaseDC(IntPtr.Zero, screen);
        }
    }

    [DllImport("user32.dll")] private static extern bool SetWindowDisplayAffinity(IntPtr hwnd, uint affinity);
    [DllImport("user32.dll")] private static extern IntPtr GetDC(IntPtr hwnd);
    [DllImport("user32.dll")] private static extern int ReleaseDC(IntPtr hwnd, IntPtr hdc);
    [DllImport("dwmapi.dll")] private static extern int DwmFlush();
    [DllImport("gdi32.dll")] private static extern IntPtr CreateCompatibleDC(IntPtr hdc);
    [DllImport("gdi32.dll")] private static extern bool DeleteDC(IntPtr hdc);
    [DllImport("gdi32.dll")] private static extern IntPtr CreateDIBSection(IntPtr hdc, ref BitmapInfoHeader header, uint usage, out IntPtr bits, IntPtr section, uint offset);
    [DllImport("gdi32.dll")] private static extern IntPtr SelectObject(IntPtr hdc, IntPtr gdiObject);
    [DllImport("gdi32.dll")] private static extern bool DeleteObject(IntPtr gdiObject);
    [DllImport("gdi32.dll")] private static extern bool BitBlt(IntPtr destination, int x, int y, int width, int height, IntPtr source, int sourceX, int sourceY, uint rasterOperation);
    [DllImport("gdi32.dll")] private static extern bool GdiFlush();
}
