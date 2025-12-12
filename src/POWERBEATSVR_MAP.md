# PowerBeatsVR Level Format Mapping

This document describes how PowerBeatsVR level format is mapped to EnergySource/TempoVR.

## Overview

EnergySource supports two level formats:
1. **Beat Saber** - Folder containing `info.dat` and difficulty `.dat` files
2. **PowerBeatsVR** - Single `.json` file with all level data

The `MapFactory` class automatically detects and loads the appropriate format.

## Coordinate Systems

### PowerBeatsVR Coordinates (Source)

From PowerBeatsVR developers:
```
posx = -1.3 to 1.3
posy = 0.5 to 1.3
```

**Note:** Actual level data may exceed these limits. The converter does not clamp values.

### EnergySource Coordinates (Target)

From `MapLoader.gd`:
```gdscript
LEVEL_WIDTH = 0.8   # X range: -0.8 to 0.8
LEVEL_LOW = 0.6     # Y minimum
LEVEL_HIGH = 1.05   # Y range: 0.6 to 2.1
```

### Mapping Approach

Following the same approach as the Beat Saber to PowerBeatsVR converter:
**Coordinates pass through directly without transformation.**

```gdscript
static func pbvr_to_es_position(pbvr_x: float, pbvr_y: float) -> Vector2:
    # Direct passthrough - preserves original level designer's intent
    return Vector2(pbvr_x, pbvr_y)
```

This means PowerBeatsVR levels may use a slightly wider coordinate range than native EnergySource levels, but this preserves the original gameplay feel.

## File Structure

### PowerBeatsVR Level Layout

```
PowerBeatsVRLevels/
├── Layouts/
│   └── SongName.json      # Level data
└── music/
    └── all/
        └── SongName.ogg   # Audio file (name must match)
```

### JSON Format (schemaVersion 2)

```json
{
  "name": "Song Name",
  "author": "Artist Name",
  "bpm": 120,
  "offset": 0,
  "schemaVersion": 2,
  "Beginner": {
    "isGenerated": true,
    "maxHighscore": 0,
    "beats": [...]
  },
  "Advanced": { ... },
  "Expert": { ... }
}
```

### Beat Format

```json
{
  "beatNo": 4,
  "beatLabel": "",
  "actions": [
    {
      "position": [x, y],
      "action": "NormalBall"
    }
  ],
  "subBeats": [
    {
      "offset": 0.5,
      "actions": [...]
    }
  ]
}
```

## Action Type Mapping

| PowerBeatsVR Action | EnergySource `_type` | Description |
|---------------------|----------------------|-------------|
| `NormalBall` | `0` (left) or `1` (right) | Standard hittable ball. Type determined by X position (negative = left, positive = right) |
| `PowerBall` | `0` or `1` | Same as NormalBall (future: could add visual distinction) |
| `BallObstacle` | `3` (bomb) | Avoid hitting these |
| `WallObstacle` | obstacle | Wall/barrier to dodge |
| `Stream` | (not implemented) | Logged and skipped |

## Wall Type Mapping

| Type ID | PowerBeatsVR Name | EnergySource Type | Implementation |
|---------|-------------------|-------------------|----------------|
| 0 | SingleColumn | `full_height` | Implemented |
| 1 | DoubleColumn | `full_height` | Placeholder |
| 2 | ArchwayCenter | `archway_center` | Placeholder |
| 3 | ArchwayLeft | `archway_left` | Placeholder |
| 4 | ArchwayRight | `archway_right` | Placeholder |
| 5 | OpeningLeft | `opening_left` | Placeholder |
| 6 | OpeningRight | `opening_right` | Placeholder |
| 7 | BarAcrossTheForehead | `crouch` | Implemented |

**Placeholder** types currently render as `full_height` walls. Future versions may add unique visuals.

## Timing

### Ball Flight Duration

PowerBeatsVR adjusts how long balls take to fly from spawn to player based on BPM. This is critical for proper gameplay feel.

**From PowerBeatsVR `GameManager.cs` (Expert difficulty):**

| BPM Range | Threshold | Flight Duration |
|-----------|-----------|-----------------|
| Low | BPM < 100 | 2 beats |
| Mid | 100 <= BPM < 145 | 2 beats |
| High | BPM >= 145 | 3 beats |

**Example - Wellerman (96 BPM):**
- BPM Range: Low (96 < 100)
- Flight Duration: 2 beats
- Flight Time: 60/96 * 2 = **1.25 seconds**

Beat Saber levels use a fixed 4-beat flight duration.

### Beat Number
The `beatNo` field indicates which beat (integer) the actions occur on.

### Sub-Beat Offset
Actions can occur between beats using `subBeats`:
- `offset: 0.5` = halfway between this beat and the next
- `offset: 0.25` = quarter of the way through

The offset is stored in the note data and used by the game to delay spawning.

## Difficulties

PowerBeatsVR uses three difficulty levels:
- `Beginner`
- `Advanced`  
- `Expert`

These map directly (no name conversion needed).

## Audio File Matching

The audio file is found by matching the JSON filename:
- `Wellerman.json` → looks for `Wellerman.ogg`, `Wellerman.mp3`, or `Wellerman.wav`

Search paths (in order):
1. Same directory as the JSON file
2. `../music/` relative to Layouts
3. `../music/all/` relative to Layouts

## Implementation Files

| File | Purpose |
|------|---------|
| `scripts/PowerBeatsVRMap.gd` | Loads and parses PowerBeatsVR JSON format |
| `scripts/MapFactory.gd` | Detects format and creates appropriate loader |
| `scripts/MapLoader.gd` | Original Beat Saber loader (unchanged) |
| `tests/test_powerbeatsvr.gd` | Unit tests for PowerBeatsVR loading |

## Usage Example

```gdscript
# Automatic format detection
var map = MapFactory.create_map("/path/to/Wellerman.json")
# or
var map = MapFactory.create_map("/path/to/BeatSaberLevel/")

# Both return objects with the same interface:
map.get_level("Expert")
var notes = map._on_beat_detected("Expert", beat_number)
```

## Future Enhancements

- Visual distinction for PowerBall vs NormalBall
- Stream support (bezier path rendering)
- Unique visuals for each wall type
- Cover image support


