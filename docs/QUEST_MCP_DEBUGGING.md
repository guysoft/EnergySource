# Quest VR Debugging with MCP Tools

This guide explains how to remotely debug and test the game on Quest headsets using AI-assisted MCP (Model Context Protocol) tools without physically wearing the headset.

## Prerequisites

1. Quest connected via ADB: `adb devices` should show your Quest
2. MCP mobile tools available (mobile-mcp server)
3. Game APK installed on Quest

## Available MCP Tools for Quest

### Device Management

```
mcp_mobile-mcp_mobile_list_available_devices
```
Lists all connected devices. Example output:
```json
{"devices":[{"id":"1WMHH819HH0394","name":"Quest 2","platform":"android","type":"emulator","version":"12","state":"online"}]}
```

### Screenshots

```
mcp_mobile-mcp_mobile_take_screenshot
```
Takes a screenshot of the VR display (stereoscopic left/right view).

**Important**: Quest must be awake for screenshots to work:
```bash
adb shell input keyevent KEYCODE_WAKEUP
```

### Input (Limited)

Touch and keyboard inputs generally **don't work** with VR apps because:
- VR apps use controller raycasts, not touch input
- Input goes to Android compositor, not VR rendering

## Debugging Workflow

### 1. Wake Up the Quest Display

```bash
adb -s <DEVICE_ID> shell input keyevent KEYCODE_WAKEUP
```

Verify wake state:
```bash
adb -s <DEVICE_ID> shell dumpsys power | grep mWakefulness
# Output: mWakefulness=Awake
```

### 2. Start/Stop the App

```bash
# Start app
adb shell am start -n com.tempovr.game/com.godot.game.GodotApp

# Force stop
adb shell am force-stop com.tempovr.game

# Clear logs before starting
adb logcat -c
```

### 3. Capture Logs

```bash
# Get all Godot logs
adb logcat -d -s godot:* 2>/dev/null | tail -100

# Filter for specific patterns
adb logcat -d -s godot:* | grep -i -E "(error|layout|map|level)"

# Real-time log monitoring
adb logcat -s godot:* 
```

### 4. Take Screenshots to Verify State

Using MCP:
```
mcp_mobile-mcp_mobile_take_screenshot with device="1WMHH819HH0394"
```

Using ADB directly:
```bash
adb exec-out screencap -p > screenshot.png
```

## Auto-Start Test Mode

For automated level testing, use the `CustomSongTest` debug mode:

### Enable CustomSongTest Mode

Edit `src/scenes/GameManager.tscn`:
```
debug_start_scene = "CustomSongTest"
```

This will automatically:
1. Load a predefined test song from PowerBeatsVRLevels
2. Skip the menu and go directly to gameplay
3. Print detailed logs about the loading process

### Customize the Test Song

Edit `src/scripts/GameManager.gd` in the `CustomSongTest` case:
```gdscript
"CustomSongTest":
    var test_path = GameVariables.pbvr_music_path + "/Your Song Name.mp3"
    GameVariables.path = test_path
    GameVariables.difficulty = "Expert"
    load_scene(game_path, "game")
```

### Build and Test

```bash
# Rebuild APK
cd src && godot --headless --export-debug "Meta Quest 2" out/tempovr.apk

# Install
adb install -r out/tempovr.apk

# Clear logs and start
adb logcat -c && adb shell am start -n com.tempovr.game/com.godot.game.GodotApp

# Wait and capture logs
sleep 10 && adb logcat -d -s godot:* | head -150
```

## Interpreting Debug Logs

### Successful Level Load

```
CustomSongTest: Auto-loading Matt Gray song for testing...
CustomSongTest: path=/storage/emulated/0/.../music/Song Name.mp3
MapFactory.detect_format: ext=mp3 file_exists=true
MapFactory.detect_format: POWER_BEATS_VR (music file)
MapFactory: Derived layout path: .../Layouts/Song Name.json
MapFactory: Layout file exists: true
PowerBeatsVRMap: Loaded level 'Song Name' by Unknown
PowerBeatsVRMap: Loaded Expert - 760 notes
Game: Map loaded: true
```

### Failed Level Load

```
MapFactory.detect_format: ext=mp3 file_exists=false
# OR
MapFactory: Layout file exists: false
Game: Map loaded: false
Game: Failed to load map at: ...
```

### Common Issues

| Log Pattern | Cause | Fix |
|------------|-------|-----|
| `file_exists=false` | Music file missing | Push files via ADB |
| `Layout file exists: false` | Layout JSON missing | Check Layouts folder |
| `UNKNOWN` format | Invalid path | Verify path is correct |
| `Parameter "material" is null` | Missing shader/material | Usually not fatal |

## File Verification Commands

```bash
# Check if music file exists
adb shell "ls -la '/storage/emulated/0/Android/data/com.tempovr.game/files/PowerBeatsVRLevels/music/Song Name.mp3'"

# Check if layout exists
adb shell "ls -la '/storage/emulated/0/Android/data/com.tempovr.game/files/PowerBeatsVRLevels/Layouts/Song Name.json'"

# Count files in folders
adb shell "ls /storage/emulated/0/Android/data/com.tempovr.game/files/PowerBeatsVRLevels/Layouts/ | wc -l"
adb shell "ls /storage/emulated/0/Android/data/com.tempovr.game/files/PowerBeatsVRLevels/music/ | wc -l"
```

## Screenshot Interpretation

VR screenshots show **stereoscopic view** (left eye | right eye):

- **Main Menu**: Shows "Original Custom SONG" tabs, "start" button
- **Game Playing**: Shows grid floor, mountains, timer (00:XX:XX), score, notes (colored balls)
- **Black Screen**: Quest is asleep or app not rendering

## Best Practices

1. **Always wake Quest before screenshots**: `adb shell input keyevent KEYCODE_WAKEUP`
2. **Clear logs before testing**: `adb logcat -c`
3. **Wait for app to fully load**: Sleep 10-15 seconds after starting
4. **Use CustomSongTest for reproducible tests**: Eliminates manual UI navigation
5. **Check both logs AND screenshots**: Logs show errors, screenshots show visual state
6. **Revert debug mode after testing**: Set `debug_start_scene = "Menu"` for normal use

## Example: Full Debug Session

```bash
# 1. Wake Quest
adb shell input keyevent KEYCODE_WAKEUP

# 2. Clear logs and start app  
adb logcat -c && adb shell am force-stop com.tempovr.game
adb shell am start -n com.tempovr.game/com.godot.game.GodotApp

# 3. Wait for load
sleep 12

# 4. Wake again (Quest may have slept)
adb shell input keyevent KEYCODE_WAKEUP

# 5. Take screenshot
adb exec-out screencap -p > /tmp/quest_debug.png

# 6. Get logs
adb logcat -d -s godot:* | grep -i -E "(error|map|level|load)" | head -50

# 7. View screenshot (opens in default viewer)
xdg-open /tmp/quest_debug.png
```

