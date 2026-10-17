using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Runtime.Versioning;
using System.Threading;

/// <summary>
/// Reads and moves desktop icons through Explorer (see <see cref="ExplorerDesktopView"/>).
/// Explorer calls run on a dedicated STA thread so a busy Explorer can't stall a frame; the
/// icons are re-read about once a second.
///
/// Every icon this moves is remembered on disk with its original position
/// (<see cref="MovedIconsStore"/>) and put back on <see cref="RestoreAll"/> / <see cref="Dispose"/>,
/// or on the next start after a crash.
/// </summary>
[SupportedOSPlatform("windows")]
internal sealed class DesktopIcons : IDisposable
{
    /// <param name="Id">Full parsing path, unique per icon.</param>
    /// <param name="Rect">The icon image (not its label), in screen pixels.</param>
    /// <param name="Visible">False when another window covers the icon's centre.</param>
    public sealed record Icon(string Id, string Name, Godot.Rect2I Rect, bool Visible);

    public sealed record Layout(bool AutoArrange, bool SnapToGrid, int IconSize, Godot.Vector2I Spacing);

    private const int RefreshMs = 1000;
    private const int RestoreTimeoutMs = 3000;
    private const int StopTimeoutMs = 2000;

    private readonly MovedIconsStore _moved;
    private readonly Thread _thread;
    private readonly AutoResetEvent _wake = new(false);
    private readonly ConcurrentQueue<Action> _jobs = new();
    private volatile bool _stopping;
    private volatile IReadOnlyList<Icon> _icons = Array.Empty<Icon>();
    private volatile Layout _layout;
    private volatile string _lastError;
    private volatile bool _paused;

    // Only touched on the worker thread.
    private ExplorerDesktopView _view;
    private long _nextRefresh;

    public DesktopIcons(string movedFile)
    {
        _moved = new MovedIconsStore(movedFile);
        _thread = new Thread(Run) { IsBackground = true, Name = "DesktopIcons" };
        _thread.SetApartmentState(ApartmentState.STA);
        _thread.Start();
    }

    /// <summary>Latest snapshot, refreshed about once a second. Empty until the first read.</summary>
    public IReadOnlyList<Icon> Icons => _icons;

    public Layout CurrentLayout => _layout;

    /// <summary>Why the last Explorer call failed, or null.</summary>
    public string LastError => _lastError;

    /// <summary>
    /// While true the icons aren't re-read (nothing is shown, so nobody needs them) and the
    /// thread sleeps until there's a move or restore to do.
    /// </summary>
    public bool Paused
    {
        get => _paused;
        set
        {
            _paused = value;
            _nextRefresh = 0; // read them straight away once unpaused
            _wake.Set();
        }
    }

    /// <summary>Move an icon so its image's top-left lands on <paramref name="iconTopLeft"/> (screen pixels).</summary>
    public void Move(string id, Godot.Vector2I iconTopLeft)
    {
        Enqueue(() => MoveNow(id, iconTopLeft));
    }

    /// <summary>Put every icon we moved back where it was, unless the user has moved it since. Blocks until done.</summary>
    public void RestoreAll(int timeoutMs = RestoreTimeoutMs)
    {
        using var done = new ManualResetEventSlim();
        Enqueue(() =>
        {
            try { RestoreNow(onlyIfUntouched: true); }
            finally { done.Set(); }
        });
        done.Wait(timeoutMs);
    }

    public void Dispose()
    {
        RestoreAll();
        _stopping = true;
        _wake.Set();
        _thread.Join(StopTimeoutMs);
    }

    private void Enqueue(Action job)
    {
        _jobs.Enqueue(job);
        _wake.Set();
    }

    private void Run()
    {
        _lastError = _moved.Load();
        if (_moved.Icons.Count > 0)
            Enqueue(() => RestoreNow(onlyIfUntouched: false)); // left over from a session that didn't exit cleanly

        while (!_stopping)
        {
            try
            {
                _view ??= ExplorerDesktopView.Connect();
                while (_jobs.TryDequeue(out var job))
                    job();
                if (!_paused && Environment.TickCount64 >= _nextRefresh)
                {
                    Refresh();
                    _nextRefresh = Environment.TickCount64 + RefreshMs;
                }
                _lastError = null;
            }
            catch (Exception e)
            {
                // Explorer restarting invalidates the view; reconnect on the next pass.
                _view = null;
                _lastError = e.Message;
            }
            _wake.WaitOne(_paused ? Timeout.Infinite : RefreshMs);
        }
    }

    private void Refresh()
    {
        _layout = _view.ReadLayout();
        var windows = DesktopCoverage.WindowsAboveDesktop();
        var count = _view.Count;
        var icons = new List<Icon>(count);
        for (var i = 0; i < count; i++)
        {
            var (id, name) = _view.Names(i);
            var rect = _view.ScreenRect(_view.Position(i), _layout.IconSize);
            icons.Add(new Icon(id, name, rect, DesktopCoverage.IsUncovered(rect.GetCenter(), windows)));
        }
        _icons = icons;
    }

    private void MoveNow(string id, Godot.Vector2I iconTopLeft)
    {
        var index = _view.IndexOf(id);
        if (index < 0)
            return;
        var before = _view.Position(index);
        _view.Place(index, _view.PositionFor(iconTopLeft));
        var landed = _view.Position(index); // may differ from where it was sent when icons snap to the grid

        if (_moved.Icons.TryGetValue(id, out var moved))
        {
            moved.LastX = landed.X;
            moved.LastY = landed.Y;
            return;
        }
        _moved.Icons[id] = new MovedIconsStore.MovedIcon { OriginalX = before.X, OriginalY = before.Y, LastX = landed.X, LastY = landed.Y };
        _moved.Save(); // on disk as soon as an icon first leaves home, in case we crash
    }

    private void RestoreNow(bool onlyIfUntouched)
    {
        foreach (var (id, moved) in _moved.Icons)
        {
            var index = _view.IndexOf(id);
            if (index < 0)
                continue; // deleted or renamed since
            var now = _view.Position(index);
            if (onlyIfUntouched && (now.X != moved.LastX || now.Y != moved.LastY))
                continue; // the user moved it themselves; leave it
            _view.Place(index, new Win32.Point { X = moved.OriginalX, Y = moved.OriginalY });
        }
        _moved.Icons.Clear();
        _moved.Save();
    }
}
