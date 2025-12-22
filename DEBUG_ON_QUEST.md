# Debugging on Quest - Performance Testing Guide

This document describes the workflow for testing and debugging TempoVR performance on Meta Quest 2.

## Quick Start

### Deploy to Quest
```bash
cd /home/guy/workspace/godot/EnergySource
/home/guy/vpy/bin/python tools/deploy_quest.py
```

### Wake Up Quest (for screenshots)
```bash
adb shell input keyevent KEYCODE_WAKEUP
```

### View Godot Logs
```bash
adb logcat -s godot:* | tail -50
```

## Performance Targets

| Quest Mode | Target FPS | Frame Budget |
|------------|-----------|--------------|
| 72 Hz      | 72 FPS    | 13.9 ms      |
| 90 Hz      | 90 FPS    | 11.1 ms      |
| 120 Hz     | 120 FPS   | 8.3 ms       |

**Current Status (Dec 2025):** ~36 FPS in main menu

## FPS Overlay

The game includes a built-in FPS overlay visible in VR:
- Shows current FPS (color-coded: green=72+, yellow=60-72, red=<60)
- Shows frame time in milliseconds
- Shows current quality test mode
- Located at bottom-right of view

### Cycling Test Modes
Press the **Menu Button** on either controller to cycle through test configurations:

| Mode | Particles | Lighting | PostFX | Explosions | Env Particles |
|------|-----------|----------|--------|------------|---------------|
| NORMAL | ✓ | ✓ | ✓ | ✓ | ✓ |
| NO PARTICLES | ✗ | ✓ | ✓ | ✗ | ✗ |
| NO LIGHTING | ✓ | ✗ | ✓ | ✓ | ✓ |
| NO POSTFX | ✓ | ✓ | ✗ | ✓ | ✓ |
| MINIMAL | ✗ | ✗ | ✗ | ✗ | ✗ |

## Performance Test Results

### December 2024 Baseline Testing

| Configuration | FPS | Frame Time | Notes |
|--------------|-----|------------|-------|
| Original (transparent UI) | 24 FPS | 41 ms | All effects enabled |
| No transparency on UI panels | 36 FPS | 27 ms | **+50% improvement** |
| MINIMAL + no transparency | 36 FPS | 27 ms | No additional improvement |

### Key Findings

1. **Main Bottleneck: UI SubViewports**
   - The game uses 4 UICanvasInteract panels in the main menu
   - Each has a SubViewport rendering at UPDATE_ALWAYS
   - Transparency adds significant overhead
   - **Fix:** Disabled transparency on Quest (automatic in UICanvasInteract.gd)

2. **Secondary Factors (minimal impact):**
   - Particles (GPUParticles3D) - negligible impact
   - DirectionalLight - negligible impact
   - Post-processing (glow, fog) - negligible impact
   - Note explosions - negligible impact

3. **Remaining Issues:**
   - 36 FPS is still below 72 Hz target
   - Passthrough visible through UI (environment background not rendering in XR)

## Code Changes for Quest Optimization

### UICanvasInteract.gd
- Transparency auto-disabled on Quest
- SubViewport update frequency optimization (reduces updates when not being looked at)

### QualitySettings.gd
Added debug toggles:
```gdscript
QualitySettings.debug_particles_enabled = true/false
QualitySettings.debug_lighting_enabled = true/false
QualitySettings.debug_postprocess_enabled = true/false
QualitySettings.debug_note_explosions_enabled = true/false
QualitySettings.debug_environment_particles_enabled = true/false
```

## Recommended Optimizations

### Already Implemented
- [x] Disable UI transparency on Quest
- [x] Mobile rendering method (`renderer/rendering_method="mobile"`)
- [x] Glow/fog disabled on Quest in Game.gd
- [x] Reduced particle counts on Quest

### Recommended Next Steps
1. **Reduce SubViewport count** - Combine UI panels or lazy-load only visible panels
2. **Lower SubViewport resolution** - Reduce UI render resolution on Quest
3. **Investigate XR rendering** - Ensure proper opaque background rendering
4. **Profile GPU usage** - Use Meta Quest GPU profiler for detailed breakdown

## Debugging Workflow

### 1. Make Code Changes
Edit scripts locally in Cursor/VSCode

### 2. Deploy to Quest
```bash
/home/guy/vpy/bin/python tools/deploy_quest.py
```

### 3. Wake Device
```bash
adb shell input keyevent KEYCODE_WAKEUP
```

### 4. Take Screenshots
Use mobile MCP tool or:
```bash
adb shell screencap -p /sdcard/screen.png && adb pull /sdcard/screen.png
```

### 5. Check Logs
```bash
adb logcat -s godot:* | tail -100
```

### 6. Iterate
Repeat steps 1-5 until performance targets are met

## Files Modified for Performance Testing

- `src/scripts/FPSOverlay.gd` - FPS display and test mode cycling
- `src/scenes/FPSOverlay.tscn` - Label3D for VR-visible FPS
- `src/scripts/QualitySettings.gd` - Debug quality toggles
- `src/scripts/UICanvasInteract.gd` - Quest-specific optimizations
- `src/scripts/Game.gd` - Quality-aware environment setup
- `src/scripts/note.gd` - Explosion toggle check
- `src/scenes/GameManager.tscn` - FPSOverlay instance added

## Related Documentation

- [QUEST_WAKEUP.md](QUEST_WAKEUP.md) - How to wake Quest display via ADB
- [deploy_quest.py](deploy_quest.py) - Automated deployment script

