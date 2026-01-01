# Development Rules

## 1. Tool Usage
- **Do NOT run the godot binary directly** (e.g. via terminal).
- **Use MCP tools only** for interacting with the Godot project.

## 2. Committing Changes
- **Commit changes progressively** as you complete fixes or features.
- Include a clear explanation of what was done in the commit message.
- Group related changes together in a single commit.

## 3. Running and Testing
To run the game and test for errors:
1.  **Play Scene**: Use `mcp_godot-ai_play_scene` to run the current scene or the main scene. This will launch the game window.
2.  **Get Errors**: After running the scene (or while it's running), use `mcp_godot-ai_get_godot_errors` to retrieve any runtime errors, script parsing errors, or debugger output.
3.  **Clear Logs**: Use `mcp_godot-ai_clear_output_logs` to clear old errors before a new test run to ensure you are seeing fresh data.

**Rule:** Always run the game using `mcp_godot-ai_play_scene` and check for errors using `mcp_godot-ai_get_godot_errors` after making changes to scripts or scenes to verify fixes.

### Checking Scene Node Warnings
**CRITICAL:** Before running or testing a scene, use `mcp_godot-ai_get_scene_tree` and `mcp_godot-ai_get_editor_screenshot` to visually inspect the scene tree for node warnings. Common warnings to watch for:

- **XR Controllers**: `XRController3D` nodes require a `tracker` property to be set (e.g., `left_hand`, `right_hand`). Without this, controllers won't track properly in VR mode.
- **Missing Resources**: Nodes may warn about missing scripts, textures, or other resources.
- **Configuration Warnings**: Some nodes have built-in warnings for missing required properties (e.g., `CollisionShape3D` without a shape, `MeshInstance3D` without a mesh).

**Rule:** After opening a scene in the editor, take a screenshot with `mcp_godot-ai_get_editor_screenshot` to check for yellow warning triangles on nodes in the scene tree. Address these warnings before testing.

**CRITICAL:** After making code changes, ALWAYS run the game and check for runtime errors before committing. Common errors to watch for:
- Type mismatches (e.g., `bool` vs `int` in comparisons)
- Invalid mesh/material operations (e.g., `material/0` instead of `surface_material_override/0`)
- Missing or renamed properties from Godot 3 to 4 migration

### VR/XR Testing with XR Simulator
The project includes an XR Simulator addon (`addons/xr-simulator/`) for testing VR features without a headset. It is enabled in `GameManager.tscn`.

**Controls:**
- **Q key**: Hold to select left controller
- **E key**: Hold to select right controller
- **Mouse movement**: Move selected controller (or rotate camera if no controller selected)
- **Left mouse button**: Trigger click
- **Right mouse button**: Grip click
- **WASD**: Left joystick
- **Arrow keys**: Right joystick
- **Scroll wheel**: Move controller closer/farther (or adjust camera height)
- **ESC**: Release mouse capture

**Rule:** Always test VR features using the XR Simulator before committing. Run `GameManager.tscn` in the editor to test controller interactions.

### Testing Multiple Scenes
When making changes that affect menus or UI, test **both** scenes:
1. **`GameManager.tscn`** - The main entry point with full game infrastructure (Player, XR setup, etc.)
2. **`MainMenu.tscn`** - The main menu scene (note: some scripts like `ui_song_list.gd` depend on `Global.manager()` and will show errors when run standalone - this is expected)

**Known Issues When Testing MainMenu.tscn Standalone:**
- `ui_song_list.gd:9` will error with "Invalid access to property '_beatplayer' on a base object of type 'Nil'" because `Global.manager()` is not available without GameManager
- This is expected behavior - always test via `GameManager.tscn` for full functionality

## 4. Unit Testing
**Always add unit tests** when making changes to resources, scenes, or scripts. Tests are located in `res://tests/`.

Run tests with:
```bash
godot --headless --script res://tests/test_textures.gd
```

Tests should verify:
- Resources load correctly (not null)
- Resources have the correct type (e.g., `NoiseTexture2D`, not `NoiseTexture`)
- Scenes can be instantiated
- Materials have required properties set

## 5. Critical Components (Do Not Modify Without Verification)
- **Menu Animation**: The main menu logo animation relies on `BeatResponder` and `menu_logo_material.tres`.
    - **Do NOT change the export type** of `materials` in `src/scripts/beat_responder.gd` to a typed array (e.g., keep as `[]`, do NOT use `Array[ShaderMaterial]`). This ensures compatibility with existing scene data in `MainMenu.tscn`.
    - Ensure `menu_logo_material.tres` uses `NoiseTexture2D` (Godot 4) and not `NoiseTexture`.

## 6. Godot 3 to Godot 4 Migration Reference

When migrating from Godot 3 to Godot 4, the following changes are required:

### Resource Format
- `format=2` → `format=3`
- Add `uid="uid://..."` to resources

### Node Types
- `Spatial` → `Node3D`
- `MeshInstance` → `MeshInstance3D`
- `Area` → `Area3D`
- `CollisionShape` → `CollisionShape3D`
- `Viewport` → `SubViewport`

### Materials
- `SpatialMaterial` → `StandardMaterial3D`
- `flags_transparent = true` → `transparency = 1`
- `flags_unshaded = true` → `shading_mode = 0`
- `material/0` → `surface_material_override/0` (for MeshInstance3D)
- `hint_color` → `source_color` (in shaders)
- `hint_albedo` → `source_color` (in shaders)
- `hint_white` → `hint_default_white` (in shaders)

### Textures
- `NoiseTexture` → `NoiseTexture2D`
- `OpenSimplexNoise` → `FastNoiseLite`
- `GradientTexture` → `GradientTexture2D`
- `Texture` type → `Texture2D` type
- `ViewportTexture` must be explicitly created and assigned to materials

### Shader Parameters
- `shader_param/` → `shader_parameter/`
- `NORMALMAP` → `NORMAL_MAP`
- `NORMALMAP_DEPTH` → `NORMAL_MAP_DEPTH`

### AnimationPlayer
- `anims/animation_name = SubResource(id)` → Use `AnimationLibrary`:
```
[sub_resource type="AnimationLibrary" id="X"]
_data = {
"animation_name": SubResource("animation_id")
}

[node name="AnimationPlayer" ...]
libraries = {
"": SubResource("X")
}
```

### Animation Tracks
- `translation` → `position`
- `PoolRealArray` → `PackedFloat32Array`
- `PoolColorArray` → `PackedColorArray`

### Input Events
- `InputEventMouseButton.button_pressed` → `InputEventMouseButton.pressed`
- `InputEvent.is_action_pressed()` / `is_action_released()` API unchanged but check for deprecations

### SubViewport (formerly Viewport)
- Must have `render_target_update_mode = 4` (UPDATE_ALWAYS) for real-time updates
- `size_override_stretch` removed
- `hdr` → `use_hdr_2d`
- `render_target_v_flip` removed (handled automatically)

### Environment/Sky
- `ProceduralSky` properties moved to `ProceduralSkyMaterial`
- `Sky` resource now needs a `sky_material` property pointing to `ProceduralSkyMaterial`
- `background_sky` → `sky`
- Fog properties changed significantly

### UI in 3D (SubViewport + ViewportTexture)
For 2D UI rendered on 3D meshes:
1. Create `SubViewport` with `transparent_bg = true`, `disable_3d = true`
2. Create `ViewportTexture` with `viewport_path` pointing to SubViewport
3. Create `StandardMaterial3D` with `shading_mode = 0` and `albedo_texture` set to ViewportTexture
4. Apply material to mesh via `surface_material_override/0`

### Type Safety in Godot 4
- `lerp()` requires ALL arguments to be the same type (all float or all int)
- Cast explicitly: `lerp(float(value), float(target), amount)`
- Use `lerpf()` when working with shader parameters that may be int or float
- Signal callbacks receiving ints should cast to float before lerp operations

## 7. QA Testing Philosophy: "You Build It, You Own It"

### The Developer's Responsibility
When you fix something, you own the entire user experience around it:
1. **Don't just verify "does it compile?"** - Actually PLAY the game
2. **Don't just verify "does it start?"** - Test ALL user interactions
3. **Test input combinations users will try** - Rapid clicks, holding buttons, edge cases
4. **If it breaks, it's YOUR responsibility** - No passing blame

### Full Game Flow Testing Checklist
Before claiming any fix is complete:
- [ ] Menu navigation works (all buttons)
- [ ] Song selection and difficulty selection work
- [ ] Game loads and plays without errors
- [ ] Notes spawn and can be hit
- [ ] Scoring and combo system work
- [ ] Energy bar updates correctly
- [ ] Pause/resume works
- [ ] Return to menu works
- [ ] VR controller inputs (trigger, grip) work correctly

### Common Mistakes to Avoid
1. **Testing beats ≠ Testing gameplay**: Just because beats fire doesn't mean note collision works
2. **No audio spam**: Check that sounds play ONCE, not every frame
3. **Check `is_button_pressed` vs `is_button_just_pressed`**: One returns true every frame, one returns true once
4. **Test with low/zero energy**: Edge cases often break first

### Investigating Issues Systematically
When QA reports a bug:
1. **Reproduce it yourself first** - Don't assume, verify
2. **Trace the code path** - Use grep to find all related code
3. **Check the original Godot 3 version** - Was it always like this?
4. **Fix ALL instances** - Don't just patch one occurrence
5. **Test the fix** - Play the game, don't just run it

## 8. Running Unit Tests

**CRITICAL:** Always run unit tests after making ANY changes to ensure nothing was broken.

### How to Run Tests
```bash
cd src/
godot --headless --script res://tests/test_textures.gd
```

The test script will:
- Validate all resource files load correctly
- Test scene instantiation
- Verify VR raycast compatibility
- Check UICanvasInteract nodes have required meshes
- Validate menu-to-game flow

### Expected Output
Tests should end with:
```
=== Test Summary ===
✓ ALL TESTS PASSED
```

Or if there are failures:
```
✗ SOME TESTS FAILED
```

### When to Run Tests
- **After fixing bugs**: Verify the fix doesn't break other functionality
- **After adding features**: Ensure new code integrates properly
- **Before committing**: Always verify tests pass before making a commit
- **After modifying scenes**: Especially UICanvasInteract-based scenes

### Common Test Failures
- **"Node not found" errors in headless mode**: Some tests have limitations in headless Godot. Verify the actual game runs correctly using `mcp_godot-ai_play_scene`.
- **Script compilation errors**: Missing autoloads (Global, Events, GameVariables). These are expected in isolated headless tests.
- **Resource loading errors**: Check file paths are correct (res:// paths relative to project.godot).

## 9. Font Configuration

### Project Font Settings
- **Global default font**: Set in `project.godot` under `[gui]` section
  ```
  theme/custom_font="res://fonts/millimetre-font-64.tres"
  ```
- **Theme font**: Set in `ui_theme.tres` via `default_font` property
- **Per-node override**: Use `theme_override_font_sizes/font_size` property

### Font Size Standard
- Default font size across the game: **64**
- All buttons and labels should use `theme_override_font_sizes/font_size = 64` unless specifically designed otherwise
- The font resource `millimetre-font-64.tres` references `Millimetre-Bold.otf`

### Finding Font Issues
```bash
# Find all font size overrides
grep -r "font_size" scenes/*.tscn

# Check project font settings  
cat project.godot | grep -A5 "\[gui\]"
```

## 10. VR UI Button Configuration

### Button Signals for VR Raycast
The VR raycast system (`Feature_UIRayCast.gd` + `UIArea.gd`) pushes mouse events to SubViewport UIs. However, button release events don't always properly trigger the `pressed` signal.

**Rule:** For buttons in VR UI, use `button_down` signal instead of `pressed`:
```gdscript
# WRONG - may not fire with VR raycast
button.pressed.connect(_on_button_pressed)

# CORRECT - fires immediately on click
button.button_down.connect(_on_button_pressed)
```

### Button Properties for VR
When adding buttons to VR-compatible UI scenes:
1. **mouse_filter = 0** (STOP) - Ensures button captures input instead of passing through
2. **Connect signals in code** - Scene file signal connections may not work reliably with VR raycast input
3. **Use `button_down` signal** - The `pressed` signal (which fires on release) doesn't work reliably with VR raycast

### Example: Connecting Buttons in Code
```gdscript
func _ready():
    var my_button = $Path/To/Button
    if my_button and not my_button.button_down.is_connected(_on_button_pressed):
        my_button.button_down.connect(_on_button_pressed)
```

### ItemList in VR UI
When using ItemList with scroll buttons:
- **Remove `size_flags_vertical = 3`** (EXPAND_FILL) from ItemList - otherwise it expands to fit all content and pushes buttons off-screen
- Set a fixed height via `custom_minimum_size`
- Disable parent ScrollContainer scrolling (`horizontal_scroll_mode = 0`, `vertical_scroll_mode = 0`) if ItemList handles its own scrolling

## 11. UICanvasInteract Panel Sizing

### How UICanvasInteract Works
The `UICanvasInteract.tscn` scene renders 2D UI on a 3D mesh for VR interaction. It automatically resizes based on the Control child's size:

1. At runtime, `UICanvasInteract.gd` finds the first Control child node
2. Gets the Control's `get_combined_minimum_size()` 
3. Scales the `UIArea` mesh and `SubViewport` to match
4. Uses `UI_PIXELS_TO_METER = 1.0 / 1024` for conversion

### Resizing a UICanvasInteract Panel

To set the size of a UI panel (like `ui_playlist.tscn` or `ui_song_list.tscn`):

1. **Set `custom_minimum_size` on the root Control node:**
   ```
   [node name="UI_Playlist" type="VBoxContainer"]
   custom_minimum_size = Vector2(1468, 768)
   ```

2. **Set `custom_minimum_size` on key child elements** (like ItemList):
   ```
   [node name="PlaylistItems" type="ItemList" parent="ListContainer"]
   custom_minimum_size = Vector2(1436, 636)
   ```

3. **Add `size_flags_vertical = 3`** to containers that should expand to fill space:
   ```
   [node name="ListContainer" type="VBoxContainer" parent="."]
   layout_mode = 2
   size_flags_vertical = 3
   ```

### Reference Sizes (Song Select Menu)
- **Overall panel**: `custom_minimum_size = Vector2(1468, 768)`
- **ItemList**: `custom_minimum_size = Vector2(1436, 636)`

### After Changing Sizes
If the editor doesn't reflect size changes immediately:
1. Open the UI scene directly (e.g., `ui_playlist.tscn`)
2. Reopen the parent scene (e.g., `MainMenu.tscn`)
3. The UICanvasInteract will recalculate sizes at runtime

### Creating a New UICanvasInteract Panel
1. Create a new UI scene with a Control root (VBoxContainer, MarginContainer, etc.)
2. Set `custom_minimum_size` on the root to desired dimensions
3. In MainMenu.tscn, instance `UICanvasInteract.tscn`
4. Add your UI scene as a child of the UICanvasInteract instance
5. Set `transparent = true` on UICanvasInteract if needed
6. Position/rotate the UICanvasInteract in 3D space

## 12. Quest Device Tools

Documentation for Quest VR headset management tools is located in the `tools/` directory:

- **[QUEST_WAKEUP.md](tools/QUEST_WAKEUP.md)** - How to wake up the Quest display remotely via ADB (useful for screenshots and remote debugging)

## 13. Remote Debugging System (Quest/AI-Assisted Testing)

The project includes a remote debugging system that allows AI assistants to test the game on Quest without human interaction.

### Key Files

| File | Purpose |
|------|---------|
| `src/scripts/GameManager.gd` | Contains `debug_start_scene` and `debug_test_song` export variables |
| `src/scripts/DebugController.gd` | Keyboard-based debug controller for remote input via ADB |
| `docs/QUEST_MCP_DEBUGGING.md` | Full documentation for Quest MCP debugging workflow |
| `DEBUG_ON_QUEST.md` | Performance testing and optimization guide |

### Debug Configuration (GameManager.tscn Inspector)

| Property | Values | Description |
|----------|--------|-------------|
| `debug_start_scene` | `Menu`, `Game`, `GameTest`, `CustomSongTest` | Scene to load on startup |
| `debug_test_song` | e.g., `"Matt Gray - Sanxion Loader 2014 Remake Preview.mp3"` | Song filename for CustomSongTest mode (filename only, not full path) |

**Recommended test song:** `Matt Gray - Sanxion Loader 2014 Remake Preview.mp3` - a known working song for debugging.

### Debug Start Scene Modes

- **Menu** - Normal startup, shows main menu
- **Game** - Load Game.tscn directly (requires `GameVariables.path` set elsewhere)
- **GameTest** - Auto-load `res://Levels/test` for built-in test level
- **CustomSongTest** - Auto-load song specified in `debug_test_song` from PowerBeatsVRLevels

### DebugController Keyboard Commands (via ADB)

```bash
# Send key events to the game
adb shell input keyevent KEYCODE_F1  # Start test level
adb shell input keyevent KEYCODE_F2  # Return to menu
adb shell input keyevent KEYCODE_F3  # Print game state to logs
adb shell input keyevent KEYCODE_F4  # Toggle debug overlay
adb shell input keyevent KEYCODE_1   # Set difficulty: Beginner
adb shell input keyevent KEYCODE_5   # Set difficulty: Expert
```

### Typical AI Testing Workflow

1. **Configure test song** - Set `debug_test_song = "Matt Gray - Sanxion Loader 2014 Remake Preview.mp3"` in GameManager.tscn inspector
2. **Set debug mode** - Set `debug_start_scene = "CustomSongTest"` 
3. **Build and deploy** - `/home/guy/vpy/bin/python tools/deploy_quest.py`
4. **Wake device** - `adb shell input keyevent KEYCODE_WAKEUP`
5. **Start app** - `adb shell am start -n com.tempovr.game/com.godot.game.GodotApp`
6. **Capture logs** - `adb logcat -d -s godot:* | tail -100`
7. **Take screenshot** - Use MCP mobile tools or `adb exec-out screencap -p > screenshot.png`
8. **Revert for commit** - Set `debug_start_scene = "Menu"` and clear `debug_test_song`

### Important Notes

- **Never commit with hardcoded test songs** - Always clear `debug_test_song` before committing
- **debug_test_song is filename only** - Just `"Song.mp3"`, not the full path
- **DebugController reads from GameManager** - No hardcoded values in DebugController.gd
- See `docs/QUEST_MCP_DEBUGGING.md` for detailed debugging procedures
