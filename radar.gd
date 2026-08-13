extends Control

@export var player_ship: Node3D
@export var radar_range: float = 800.0
@export var blip_scene: PackedScene = preload("res://Radar_Blip.tscn")

@onready var blip_container: Control = $BlipContainer

func _process(_delta: float) -> void:
	if not is_instance_valid(player_ship):
		return

	var center: Vector2 = size / 2.0
	var radar_radius: float = min(size.x, size.y) / 2.0

	var targets = get_tree().get_nodes_in_group("enemy_ship")
	var existing_blips = blip_container.get_children()

	# 1. Ensure we have enough blip instances in the container
	while existing_blips.size() < targets.size():
		var new_blip = blip_scene.instantiate()
		blip_container.add_child(new_blip)
		existing_blips.append(new_blip)

	# 2. Hide all blips initially
	for blip in existing_blips:
		blip.hide()

	# 3. Process targets and update corresponding blips
	var active_blip_index: int = 0

	# Get player's flat (Y-only) transform so pitch/roll doesn't warp radar
	var player_yaw_transform: Transform3D = Transform3D(
		Basis(Vector3.UP, player_ship.global_rotation.y), 
		player_ship.global_position
	)

	for target in targets:
		if not target is Node3D:
			continue

		# Relative position ignoring player pitch/roll
		var local_pos: Vector3 = player_yaw_transform.affine_inverse() * target.global_position
		var distance_2d: float = Vector2(local_pos.x, local_pos.z).length()

		if distance_2d <= radar_range:
			# -Z is forward in Godot 3D, mapping cleanly to -Y (UP) in 2D UI
			var radar_x: float = (local_pos.x / radar_range) * radar_radius
			var radar_y: float = (local_pos.z / radar_range) * radar_radius

			var blip: Control = existing_blips[active_blip_index]
			blip.show()

			# Center the blip sprite/control on the calculated point
			var blip_offset: Vector2 = blip.size / 2.0 if blip is Control else Vector2.ZERO
			blip.position = center + Vector2(radar_x, radar_y) - blip_offset

			active_blip_index += 1
