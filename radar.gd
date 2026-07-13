extends Control

@export var player_ship: Node3D
@export var radar_range: float = 800.0
@export var blip_scene: PackedScene = preload("res://Radar_Blip.tscn")

var radar_radius : float

@onready var blip_container: Control = $BlipContainer

func _ready() -> void:
	radar_radius = size.x / 2.0

func _process(delta: float) -> void:
	for child in blip_container.get_children():
		child.queue_free()
	
	var targets = get_tree().get_nodes_in_group("enemy_ship")
	
	for target in targets:
		if target is Node3D:
			var local_pos = player_ship.to_local(target.global_position)
			var distance = Vector2(local_pos.x, local_pos.y).length()
			
			if distance <= radar_range:
				var radar_x = (local_pos.x / radar_range) * radar_radius
				var radar_y = (local_pos.z / radar_range) * radar_radius
				
				var blip = blip_scene.instantiate()
				blip_container.add_child(blip)
				
				blip.position = Vector2(radar_radius + radar_x, radar_radius + radar_y)
