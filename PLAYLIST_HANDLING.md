# Playlist and Song Path Handling

This document describes how songs and playlists are handled in TempoVR, including the unified song path approach that ensures correct audio playback in all scenarios.

## Overview

TempoVR supports two level formats:
- **PowerBeatsVR**: Music files with separate JSON layout files
- **Beat Saber**: Self-contained level folders with `info.dat`

The key design principle is that `GameVariables.path` always identifies **what song to play**, and the system derives everything else from it.

## Song Path Design

### PowerBeatsVR Format

```
GameVariables.path = music file path (e.g., "music/ogg/Wellerman.ogg")
                           ↓
              MapFactory.create_map()
                           ↓
         Derives layout: "Layouts/Wellerman.json"
         Sets map.music_path = original music path
                           ↓
              map.get_song() returns music path
```

**Key points:**
- The music file is the **primary identifier**
- Layout path is **derived** from the music filename: `song.ogg` → `Layouts/song.json`
- `MapFactory` sets `map.music_path` so `get_song()` returns the correct audio

### Beat Saber Format

```
GameVariables.path = level folder path (e.g., "Levels/MySong/")
                           ↓
              MapFactory.create_map()
                           ↓
         Loads info.dat from folder
         Audio path read from info.dat._songFilename
                           ↓
              map.get_song() returns folder + audio filename
```

**Key points:**
- The level folder is the **primary identifier**
- Audio file is **inside** the folder, specified in `info.dat`
- No derivation needed - everything is self-contained

## File Responsibilities

### GameVariables.gd

```gdscript
var path = null      # The song to play (music file for PBVR, folder for BS)
var difficulty = null
```

`path` holds different things depending on format:
- PowerBeatsVR: Full path to music file (`.ogg`, `.mp3`, `.wav`)
- Beat Saber: Path to level folder containing `info.dat`

### MapFactory.gd

Detects format and creates appropriate map loader:

```gdscript
static func detect_format(path: String) -> MapFormat:
    # Beat Saber: folder with info.dat
    if DirAccess.dir_exists_absolute(path):
        if FileAccess.file_exists(path + "/info.dat"):
            return MapFormat.BEAT_SABER
    
    # PowerBeatsVR: music file
    var ext = path.get_extension().to_lower()
    if ext in ["ogg", "mp3", "wav"]:
        return MapFormat.POWER_BEATS_VR
    
    # PowerBeatsVR: JSON layout (backwards compat)
    if path.ends_with(".json"):
        return MapFormat.POWER_BEATS_VR
```

For PowerBeatsVR music files, `create_map()`:
1. Derives the layout path from the music filename
2. Creates `PowerBeatsVRMap` with the layout path
3. Sets `map.music_path` to the original music path

### PowerBeatsVRMap.gd

```gdscript
var music_path: String = ""  # Set by MapFactory when loading from music file

func get_song() -> String:
    # If explicit music path was set, use it
    if music_path != "":
        return music_path
    # Otherwise derive from layout name (backwards compat)
    # ... search in music folders
```

### ui_song_list.gd

When user selects a PowerBeatsVR song:

```gdscript
func _select_powerbeatsvr_song(index: int):
    var music_path = songs_paths[index]  # Full path to music file
    GameVariables.path = music_path      # Store music path
    var map = MapFactory.create_map(music_path)  # Derives layout
    # ...
```

### PlaylistManager.gd

When loading a playlist song:

```gdscript
func _load_current_song() -> bool:
    var song = get_current_song()
    GameVariables.path = song.music_path  # Music path is primary
    GameVariables.difficulty = song.difficulty
    # ...
```

### Game.gd

Simply uses `map.get_song()` without special handling:

```gdscript
func setup_song(map):
    var song_path = map.get_song()  # Always returns correct path
    var stream = audio_loader.loadfile(song_path, false)
    # ...
```

## Playlist Mode

Playlist mode allows playing multiple songs in sequence. It is only available for PowerBeatsVR levels.

### State Management

```gdscript
# PlaylistManager.gd
var _playlist_mode: bool = false
var _current_playlist: PlaylistData = null
var _current_song_index: int = 0
```

### Flow

1. User selects playlist in `ui_playlist.gd`
2. `PlaylistManager.start_playlist()` sets `_playlist_mode = true`
3. `_load_current_song()` sets `GameVariables.path = song.music_path`
4. Game scene loads and plays the song
5. On song end, `next_song()` advances to next song
6. Repeat until playlist ends or user exits

### Key Functions

| Function | Purpose |
|----------|---------|
| `start_playlist(playlist)` | Begin playlist mode |
| `next_song()` | Advance to next song (or end playlist) |
| `skip_to_song(index)` | Jump to specific song |
| `end_playlist()` | Exit playlist mode |
| `is_playlist_mode()` | Check if in playlist mode |
| `get_current_song()` | Get current song entry |

### Playlist UI Elements

- **Next Button**: Shown on end-of-song screen when more songs remain
- **Skip Button**: In pause menu during playlist mode
- **Playlist Time Label**: Shows elapsed playlist time and song count

## Historical Bug Fix

### The Problem

Previously, there were two separate sources for what song to play:
- `GameVariables.path` stored the **layout path**
- `PlaylistManager.get_current_song().music_path` stored the **audio path**

This caused a bug: when playing a playlist song, then selecting a normal song, the playlist song's audio would play instead because stale playlist state overrode the audio path.

### The Solution

Unified approach where `GameVariables.path` is the **single source of truth**:
- For PowerBeatsVR: `path` = music file, layout is derived
- For Beat Saber: `path` = level folder (unchanged)

Now `map.get_song()` always returns the correct audio path without needing to check playlist mode.

## Testing

Run unit tests:

```bash
cd src
godot --headless --script res://tests/test_song_path.gd
godot --headless --script res://tests/test_playlist.gd
```

## File Structure Reference

```
PowerBeatsVRLevels/
├── Layouts/
│   ├── Song1.json
│   └── Song2.json
├── music/
│   ├── ogg/
│   │   ├── Song1.ogg
│   │   └── Song2.ogg
│   └── all/
│       └── Song3.mp3
└── playlists.json

Levels/                    # Beat Saber format
└── MySong/
    ├── info.dat
    ├── song.ogg
    ├── Easy.dat
    └── Expert.dat
```

