extends Node

# VRRecenter - Manages VR room scale orientation reset and persistence
# Stores position and rotation offset that is applied to XROrigin3D
# Persisted via Settings autoload

const RECENTER_HOLD_TIME := 3.0  # seconds

var _xr_origin: XROrigin3D = null
var _xr_camera: XRCamera3D = null

# Current offset values (applied to XROrigin3D)
var _offset_position := Vector3.ZERO
var _offset_rotation := 0.0  # Y-axis rotation in radians

func _ready():
	# Load saved offset on startup
	load_offset()

func set_xr_nodes(origin: XROrigin3D, camera: XRCamera3D):
	"""Set references to the XR nodes. Called after XR is initialized."""
	_xr_origin = origin
	_xr_camera = camera
	# Apply saved offset once we have the nodes
	apply_offset()

func load_offset():
	"""Load the saved offset from Settings."""
	_offset_position = Settings.get_setting("vr", "recenter_offset_position", Vector3.ZERO)
	_offset_rotation = Settings.get_setting("vr", "recenter_offset_rotation", 0.0)
	print("VRRecenter: Loaded offset - position: ", _offset_position, ", rotation: ", _offset_rotation)

func save_offset():
	"""Save the current offset to Settings."""
	Settings.set_setting("vr", "recenter_offset_position", _offset_position)
	Settings.set_setting("vr", "recenter_offset_rotation", _offset_rotation)
	print("VRRecenter: Saved offset - position: ", _offset_position, ", rotation: ", _offset_rotation)

func apply_offset():
	"""Apply the stored offset to the XROrigin3D node."""
	if _xr_origin == null:
		print("VRRecenter: Cannot apply offset - XROrigin3D not set")
		return
	
	# Apply rotation around Y axis
	_xr_origin.rotation.y = _offset_rotation
	
	# Apply position offset
	_xr_origin.position = _offset_position
	
	print("VRRecenter: Applied offset to XROrigin3D")

func recenter():
	"""Recenter the VR space based on current HMD position and orientation.
	
	This calculates the offset needed to make the current HMD forward direction
	become the 'forward' direction in the game world (negative Z).
	"""
	if _xr_origin == null or _xr_camera == null:
		print("VRRecenter: Cannot recenter - XR nodes not set")
		return
	
	# Get the current HMD (camera) transform
	var camera_transform = _xr_camera.global_transform
	
	# Get the forward direction of the camera (negative Z in camera space)
	var camera_forward = -camera_transform.basis.z
	# Project onto XZ plane (ignore vertical component)
	camera_forward.y = 0
	camera_forward = camera_forward.normalized()
	
	# Calculate the angle between current forward and world forward (-Z)
	var world_forward = Vector3(0, 0, -1)
	var angle = camera_forward.signed_angle_to(world_forward, Vector3.UP)
	
	# The rotation offset is the negative of this angle
	# (we rotate the origin so that the camera's forward becomes world forward)
	_offset_rotation = angle
	
	# Calculate position offset to center on HMD position
	# We want the HMD's XZ position to become the origin (0, 0, 0) in room space
	var camera_pos = _xr_camera.global_position
	
	# Apply the rotation to the position offset as well
	var rotated_offset = Vector3(-camera_pos.x, 0, -camera_pos.z).rotated(Vector3.UP, angle)
	_offset_position = rotated_offset
	
	# Apply and save
	apply_offset()
	save_offset()
	
	print("VRRecenter: Recentered - new rotation: ", rad_to_deg(_offset_rotation), " degrees")

func clear_offset():
	"""Clear the offset and reset to default."""
	_offset_position = Vector3.ZERO
	_offset_rotation = 0.0
	apply_offset()
	save_offset()
	print("VRRecenter: Offset cleared")

# Static helper functions for offset calculations (useful for testing)
static func calculate_rotation_offset(camera_forward: Vector3) -> float:
	"""Calculate the Y rotation offset given a camera forward direction."""
	var forward = camera_forward
	forward.y = 0
	if forward.length_squared() < 0.001:
		return 0.0
	forward = forward.normalized()
	
	var world_forward = Vector3(0, 0, -1)
	return forward.signed_angle_to(world_forward, Vector3.UP)

static func calculate_position_offset(camera_position: Vector3, rotation_offset: float) -> Vector3:
	"""Calculate the position offset given camera position and rotation offset."""
	var offset = Vector3(-camera_position.x, 0, -camera_position.z)
	return offset.rotated(Vector3.UP, rotation_offset)

