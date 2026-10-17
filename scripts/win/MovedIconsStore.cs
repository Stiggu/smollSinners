using System;
using System.Collections.Generic;
using System.IO;
using System.Text.Json;

/// <summary>
/// Every desktop icon we've moved: where it started and where we last put it (Explorer's list
/// view coordinates). Written to disk as soon as an icon first leaves home, so the icons can
/// be put back on the next start after a crash.
/// </summary>
internal sealed class MovedIconsStore
{
    /// <summary>One icon's way home. The property names are the file's format: keep them.</summary>
    public sealed class MovedIcon
    {
        public int OriginalX { get; set; }
        public int OriginalY { get; set; }
        public int LastX { get; set; }
        public int LastY { get; set; }
    }

    private readonly string _file;

    public MovedIconsStore(string file)
    {
        _file = file;
    }

    /// <summary>By icon id.</summary>
    public Dictionary<string, MovedIcon> Icons { get; private set; } = new();

    /// <summary>Read what a previous session left. Returns why it couldn't, or null.</summary>
    public string Load()
    {
        try
        {
            if (File.Exists(_file))
                Icons = JsonSerializer.Deserialize<Dictionary<string, MovedIcon>>(File.ReadAllText(_file)) ?? new();
            return null;
        }
        catch (Exception e)
        {
            return $"couldn't read {_file}: {e.Message}";
        }
    }

    public void Save()
    {
        if (Icons.Count == 0)
        {
            File.Delete(_file);
            return;
        }
        Directory.CreateDirectory(Path.GetDirectoryName(_file));
        File.WriteAllText(_file, JsonSerializer.Serialize(Icons));
    }
}
