# TempoVR - Meta Quest 2 Deployment Guide

This document covers building, deploying, and managing music files for TempoVR on Meta Quest 2.

## Prerequisites

### On Your Computer
1. **Godot 4.5+** with Android export templates installed
2. **Android SDK** with NDK (version 23+)
3. **Java JDK 17** (Adoptium Temurin recommended)
4. **ADB** (Android Debug Bridge)

### On Your Quest 2
1. **Developer Mode enabled** via Meta Quest app on your phone
2. **USB Debugging authorized** when connected to computer

## Godot Editor Settings

In Godot, go to **Editor → Editor Settings → Export → Android**:

| Setting | Value |
|---------|-------|
| Java SDK Path | `/home/guy/jdk/jdk-17.0.13+11` (or your JDK path) |
| Android SDK Path | `/home/guy/Android/Sdk` (or your SDK path) |
| Debug Keystore | `~/.android/debug.keystore` |

## Export Settings

The export preset is configured in `src/export_presets.cfg`:

| Setting | Value |
|---------|-------|
| XR Mode | OpenXR |
| Meta Plugin | Enabled |
| Quest 2 Support | Enabled |
| Architecture | arm64-v8a |
| Package Name | `com.tempovr.game` |

### Required Permissions
- `READ_EXTERNAL_STORAGE`
- `WRITE_EXTERNAL_STORAGE`
- `MANAGE_EXTERNAL_STORAGE`
- `INTERNET`
- `VIBRATE`

## Building the APK

1. Open project in Godot: `src/project.godot`
2. Go to **Project → Export**
3. Select **"Meta Quest 2"** preset
4. Click **Export Project**
5. Save as `out/tempovr.apk`

## Installing on Quest 2

### First-time Setup
1. Connect Quest 2 via USB
2. Put on the headset and **Allow USB debugging**
3. Check "Always allow from this computer"

### Install Commands
```bash
# Check Quest is connected
adb devices

# Install APK (use -r to replace existing)
adb install -r src/out/tempovr.apk
```

## Music Files Location

The game looks for music files in this location on Quest 2:

```
/storage/emulated/0/Android/data/com.tempovr.game/files/PowerBeatsVRLevels/
├── Layouts/           # Song layout JSON files (beat maps)
├── music/             # Audio files (.ogg, .mp3)
│   ├── all/
│   ├── ogg/
│   └── ...
└── playlists.json     # Playlist definitions
```

### Pushing Music Files to Quest

```bash
# Create the directory structure
adb shell mkdir -p /storage/emulated/0/Android/data/com.tempovr.game/files/PowerBeatsVRLevels

# Push Layouts folder
adb push PowerBeatsVRLevels/Layouts /storage/emulated/0/Android/data/com.tempovr.game/files/PowerBeatsVRLevels/

# Push music folder
adb push PowerBeatsVRLevels/music /storage/emulated/0/Android/data/com.tempovr.game/files/PowerBeatsVRLevels/

# Push playlists.json
adb push PowerBeatsVRLevels/playlists.json /storage/emulated/0/Android/data/com.tempovr.game/files/PowerBeatsVRLevels/
```

### Verifying Files on Quest
```bash
# List the PowerBeatsVRLevels folder
adb shell ls -la /storage/emulated/0/Android/data/com.tempovr.game/files/PowerBeatsVRLevels/

# Check music files
adb shell ls /storage/emulated/0/Android/data/com.tempovr.game/files/PowerBeatsVRLevels/music/ | head -20
```

## Troubleshooting

### Quest Not Detected
```bash
# Restart ADB server
adb kill-server
adb start-server
adb devices
```
- Make sure USB cable supports data (not charge-only)
- Try different USB port
- Re-authorize in headset

### Music Not Showing
1. Verify files are in correct location:
   ```bash
   adb shell ls -la /storage/emulated/0/Android/data/com.tempovr.game/files/PowerBeatsVRLevels/
   ```
2. Check game logs:
   ```bash
   adb logcat -s godot:* | grep -i "music\|playlist\|powerbeatsvr"
   ```

### Playlists Not Showing
- Ensure `playlists.json` is in the `PowerBeatsVRLevels/` folder
- Check JSON syntax is valid

### App Crashes on Start
```bash
# View crash logs
adb logcat -s godot:* AndroidRuntime:E | tail -100
```

### Permission Denied Errors
Grant storage permissions in Quest:
**Settings → Apps → TempoVR → Permissions → Storage → Allow**

## Updating the Game

```bash
# Rebuild APK in Godot, then:
adb install -r src/out/tempovr.apk
```

Music files persist across app updates since they're stored in external storage.

## Uninstalling

```bash
# Remove app (keeps music files)
adb uninstall com.tempovr.game

# To also remove music files:
adb shell rm -rf /storage/emulated/0/Android/data/com.tempovr.game/
```

## Development Tips

### Viewing Logs in Real-time
```bash
adb logcat -s godot:V
```

### Quick Deploy from Godot
Use the **Remote Debug** button (next to play button) in Godot to deploy directly to Quest.

### Wireless ADB (Optional)
```bash
# Enable on Quest (one-time, while USB connected)
adb tcpip 5555

# Connect wirelessly (replace with Quest's IP)
adb connect 192.168.1.XXX:5555

# Disconnect USB, continue using adb wirelessly
```

## File Structure Reference

### On Computer (Development)
```
EnergySource/
├── src/                    # Godot project
│   ├── project.godot
│   ├── export_presets.cfg
│   └── out/tempovr.apk     # Built APK
└── PowerBeatsVRLevels/     # Music & layouts (outside Godot project)
    ├── Layouts/
    ├── music/
    └── playlists.json
```

### On Quest 2 (Runtime)
```
/storage/emulated/0/Android/data/com.tempovr.game/files/
└── PowerBeatsVRLevels/
    ├── Layouts/
    ├── music/
    └── playlists.json
```

