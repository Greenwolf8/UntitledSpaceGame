extends CharacterBody3D

@export var speed := 50

func _physics_process(delta:):
	var forward_direction = -global_transform.basis.y * speed
	global_position += forward_direction * speed * delta
