using System;
using System.Runtime.Versioning;
using Godot;

/// <summary>
/// Windows calls Godot doesn't expose. Registered as the WinGlue autoload, so GDScript calls
/// it like any autoload: <c>WinGlue.SetClickThrough(true)</c>. GDScript reaches it through
/// the Desktop node (scripts/desktop/desktop.gd) and the overlay.
/// </summary>
[SupportedOSPlatform("windows")]
public partial class WinGlue : Node
{
    private const string MovedIconsFile = "user://moved_icons.json";

    private bool _clickThrough;
    private DesktopIcons _desktopIcons;

    public override void _Ready()
    {
        if (OperatingSystem.IsWindows())
            _desktopIcons = new DesktopIcons(ProjectSettings.GlobalizePath(MovedIconsFile));
    }

    // Puts back any desktop icons we moved.
    public override void _ExitTree() => _desktopIcons?.Dispose();

    /// <summary>
    /// The desktop's icons, refreshed about once a second: dictionaries with "id", "name",
    /// "rect" (the icon image, in Godot screen coordinates) and "visible" (not covered by a window).
    /// </summary>
    public Godot.Collections.Array<Godot.Collections.Dictionary> GetDesktopIcons()
    {
        var result = new Godot.Collections.Array<Godot.Collections.Dictionary>();
        if (_desktopIcons == null)
            return result;
        var offset = Win32ToGodot();
        foreach (var icon in _desktopIcons.Icons)
        {
            result.Add(new Godot.Collections.Dictionary
            {
                ["id"] = icon.Id,
                ["name"] = icon.Name,
                ["rect"] = new Rect2I(icon.Rect.Position + offset, icon.Rect.Size),
                ["visible"] = icon.Visible,
            });
        }
        return result;
    }

    /// <summary>"auto_arrange", "snap_to_grid", "icon_size", "spacing"; empty until the first read.</summary>
    public Godot.Collections.Dictionary GetDesktopLayout()
    {
        var layout = _desktopIcons?.CurrentLayout;
        if (layout == null)
            return new Godot.Collections.Dictionary();
        return new Godot.Collections.Dictionary
        {
            ["auto_arrange"] = layout.AutoArrange,
            ["snap_to_grid"] = layout.SnapToGrid,
            ["icon_size"] = layout.IconSize,
            ["spacing"] = layout.Spacing,
        };
    }

    /// <summary>Moves an icon so its image's top-left is at <paramref name="iconTopLeft"/> (Godot screen coordinates). Asynchronous.</summary>
    public void MoveDesktopIcon(string id, Vector2I iconTopLeft) => _desktopIcons?.Move(id, iconTopLeft - Win32ToGodot());

    /// <summary>Where Explorer last put an icon we moved (Godot screen coordinates); empty if we never moved it.</summary>
    public Rect2I GetPlacedIconRect(string id) =>
        _desktopIcons != null && _desktopIcons.TryGetPlaced(id, out var rect) ? new Rect2I(rect.Position + Win32ToGodot(), rect.Size) : new Rect2I();

    /// <summary>Puts every icon we moved back where it was (unless the user moved it since). Blocks briefly.</summary>
    public void RestoreDesktopIcons() => _desktopIcons?.RestoreAll();

    /// <summary>
    /// How much of a screen area (Godot screen coordinates) shows the desktop, 0 to 1: the part
    /// no other app's window covers. Cheap enough to call a few times a second.
    /// </summary>
    public float DesktopUncoveredFraction(Rect2I area) =>
        OperatingSystem.IsWindows() ? DesktopCoverage.UncoveredFraction(new Rect2I(area.Position - Win32ToGodot(), area.Size)) : 1f;

    /// <summary>What the screen shows in an area (Godot screen coordinates), without this app's window.</summary>
    public Image CaptureScreen(Rect2I area) =>
        ScreenCapture.Copy(new Rect2I(area.Position - Win32ToGodot(), area.Size), MainWindowHandle());

