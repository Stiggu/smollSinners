using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Runtime.Versioning;
using System.Text;
using Godot;

/// <summary>
/// Which parts of the screen show the desktop: the windows stacked above it, and what they
/// leave uncovered. Screen coordinates are Win32's (0,0 at the main monitor's top-left).
/// </summary>
[SupportedOSPlatform("windows")]
internal static class DesktopCoverage
{
    /// <summary>The window classes that make up the desktop itself.</summary>
    private static readonly HashSet<string> DesktopClasses = new() { "Progman", "WorkerW" };
    private const int ClassNameCapacity = 64;

    /// <param name="Area">Where it shows on screen.</param>
    /// <param name="IsDesktop">The desktop itself: everything after it in the z-order is behind it.</param>
    public readonly record struct Window(Rect2I Area, bool IsDesktop);

    /// <summary>
    /// Top-level windows from the top of the z-order down to the desktop, where they show on
    /// screen, skipping ones that can't cover anything: our own, minimized, cloaked, click-through
    /// overlays and fully transparent ones.
    /// </summary>
    public static List<Window> WindowsAboveDesktop()
    {
        var found = new List<Window>();
        var className = new StringBuilder(ClassNameCapacity);
        var ownProcess = (uint)System.Environment.ProcessId;
        Win32.EnumWindows((hwnd, _) =>
        {
            if (!CanCoverTheDesktop(hwnd, ownProcess))
                return true;
            var frame = DrawnFrame(hwnd);
            if (frame.IsEmpty)
                return true;
            className.Clear();
            Win32.GetClassName(hwnd, className, className.Capacity);
            found.Add(new Window(frame.ToRect2I(), DesktopClasses.Contains(className.ToString())));
            return true;
        }, IntPtr.Zero);
        return found;
    }

    /// <summary>How much of <paramref name="area"/> shows the desktop, 0 to 1: what no window covers.</summary>
    public static float UncoveredFraction(Rect2I area)
    {
        if (area.Size.X <= 0 || area.Size.Y <= 0)
            return 0f;
        var open = new List<Rect2I> { area };
        foreach (var window in WindowsAboveDesktop())
        {
            if (!window.Area.Intersects(area))
                continue;
            if (window.IsDesktop)
                break; // everything further down is behind the desktop
            open = Subtract(open, window.Area);
            if (open.Count == 0)
                return 0f;
        }
        long uncovered = 0;
        foreach (var piece in open)
            uncovered += (long)piece.Size.X * piece.Size.Y;
        return (float)((double)uncovered / ((long)area.Size.X * area.Size.Y));
    }

    /// <summary>Whether the topmost window at <paramref name="point"/> is the desktop (or there's none).</summary>
    public static bool IsUncovered(Vector2I point, List<Window> windows)
    {
        foreach (var window in windows)
        {
            if (window.Area.HasPoint(point))
                return window.IsDesktop;
        }
        return true;
    }

    private static bool CanCoverTheDesktop(IntPtr hwnd, uint ownProcess)
    {
        if (!Win32.IsWindowVisible(hwnd) || Win32.IsIconic(hwnd) || IsCloaked(hwnd))
            return false;
        Win32.GetWindowThreadProcessId(hwnd, out var process);
        if (process == ownProcess)
            return false;
        var exStyle = Win32.GetWindowLongPtr(hwnd, Win32.GwlExStyle).ToInt64();
        if ((exStyle & Win32.WsExLayered) == 0)
            return true;
        if ((exStyle & Win32.WsExTransparent) != 0)
            return false; // click-through overlays: game overlays, other pets
        var fadedOut = Win32.GetLayeredWindowAttributes(hwnd, out _, out var alpha, out var flags)
            && (flags & Win32.LwaAlpha) != 0 && alpha == 0;
        return !fadedOut;
    }

    /// <summary>The frame as drawn: GetWindowRect adds invisible resize borders on Windows 10 and 11.</summary>
    private static Win32.Rect DrawnFrame(IntPtr hwnd)
    {
        if (Win32.DwmGetWindowAttribute(hwnd, Win32.DwmwaExtendedFrameBounds, out Win32.Rect frame, Marshal.SizeOf<Win32.Rect>()) != 0)
            Win32.GetWindowRect(hwnd, out frame);
        return frame;
    }

    private static bool IsCloaked(IntPtr hwnd)
    {
        return Win32.DwmGetWindowAttribute(hwnd, Win32.DwmwaCloaked, out int cloaked, sizeof(int)) == 0 && cloaked != 0;
    }

    /// <summary>What's left of <paramref name="rects"/> with <paramref name="cut"/> taken out, as non-overlapping rectangles.</summary>
    private static List<Rect2I> Subtract(List<Rect2I> rects, Rect2I cut)
    {
        var left = new List<Rect2I>(rects.Count + 3);
        foreach (var rect in rects)
        {
            var hit = rect.Intersection(cut);
            if (hit.Size.X <= 0 || hit.Size.Y <= 0)
            {
                left.Add(rect);
                continue;
            }
            // the bands above and below the cut, full width; then the bits beside it
            if (hit.Position.Y > rect.Position.Y)
                left.Add(new Rect2I(rect.Position.X, rect.Position.Y, rect.Size.X, hit.Position.Y - rect.Position.Y));
            if (hit.End.Y < rect.End.Y)
                left.Add(new Rect2I(rect.Position.X, hit.End.Y, rect.Size.X, rect.End.Y - hit.End.Y));
            if (hit.Position.X > rect.Position.X)
                left.Add(new Rect2I(rect.Position.X, hit.Position.Y, hit.Position.X - rect.Position.X, hit.Size.Y));
            if (hit.End.X < rect.End.X)
                left.Add(new Rect2I(hit.End.X, hit.Position.Y, rect.End.X - hit.End.X, hit.Size.Y));
        }
        return left;
    }
}
