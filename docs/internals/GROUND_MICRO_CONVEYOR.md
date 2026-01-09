# Dual Mesh Conveyor Belt Ground System

## Overview

The Dual Mesh Conveyor Belt system creates smooth infinite scrolling terrain that is:
1. **Free of vertex pumping** - vertices move WITH the mesh instead of sampling moving noise
2. **SpaceWarp compatible** - no visible motion discontinuities that confuse frame prediction

### The Problems

**Problem 1: Vertex Pumping**
When scrolling terrain using `TIME * speed` in a shader:
- Noise values scroll through **fixed vertex positions**
- Vertices "pump" up and down as new noise values pass through them
- At low subdivision levels, this creates visible ripples/waves

**Problem 2: SpaceWarp Artifacts**
The original micro conveyor solution snapped the mesh back every 0.5 world units:
- SpaceWarp predicts frame motion based on motion vectors
- Sudden position resets create **motion discontinuities**
- SpaceWarp sees the mesh jump backward, causing stutter/artifacts

### The Solution

Use **two meshes** that leapfrog each other:
1. Both meshes move continuously in the same direction (+Z toward player)
2. When a mesh goes **fully behind the player** (out of view), it teleports ahead
3. Each mesh has its own UV offset (via instance uniform) that increments on teleport
4. **Result**: All visible motion is smooth and predictable for SpaceWarp

```
View frustum (player looking -Z)
       ┌────────────────┐
       │                │
  [A]══│═══════════════>│═══>  (A exits view, teleport to front)
       │                │
  [B]══│═══════════════>│═══>  (B visible, smooth motion)
       │                │
       └────────────────┘
```

---

## Key Components

### Files

| File | Purpose |
|------|---------|
| `src/scripts/Ground.gd` | Script that controls dual mesh movement and teleport |
| `src/effects/Ground.tres` | Shader material with instance uniform for per-mesh UV offset |
| `src/scenes/Ground.tscn` | Scene with two ground meshes (GroundShapeA, GroundShapeB) |
| `src/scenes/GroundCurveTest.tscn` | Test scene for debugging (uses different system) |

### Shader Uniforms

| Uniform | Type | Purpose |
|---------|------|---------|
| `uv_offset_z` | instance float | Per-mesh UV offset (set via `set_instance_shader_parameter`) |
| `mesh_size_z` | float | Mesh local size for triplanar offset conversion |
| `debug_height_colors` | bool | Enable height visualization (red=peak, blue=valley) |
| `enable_curve` | bool | Enable curved world effect |
| `curve_strength` | float | How much to bend terrain at distance |

### Script Variables

| Variable | Type | Purpose |
|----------|------|---------|
| `ground_size` | float | Mesh local size (before transform scale) |
| `subdivisions` | int | Number of mesh subdivisions (must match PlaneMesh) |
| `grid_scale` | float | Texture tiling (lower = bigger grid squares) |
| `teleport_threshold` | float | When mesh.position.z > this, teleport |
| `teleport_distance` | float | How far to jump back (2 mesh lengths) |
| `uv_per_teleport` | float | UV increment per teleport |

---

## The Math

### Coordinate Spaces

```
┌─────────────────────────────────────────────────────────────────┐
│ COORDINATE SPACE RELATIONSHIPS                                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  UV Space:        0 ────────────────────────────────────── 1    │
│                   │              (normalized)              │    │
│                   │                                        │    │
│  VERTEX Space:   -4 ────────────────────────────────────── +4   │
│  (mesh local)     │         (mesh_size = 8)                │    │
│                   │                                        │    │
│  World Space:   -32 ────────────────────────────────────── +32  │
│  (after scale)    │    (mesh_size × transform_scale = 64)  │    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### Key Parameters

| Parameter | Value | Calculation |
|-----------|-------|-------------|
| mesh_size | 8.0 | PlaneMesh size |
| mesh_scale | 8x | Transform3D scale |
| world_size | 64 | mesh_size × mesh_scale |
| subdivisions | 128 | PlaneMesh subdivide_depth |
| grid_scale | 2.0 | uv1_scale |
| teleport_threshold | 64.0 | world_size (mesh fully behind player) |
| teleport_distance | 128.0 | world_size × 2 (jump 2 mesh lengths) |
| uv_per_teleport | 4.0 | (teleport_distance / subdivision_period_world) × subdivision_period_uv |

### Subdivision Period Calculations

These are still used for UV offset calculations:

**World Period** (distance for one subdivision):
```
world_period = world_size / subdivisions
             = 64 / 128
             = 0.5 world units
```

**UV Period** (UV change for one subdivision):
```
uv_period = grid_scale / subdivisions
          = 2 / 128
          = 0.015625
```

### Initial UV Offset for Mesh B

Mesh B starts one world_size ahead of Mesh A (-64 in Z). To maintain texture continuity:
```
uv_offset_b = (world_size / world_period) × uv_period
            = (64 / 0.5) × 0.015625
            = 128 × 0.015625
            = 2.0
