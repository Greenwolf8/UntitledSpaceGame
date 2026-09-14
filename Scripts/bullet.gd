extends CharacterBody3D

@export var speed := 60

func _ready() -> void:
	await get_tree().create_timer(8).timeout
	queue_free()

func _physics_process(delta:):
	var forward_direction = global_transform.basis.y * speed
	global_position += forward_direction * speed * delta
