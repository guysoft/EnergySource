# Micro Conveyor Belt Ground System

## Overview

The Micro Conveyor Belt system creates smooth infinite scrolling terrain without the "vertex pumping" artifacts that occur with traditional shader-based UV scrolling.

### The Problem

When scrolling terrain using `TIME * speed` in a shader:
- Noise values scroll through **fixed vertex positions**
- Vertices "pump" up and down as new noise values pass through them
- At low subdivision levels, this creates visible ripples/waves
- Increasing subdivisions improves quality but tanks performance

### The Solution

Instead of scrolling UVs through fixed vertices:
1. **Physically move the mesh** a small amount each frame
2. When it moves one subdivision period, **snap it back** to the start
3. **Increment the UV offset** to compensate
4. Result: Vertices move **with** the mesh, sampling consistent noise values

This eliminates pumping because the same vertices always sample the same relative noise position - they just physically move in world space.

---

## Key Components

### Files

| File | Purpose |
|------|---------|
| `src/scripts/Ground.gd` | Script that controls mesh movement and UV offset |
| `src/effects/Ground.tres` | Shader material with micro conveyor uniforms |
| `src/scenes/Ground.tscn` | Main ground scene with scaled mesh |
| `src/scenes/GroundCurveTest.tscn` | Test scene for debugging (no game dependencies) |

### Shader Uniforms

| Uniform | Type | Purpose |
|---------|------|---------|
| `uv_offset_z` | float | Accumulated UV offset (set by script each reset) |
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
| `subdivision_period_world` | float | World distance before reset |
| `subdivision_period_uv` | float | UV offset increment per reset |

---

## The Math

### Coordinate Spaces

Understanding the different coordinate spaces is crucial:

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

### Period Calculations

**World Period** (how far mesh moves before reset):
```
world_period = (mesh_size × mesh_scale) / subdivisions
             = (8 × 8) / 128
             = 0.5 world units
```

**UV Period** (how much UV offset increases per reset):
```
uv_period = (1 / subdivisions) × grid_scale
          = (1 / 128) × 2
          = 0.015625 (in scaled UV space)
```

### Why Two Different Periods?

The shader uses two coordinate systems for texture sampling:

1. **UV-based** (for height/noise):
   ```glsl
   v_scrolled_uv = UV * uv1_scale + vec2(0, -uv_offset_z);
   float heightmap = texture(noise, v_scrolled_uv / uv1_scale.x).r;
   ```

2. **VERTEX-based** (for triplanar textures):
   ```glsl
   uv1_triplanar_pos = VERTEX * uv1_scale + vec3(0, 0, -triplanar_offset);
   ```

These need different offset values because:
- UV goes `0 → 1` across the mesh
- VERTEX goes `-4 → +4` across the mesh (for size 8)

**The conversion:**
```glsl
float triplanar_offset_z = uv_offset_z * mesh_size_z;
```

### Full Calculation Chain

```
Given:
  mesh_size = 8 (PlaneMesh size)
  mesh_scale = 8 (Transform3D scale)
  subdivisions = 128
  grid_scale = 2 (uv1_scale)

World size:
  world_size = mesh_size × mesh_scale = 8 × 8 = 64

World period (one subdivision in world space):
  world_period = world_size / subdivisions = 64 / 128 = 0.5

UV period (one subdivision in scaled UV space):
  uv_period = grid_scale / subdivisions = 2 / 128 = 0.015625

Triplanar offset conversion:
  triplanar_offset = uv_offset_z × mesh_size = 0.015625 × 8 = 0.125

Verification:
  - UV scrolls by: uv_period / grid_scale = 0.015625 / 2 = 0.0078125 (base UV)
  - VERTEX scrolls by: triplanar_offset / uv1_scale = 0.125 / 2 = 0.0625 (base VERTEX)
  - Base UV to VERTEX: 0.0078125 × 8 = 0.0625 ✓ (they match!)
```

---

## Implementation Details

### Script Flow (`Ground.gd`)