```

---

## Implementation Details

### Dual Mesh Teleport Logic (`Ground.gd`)

```gdscript
func _process(delta: float):
    if speed == 0.0:
        return
    
    var movement = speed * delta
    
    # Both meshes always move forward (+Z direction)
    mesh_a.position.z += movement
    mesh_b.position.z += movement
    
    # Teleport when fully behind player (out of view)
    if mesh_a.position.z > teleport_threshold:
        mesh_a.position.z -= teleport_distance
        uv_offset_a += uv_per_teleport
        mesh_a.set_instance_shader_parameter("uv_offset_z", uv_offset_a)
    
    if mesh_b.position.z > teleport_threshold:
        mesh_b.position.z -= teleport_distance
        uv_offset_b += uv_per_teleport
        mesh_b.set_instance_shader_parameter("uv_offset_z", uv_offset_b)
```

### Instance Uniforms in Shader (`Ground.tres`)

The shader uses an **instance uniform** so each mesh can have its own UV offset:

```glsl
// Instance uniform allows per-mesh values while sharing material
instance uniform float uv_offset_z : hint_range(0, 1000) = 0.0;

void vertex() {
    // Calculate scrolled UV using per-instance offset
    v_scrolled_uv = UV * uv1_scale.xz + vec2(0.0, -uv_offset_z);
    
    // Calculate triplanar position with scaled offset
    float triplanar_offset_z = uv_offset_z * mesh_size_z;
    uv1_triplanar_pos = VERTEX * uv1_scale + vec3(0, 0, -triplanar_offset_z);
    
    // Sample noise and displace vertex
    float heightmap = texture(noise, v_scrolled_uv / uv1_scale.x).r;
    VERTEX.y += heightmap * displace_amount;
}
```

### Reset Function

```gdscript
func reset_ground():
    # Reset positions: A at origin, B one world_size ahead
    mesh_a.position.z = 0.0
    mesh_b.position.z = -world_size
    
    # Reset UV offsets (B is one mesh-length ahead)
    var uv_per_mesh_length = (world_size / subdivision_period_world) * subdivision_period_uv
    uv_offset_a = 0.0
    uv_offset_b = uv_per_mesh_length  # 2.0 with default settings
    
    # Apply via instance parameters
    mesh_a.set_instance_shader_parameter("uv_offset_z", uv_offset_a)
    mesh_b.set_instance_shader_parameter("uv_offset_z", uv_offset_b)
```

---

## Why This Works

### Seamless Seams

At the seam between meshes (e.g., z=-32 where Mesh A's front meets Mesh B's back):
- Mesh A front samples UV that wraps to match Mesh B's back
- The noise texture is seamless (`seamless = true`), so wrap-around is invisible

### SpaceWarp Compatibility

| Old System | New System |
|------------|------------|
| Mesh snaps back every 0.5 units | Mesh teleports every 64+ units |
| Snap happens **in view** | Teleport happens **behind player** |
| SpaceWarp sees discontinuous motion | SpaceWarp sees smooth +Z motion |
| Motion vectors flip direction | Motion vectors always +Z |

---

## Debugging

### Debug Mode

Enable debug coloring to visualize terrain height:

```gdscript
$Ground.set_debug_mode(true)
```

Colors:
- 🔴 **Red** = Peaks (high terrain)
- 🟢 **Green** = Middle elevation
- 🔵 **Blue** = Valleys (low terrain)
- ⬜ **White grid lines** = UV cell boundaries

### Verifying Seamlessness

1. Enable debug mode
2. Watch the seam between meshes as they scroll
3. Colors should remain stable on terrain features
4. No visible "jump" when teleport occurs (it's behind you)

### Common Issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| Texture slides relative to mountains | Triplanar offset not scaled by `mesh_size_z` | Ensure `material.set_shader_parameter("mesh_size_z", ground_size)` |
| Visible seam between meshes | Initial UV offset for mesh B incorrect | Verify `uv_offset_b = uv_per_mesh_length` at startup |
| SpaceWarp still stuttering | Teleport threshold too aggressive | Increase `teleport_threshold` to ensure mesh is fully behind player |
| Mountains too small/fast | `grid_scale` or noise frequency too high | Lower `grid_scale` or adjust noise |

---

## Performance Notes

- **Two meshes vs one**: Negligible performance difference - same total vertex count visible
- **Instance uniforms**: Efficient - no material duplication needed
- **Subdivision count**: 128 is a good balance. Higher = smoother but more vertices
- **Extra cull margin**: Set on MeshInstance3D to prevent culling when vertices are displaced
- **UV offset accumulation**: Will eventually overflow (float precision). Consider wrapping at large values (e.g., every 1000.0) since noise texture is seamless

---

## Future Improvements

- [ ] Add biome coloring based on height (snow on peaks, grass in valleys)
- [ ] Multiple noise layers for varied terrain
- [ ] LOD system for distant terrain
- [ ] Wrap UV offsets to prevent float precision issues over long play sessions
- [x] ~~SpaceWarp-compatible scrolling~~ (DONE - dual mesh system)
