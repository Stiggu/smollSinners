using System;
using System.Runtime.InteropServices;
using System.Runtime.Versioning;
using Godot;
using static ShellInterop;

/// <summary>
/// Explorer's view of the desktop folder (IFolderView2): its items, where they sit and the
/// icon grid, the documented way to reach them (Raymond Chen, "Manipulating the positions of
/// desktop icons"). Use it from one STA thread only, and connect again after Explorer restarts.
/// Item positions are in the view's list-view coordinates; screen positions are Win32's.
/// </summary>
[SupportedOSPlatform("windows")]
internal sealed class ExplorerDesktopView
{
    /// <summary>
    /// An item's position is already its icon image's left edge, but the image sits this many
    /// pixels below its top. Measured on a 100%-scale desktop with 48px icons.
    /// </summary>
    private const int IconTopMargin = 4;

    private readonly IFolderView2 _view;
    private readonly IntPtr _listView;

    private ExplorerDesktopView(IFolderView2 view, IntPtr listView)
    {
        _view = view;
        _listView = listView;
    }

    /// <summary>Reach the desktop's folder view through the shell's window list.</summary>
    public static ExplorerDesktopView Connect()
    {
        var shellWindows = (IShellWindows)Activator.CreateInstance(Type.GetTypeFromCLSID(ClsidShellWindows, true));
        object location = CsidlDesktop;
        object root = null;
        var dispatch = shellWindows.FindWindowSW(ref location, ref root, SwcDesktop, out _, SwfoNeedDispatch);
        var service = SidSTopLevelBrowser;
        var iid = typeof(IShellBrowser).GUID;
        var browser = (IShellBrowser)((IComServiceProvider)dispatch).QueryService(ref service, ref iid);
        var shellView = browser.QueryActiveShellView();
        var listView = Win32.FindWindowEx(shellView.GetWindow(), IntPtr.Zero, "SysListView32", null);
        return new ExplorerDesktopView((IFolderView2)shellView, listView);
    }

    public int Count => _view.ItemCount(SvgioAllView);

    public DesktopIcons.Layout ReadLayout()
    {
        _view.GetCurrentFolderFlags(out var flags);
        _view.GetSpacing(out var spacing);
        return new DesktopIcons.Layout((flags & FwfAutoArrange) != 0, (flags & FwfSnapToGrid) != 0, IconSize(),
            new Vector2I(spacing.X, spacing.Y));
    }

    /// <summary>The icons' images are this many pixels square.</summary>
    public int IconSize()
    {
        _view.GetViewModeAndIconSize(out _, out var iconSize);
        return iconSize;
    }

    /// <summary>An item's id (its full parsing path, unique per item) and the name Explorer shows.</summary>
    public (string Id, string Name) Names(int index)
    {
        var iid = typeof(IShellItem).GUID;
        _view.GetItem(index, ref iid, out var found);
        var item = (IShellItem)found;
        try
        {
            return (item.GetDisplayName(SigdnDesktopAbsoluteParsing), item.GetDisplayName(SigdnNormalDisplay));
        }
        finally
        {
            Marshal.ReleaseComObject(item);
        }
    }

    /// <summary>The index of the item with this id, or -1 (deleted or renamed since).</summary>
    public int IndexOf(string id)
    {
        var count = Count;
        for (var i = 0; i < count; i++)
        {
            if (Names(i).Id == id)
                return i;
        }
        return -1;
    }

    public Win32.Point Position(int index)
    {
        var position = new Win32.Point();
        WithPidl(index, pidl => _view.GetItemPosition(pidl, out position));
        return position;
    }

    public void Place(int index, Win32.Point position)
    {
        WithPidl(index, pidl => _view.SelectAndPositionItems(1, new[] { pidl }, new[] { position }, SvsiPositionItem));
    }

    /// <summary>The icon image of an item at this position, on screen.</summary>
    public Rect2I ScreenRect(Win32.Point position, int iconSize)
    {
        var screen = position;
        Win32.ClientToScreen(_listView, ref screen);
        return new Rect2I(screen.X, screen.Y + IconTopMargin, iconSize, iconSize);
    }

    /// <summary>The item position that puts its icon image's top-left at this screen point.</summary>
    public Win32.Point PositionFor(Vector2I iconTopLeft)
    {
        var point = new Win32.Point { X = iconTopLeft.X, Y = iconTopLeft.Y - IconTopMargin };
        Win32.ScreenToClient(_listView, ref point);
        return point;
    }

    private void WithPidl(int index, Action<IntPtr> use)
    {
        _view.Item(index, out var pidl);
        try { use(pidl); }
        finally { Marshal.FreeCoTaskMem(pidl); }
    }
}