```gdscript
func _process(delta):
    # 1. Move mesh forward
    mesh_offset_z += speed * delta
    
    # 2. Check if we've moved one period
    while mesh_offset_z >= subdivision_period_world:
        mesh_offset_z -= subdivision_period_world  # Snap back
        uv_accumulated_offset += subdivision_period_uv  # Increment UV
    
    # 3. Apply to mesh and shader
    ground_shape.position.z = mesh_offset_z
    material.set_shader_parameter("uv_offset_z", uv_accumulated_offset)
```

### Shader Flow (`Ground.tres`)

```glsl
void vertex() {
    // 1. Calculate scrolled UV (for height sampling)
    v_scrolled_uv = UV * uv1_scale.xz + vec2(0.0, -uv_offset_z);
    
    // 2. Calculate triplanar position (for texture sampling)
    // Convert UV offset to VERTEX space by multiplying by mesh_size
    float triplanar_offset_z = uv_offset_z * mesh_size_z;
    uv1_triplanar_pos = VERTEX * uv1_scale + vec3(0, 0, -triplanar_offset_z);
    
    // 3. Sample noise and displace vertex
    float heightmap = texture(noise, v_scrolled_uv / uv1_scale.x).r;
    VERTEX.y += heightmap * displace_amount;
}
```

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

### Test Scene

Use `src/scenes/GroundCurveTest.tscn` for isolated testing:
- No game dependencies
- Standalone camera and lighting
- Slower speed for easier observation
- Debug mode enabled by default

### Common Issues

| Symptom | Cause | Fix |
|---------|-------|-----|
| Texture slides relative to mountains | Triplanar offset not scaled by `mesh_size_z` | Ensure `material.set_shader_parameter("mesh_size_z", ground_size)` |
| Visible jump on reset | Period calculations don't account for mesh scale | Multiply `mesh_size` by `transform.basis.get_scale().z` |
| Mountains too small/fast | `grid_scale` or noise frequency too high | Lower `grid_scale` or adjust noise |
| Vertex pumping | Not using micro conveyor (using TIME-based scroll) | Use `uv_offset_z` instead of `TIME` |

---

## Adapting for Different Terrain

To create a new terrain type using this system:

### 1. Create the Shader Material

Copy `Ground.tres` and modify:
- Noise texture (different patterns)
- Displacement amount
- Texture sampling

**Required uniforms** (don't remove):
```glsl
uniform float uv_offset_z = 0.0;
uniform float mesh_size_z = 8.0;
```

### 2. Create the Control Script

Copy `Ground.gd` and modify:
- Speed calculation (BPM sync, constant, etc.)
- Any terrain-specific logic

**Required calculations:**
```gdscript
var mesh_scale_z = mesh_node.transform.basis.get_scale().z
var world_size_z = mesh_size * mesh_scale_z
subdivision_period_world = world_size_z / float(subdivisions)
subdivision_period_uv = (1.0 / float(subdivisions)) * texture_scale
```

### 3. Set Shader Parameters

In `setup()` or `_ready()`:
```gdscript
material.set_shader_parameter("uv1_scale", Vector3(texture_scale, texture_scale, texture_scale))
material.set_shader_parameter("mesh_size_z", mesh_size)
material.set_shader_parameter("uv_offset_z", 0.0)
```

### 4. Match Mesh Subdivisions

Ensure `subdivisions` variable matches the PlaneMesh:
```
[sub_resource type="PlaneMesh"]
subdivide_width = 128
subdivide_depth = 128
```

---

## Performance Notes

- **Subdivision count**: 128 is a good balance. Higher = smoother but more vertices
- **Mesh scale**: Using transform scale (8×) instead of larger mesh reduces memory
- **UV offset accumulation**: Will eventually overflow (float precision). Consider wrapping at large values
- **Extra cull margin**: Set on MeshInstance3D to prevent culling when vertices are displaced

---

## Future Improvements

- [ ] Add biome coloring based on height (snow on peaks, grass in valleys)
- [ ] Multiple noise layers for varied terrain
- [ ] LOD system for distant terrain
- [ ] Wrap `uv_accumulated_offset` to prevent float precision issues over long play sessions

