using System;
using System.Runtime.InteropServices;

/// <summary>
/// The Explorer COM interfaces used to reach the desktop's icons. Method order is taken from
/// Wine's shobjidl.idl / exdisp.idl; placeholder methods only hold their vtable slot and must
/// never be called.
/// </summary>
internal static class ShellInterop
{
    public static readonly Guid ClsidShellWindows = new("9BA05972-F6A8-11CF-A442-00A0C90A8F39");
    public static readonly Guid SidSTopLevelBrowser = new("4C96BE40-915C-11CF-99D3-00AA004AE837");

    /// <summary>IShellWindows.FindWindowSW: the desktop window.</summary>
    public const int SwcDesktop = 8;
    /// <summary>IShellWindows.FindWindowSW: return its IDispatch.</summary>
    public const int SwfoNeedDispatch = 1;
    /// <summary>The desktop folder's CSIDL.</summary>
    public const int CsidlDesktop = 0;

    /// <summary>IFolderView.ItemCount / Item: every item in the view.</summary>
    public const uint SvgioAllView = 2;
    /// <summary>IFolderView.SelectAndPositionItems: only move them.</summary>
    public const uint SvsiPositionItem = 0x80;
    /// <summary>IFolderView2.GetCurrentFolderFlags: "Auto arrange icons".</summary>
    public const uint FwfAutoArrange = 0x1;
    /// <summary>IFolderView2.GetCurrentFolderFlags: "Align icons to grid".</summary>
    public const uint FwfSnapToGrid = 0x4;

    /// <summary>IShellItem.GetDisplayName: the name as Explorer shows it.</summary>
    public const uint SigdnNormalDisplay = 0;
    /// <summary>IShellItem.GetDisplayName: the full parsing path, unique per item.</summary>
    public const uint SigdnDesktopAbsoluteParsing = 0x80028000;

    [ComImport, Guid("85CB6900-4D95-11CF-960C-0080C7F4EE85"), InterfaceType(ComInterfaceType.InterfaceIsDual)]
    public interface IShellWindows
    {
        int Count { get; }
        void Item();
        void _NewEnum();
        void Register();
        void RegisterPending();
        void Revoke();
        void OnNavigate();
        void OnActivated();
        [return: MarshalAs(UnmanagedType.IDispatch)]
        object FindWindowSW(ref object location, ref object locationRoot, int windowClass, out int hwnd, int options);
    }

    [ComImport, Guid("6D5140C1-7436-11CE-8034-00AA006009FA"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IComServiceProvider
    {
        [return: MarshalAs(UnmanagedType.Interface)]
        object QueryService(ref Guid service, ref Guid riid);
    }

    [ComImport, Guid("000214E2-0000-0000-C000-000000000046"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IShellBrowser
    {
        void GetWindow(); // IOleWindow
        void ContextSensitiveHelp();
        void InsertMenusSB();
        void SetMenuSB();
        void RemoveMenusSB();
        void SetStatusTextSB();
        void EnableModelessSB();
        void TranslateAcceleratorSB();
        void BrowseObject();
        void GetViewStateStream();
        void GetControlWindow();
        void SendControlMsg();
        IShellView QueryActiveShellView();
    }

    [ComImport, Guid("000214E3-0000-0000-C000-000000000046"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IShellView
    {
        IntPtr GetWindow(); // IOleWindow
    }

    [ComImport, Guid("1AF3A467-214F-4298-908E-06B03E0B39F9"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IFolderView2
    {
        // IFolderView
        void GetCurrentViewMode();
        void SetCurrentViewMode();
        void GetFolder();
        void Item(int index, out IntPtr pidl);
        int ItemCount(uint flags);
        void Items();
        void GetSelectionMarkedItem();
        void GetFocusedItem();
        void GetItemPosition(IntPtr pidl, out Win32.Point position);
        void GetSpacing(out Win32.Point spacing);
        void GetDefaultSpacing();
        void GetAutoArrange();
        void SelectItem();
        void SelectAndPositionItems(uint count, [MarshalAs(UnmanagedType.LPArray)] IntPtr[] pidls, [MarshalAs(UnmanagedType.LPArray)] Win32.Point[] positions, uint flags);

        // IFolderView2 (GetGroupBy's [call_as] remote twin shares its slot)
        void SetGroupBy();
        void GetGroupBy();
        void SetViewProperty();
        void GetViewProperty();
        void SetTileViewProperties();
        void SetExtendedTileViewProperties();
        void SetText();
        void SetCurrentFolderFlags();
        void GetCurrentFolderFlags(out uint flags);
        void GetSortColumnCount();
        void SetSortColumns();
        void GetSortColumns();
        void GetItem(int index, ref Guid riid, [MarshalAs(UnmanagedType.Interface)] out object item);
        void GetVisibleItem();
        void GetSelectedItem();
        void GetSelection();
        void GetSelectionState();
        void InvokeVerbOnSelection();
        void SetViewModeAndIconSize();
        void GetViewModeAndIconSize(out int viewMode, out int imageSize);
    }

    [ComImport, Guid("43826D1E-E718-42EE-BC55-A1E261C37BFE"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
    public interface IShellItem
    {
        void BindToHandler();
        void GetParent();
        [return: MarshalAs(UnmanagedType.LPWStr)]
        string GetDisplayName(uint sigdn);
    }
}
