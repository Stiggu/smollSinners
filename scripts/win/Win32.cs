using System;
using System.Runtime.InteropServices;
using System.Runtime.Versioning;
using System.Text;

/// <summary>The user32 and dwmapi calls the Windows glue needs, with their constants named.</summary>
[SupportedOSPlatform("windows")]
internal static class Win32
{
    /// <summary>GetWindowLongPtr / SetWindowLongPtr: the extended window style.</summary>
    public const int GwlExStyle = -20;

    /// <summary>Clicks go through to whatever is underneath (only on a layered window).</summary>
    public const long WsExTransparent = 0x20;
    /// <summary>Kept off the taskbar and Alt+Tab.</summary>
    public const long WsExToolWindow = 0x80;
    /// <summary>Given a taskbar button.</summary>
    public const long WsExAppWindow = 0x40000;
    public const long WsExLayered = 0x80000;

    public const int SwHide = 0;
    public const int SwShowNoActivate = 4;

    /// <summary>GetLayeredWindowAttributes: the alpha value is in use.</summary>
    public const uint LwaAlpha = 0x2;

    /// <summary>A window's frame as drawn, without the invisible resize borders.</summary>
    public const int DwmwaExtendedFrameBounds = 9;
    /// <summary>Hidden by the system: on another virtual desktop, or a suspended app.</summary>
    public const int DwmwaCloaked = 14;

    [StructLayout(LayoutKind.Sequential)]
    public struct Point
    {
        public int X;
        public int Y;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct Rect
    {
        public int Left;
        public int Top;
        public int Right;
        public int Bottom;

        public readonly bool IsEmpty => Right <= Left || Bottom <= Top;

        public readonly Godot.Rect2I ToRect2I() => new(Left, Top, Right - Left, Bottom - Top);
    }

    public delegate bool EnumWindowsProc(IntPtr hwnd, IntPtr lParam);

    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumWindowsProc callback, IntPtr lParam);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr hwnd);
    [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr hwnd);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hwnd, out Rect rect);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetClassName(IntPtr hwnd, StringBuilder name, int maxCount);
    [DllImport("user32.dll", EntryPoint = "GetWindowLongPtrW")] public static extern IntPtr GetWindowLongPtr(IntPtr hwnd, int index);
    [DllImport("user32.dll", EntryPoint = "SetWindowLongPtrW")] public static extern IntPtr SetWindowLongPtr(IntPtr hwnd, int index, IntPtr value);
    [DllImport("user32.dll")] public static extern bool SetLayeredWindowAttributes(IntPtr hwnd, uint colorKey, byte alpha, uint flags);
    [DllImport("user32.dll")] public static extern bool GetLayeredWindowAttributes(IntPtr hwnd, out uint colorKey, out byte alpha, out uint flags);
    [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr hwnd, int command);
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern IntPtr FindWindowEx(IntPtr parent, IntPtr childAfter, string className, string windowName);
    [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr hwnd, ref Point point);
    [DllImport("user32.dll")] public static extern bool ScreenToClient(IntPtr hwnd, ref Point point);
    [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr hwnd, out uint processId);
    [DllImport("dwmapi.dll")] public static extern int DwmGetWindowAttribute(IntPtr hwnd, int attribute, out int value, int size);
    [DllImport("dwmapi.dll")] public static extern int DwmGetWindowAttribute(IntPtr hwnd, int attribute, out Rect value, int size);
}
