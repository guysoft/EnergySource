# Quest Optimization Guide

This document describes performance optimizations for Meta Quest 2 VR headset.

## Target Performance

- **Target FPS**: 72 FPS (Quest 2 native refresh rate)
- **Frame budget**: 13.8ms per frame

## Root Cause of Low FPS

Through extensive testing, we identified the following performance bottlenecks:

### Environment Effects (MAJOR - 50%+ impact)

The procedural sky and post-processing effects are the primary FPS killers:

| Effect | FPS Impact |
|--------|------------|
| Procedural Sky | -20 FPS |
| Glow | -10 FPS |
| Fog | -5 FPS |
| Volumetric Fog | -5 FPS |

### SubViewport Update Mode (CRITICAL - causes visual bugs)

**WARNING**: Do NOT use throttled SubViewport updates. This causes menus to appear "stuck" to the user's head.

| Update Mode | FPS Impact | Visual Quality |
|-------------|------------|----------------|
| UPDATE_ALWAYS (4) | Baseline | Correct |
| UPDATE_ONCE (1) | +5-10% | BROKEN - menus stuck |
| UPDATE_THROTTLED | +5-10% | BROKEN - menus stuck |
| UPDATE_DISABLED | +15% | BROKEN - no updates |

**Always use `render_target_update_mode = 4` (UPDATE_ALWAYS) for VR UI panels.**

### Transparency (MODERATE - 10-15% impact)

Transparent materials on UI panels add overhead. However, disabling them may affect visual design.

## Recommended Optimizations

### 1. Environment Optimization (MainMenu.gd / Game.gd)

Add this to `_ready()` or `setup_environment()`:

```gdscript
# Quest optimization: disable expensive environment effects
if QualitySettings.is_quest() and environment:
    environment.glow_enabled = false
    environment.fog_enabled = false
    environment.volumetric_fog_enabled = false
    # Optional: Use solid background instead of procedural sky
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.02, 0.02, 0.04, 1.0)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.15, 0.15, 0.2, 1.0)
    environment.ambient_light_energy = 0.3
```

### 2. XR Optimizations (project.godot)

These are already configured in the project:

```ini
[rendering]
renderer/rendering_method="mobile"
anti_aliasing/quality/msaa_3d=1  # MSAA x2

[xr]
openxr/foveation_level=2
openxr/foveation_dynamic=true
```

### 3. What NOT to Do

**DO NOT** modify these SubViewport settings:

```gdscript
# BAD - causes "stuck to head" visual bug
viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
```

**DO NOT** add `render_target_clear_mode = 2` to scene files.

**DO NOT** implement throttled viewport updates via `_apply_update_mode()` patterns.

## Testing Performance

### Via ADB Logcat

```bash
# Get FPS readings from Quest
adb logcat -d | grep "FPS=" | tail -5
```

Example output:
```
FPS=72/72,Prd=41ms,App=8.13ms,GPU%=0.76
```

Key metrics:
- `FPS=72/72` - Current/Target FPS
- `App=Xms` - Application frame time (should be <13.8ms)
- `GPU%` - GPU utilization (should be <0.95)

### Deploy and Test

```bash
python tools/deploy_quest.py
```

## Performance Results

| Configuration | FPS | Notes |
|--------------|-----|-------|
| Original (procedural sky + glow) | 36 | Too slow |
| Environment optimized | 72 | Target achieved |
| + SubViewport throttling | 72 | BROKEN - menus stuck |

## Files Modified for Optimization

- `src/scripts/MainMenu.gd` - Menu environment optimization
- `src/scripts/Game.gd` - In-game environment optimization (uses `_environment_manager.environment`)
- `src/scripts/GameManager.gd` - Added "GameTest" debug mode for FPS testing
- `src/project.godot` - XR settings (foveation, MSAA)

## Important: Game.gd vs MainMenu.gd

The Game scene uses `_environment_manager.change_environment(environment)` which means you must modify `_environment_manager.environment`, NOT the local `environment` export variable:

```gdscript
# CORRECT - Game.gd
if QualitySettings.is_quest():
    var env = _environment_manager.environment  # Use the active environment!
    env.glow_enabled = false
    # ...

# WRONG - would not work
if QualitySettings.is_quest():
    environment.glow_enabled = false  # This modifies the wrong object!
```

## Key Learnings

1. **Environment effects are expensive** - Procedural sky + glow + fog can cost 50%+ FPS
2. **SubViewport throttling breaks VR tracking** - Always use UPDATE_ALWAYS
3. **Quest foveation helps** - Reduces GPU load in peripheral vision
4. **MSAA x2 is acceptable** - Higher values impact performance significantly
5. **Test with headset worn** - ADB screenshots show passthrough when headset is off

## Commit Reference

- Working optimization: Branch `workout2` based on commit `ecdb6d5`
- Broken throttling: Commit `1aebfe5` (do not use this approach)

