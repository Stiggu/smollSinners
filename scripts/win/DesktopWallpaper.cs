using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Runtime.Versioning;
using Godot;

/// <summary>Each monitor's wallpaper file, layout and background (IDesktopWallpaper; placeholders hold vtable slots).</summary>
[SupportedOSPlatform("windows")]
internal static class DesktopWallpaper
{
    private static readonly Guid ClsidDesktopWallpaper = new("C2CF3110-460E-4FC1-B9D0-8A1C0C9CC4BD");

    /// <summary>DESKTOP_WALLPAPER_POSITION's values, by the names GDScript gets.</summary>
    private static readonly string[] Positions = { "center", "tile", "stretch", "fit", "fill", "span" };

    /// <param name="Area">The monitor, in Win32 screen coordinates.</param>
    /// <param name="File">Its wallpaper's file; empty for a solid colour.</param>
    public readonly record struct Monitor(Rect2I Area, string File);

    /// <param name="Position">"center", "tile", "stretch", "fit", "fill" or "span" (for every monitor).</param>
    /// <param name="Background">Shows where the picture doesn't reach, and on its own without one.</param>
    public sealed record Layout(List<Monitor> Monitors, string Position, Color Background);

    public static Layout Read()
    {
        var wallpaper = (IDesktopWallpaper)Activator.CreateInstance(Type.GetTypeFromCLSID(ClsidDesktopWallpaper, true));
        try
        {
            var monitors = new List<Monitor>();
            for (uint i = 0; i < wallpaper.GetMonitorDevicePathCount(); i++)
            {
                string id = wallpaper.GetMonitorDevicePathAt(i);
                var area = wallpaper.GetMonitorRECT(id);
                if (!area.IsEmpty) // a monitor that's switched off
                    monitors.Add(new Monitor(area.ToRect2I(), wallpaper.GetWallpaper(id) ?? ""));
            }
            int position = wallpaper.GetPosition();
            return new Layout(monitors, position < Positions.Length ? Positions[position] : "fill", FromColorRef(wallpaper.GetBackgroundColor()));
        }
        finally
        {
            Marshal.ReleaseComObject(wallpaper);
        }
    }

    /// <summary>A COLORREF is 0x00BBGGRR.</summary>
    private static Color FromColorRef(uint colorRef) =>
        Color.Color8((byte)(colorRef & 0xFF), (byte)((colorRef >> 8) & 0xFF), (byte)((colorRef >> 16) & 0xFF));

    [ComImport, Guid("B92B56A9-8B55-4E14-9A89-0199BBB6F93B"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    private interface IDesktopWallpaper
    {
        void SetWallpaper();
        [return: MarshalAs(UnmanagedType.LPWStr)]
        string GetWallpaper([MarshalAs(UnmanagedType.LPWStr)] string monitorId);
        [return: MarshalAs(UnmanagedType.LPWStr)]
        string GetMonitorDevicePathAt(uint monitorIndex);
        uint GetMonitorDevicePathCount();
        Win32.Rect GetMonitorRECT([MarshalAs(UnmanagedType.LPWStr)] string monitorId);
        void SetBackgroundColor();
        uint GetBackgroundColor();
        void SetPosition();
        int GetPosition();
    }
}