    /// <summary>The wallpaper: "position" (fill, fit...), "background" and "monitors" ({rect, file}); empty on failure.</summary>
    public Godot.Collections.Dictionary GetWallpaper()
    {
        if (!OperatingSystem.IsWindows())
            return new Godot.Collections.Dictionary();
        DesktopWallpaper.Layout layout;
        try
        {
            layout = DesktopWallpaper.Read();
        }
        catch (Exception e)
        {
            GD.PushWarning($"Can't read the wallpaper: {e.Message}");
            return new Godot.Collections.Dictionary();
        }
        var monitors = new Godot.Collections.Array<Godot.Collections.Dictionary>();
        foreach (var monitor in layout.Monitors)
        {
            monitors.Add(new Godot.Collections.Dictionary
            {
                ["rect"] = new Rect2I(monitor.Area.Position + Win32ToGodot(), monitor.Area.Size),
                ["file"] = monitor.File,
            });
        }
        return new Godot.Collections.Dictionary
        {
            ["position"] = layout.Position,
            ["background"] = layout.Background,
            ["monitors"] = monitors,
        };
    }

    /// <summary>Stop re-reading the desktop's icons every second (moves and restores still happen), or start again.</summary>
    public void SetDesktopIconsPaused(bool paused)
    {
        if (_desktopIcons != null)
            _desktopIcons.Paused = paused;
    }

    /// <summary>Why reading the desktop last failed, or "".</summary>
    public string GetDesktopIconsError() => _desktopIcons?.LastError ?? "";

    /// <summary>
    /// When enabled, clicks on the main window go to whatever is underneath it, including
    /// other apps. Godot's own mouse_passthrough flag only forwards clicks within this app.
    /// </summary>
    public void SetClickThrough(bool enabled)
    {
        _clickThrough = enabled;
        ApplyWindowStyle();
    }

    // Godot rewrites the whole extended style when the window's state changes
    // (_update_window_style), so check every frame and restore it if needed.
    public override void _Process(double delta) => ApplyWindowStyle();

    /// <summary>
    /// Add to a Win32 screen position to get Godot's. Win32 puts (0,0) at the primary
    /// monitor's top-left; Godot puts it at the top-left of all monitors, so with a monitor
    /// left of or above the primary the two differ.
    /// </summary>
    private static Vector2I Win32ToGodot() => DisplayServer.ScreenGetPosition(DisplayServer.GetPrimaryScreen());

    private void ApplyWindowStyle()
    {
        var hwnd = MainWindowHandle();
        if (hwnd == IntPtr.Zero)
            return;

        long style = Win32.GetWindowLongPtr(hwnd, Win32.GwlExStyle).ToInt64();
        long wanted = WantedStyle(style);
        if (wanted == style)
            return;

        // The taskbar only drops a window's button when the window is shown again.
        bool leavingTaskbar = (style & Win32.WsExAppWindow) != 0;
        if (leavingTaskbar)
            Win32.ShowWindow(hwnd, Win32.SwHide);
        Win32.SetWindowLongPtr(hwnd, Win32.GwlExStyle, new IntPtr(wanted));
        // A window that just became layered stays invisible until this is called. Flags 0 sets
        // no opacity or colour key, so Godot's per-pixel transparency is left as it was (same as GLFW).
        if ((style & Win32.WsExLayered) == 0 && (wanted & Win32.WsExLayered) != 0)
            Win32.SetLayeredWindowAttributes(hwnd, 0, 0, 0);
        if (leavingTaskbar)
            Win32.ShowWindow(hwnd, Win32.SwShowNoActivate);
    }

    /// <summary>
    /// Off the taskbar and Alt+Tab (Godot gives every main window WS_EX_APPWINDOW), and
    /// click-through when asked. WS_EX_TRANSPARENT only lets clicks reach other apps on a
    /// layered window.
    /// </summary>
    private long WantedStyle(long style)
    {
        long wanted = (style | Win32.WsExToolWindow) & ~Win32.WsExAppWindow;
        return _clickThrough ? wanted | Win32.WsExLayered | Win32.WsExTransparent : wanted & ~Win32.WsExTransparent;
    }

    private static IntPtr MainWindowHandle()
    {
        if (OS.GetName() != "Windows")
            return IntPtr.Zero;
        // 0 when running headless.
        return new IntPtr(DisplayServer.WindowGetNativeHandle(DisplayServer.HandleType.WindowHandle));
    }
}
