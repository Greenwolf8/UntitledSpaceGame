extends Node3D

@onready var screen_left_mesh: MeshInstance3D = $ScreenLeft
@onready var screen_viewport: SubViewport = $ScreenViewport

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var viewport_texture = screen_viewport.get_texture()
	var mat = screen_left_mesh.material_override as StandardMaterial3D
	Global.in_hangar = true

	if mat:
		mat.albedo_texture = viewport_texture
