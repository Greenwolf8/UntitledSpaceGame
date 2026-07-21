extends Area3D

func _ready() -> void:
	body_entered.connect(_on_area_3d_body_entered)
	body_exited.connect(_on_area_3d_body_exited)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		Global.on_ladder = true
		print("Player Touching Ladder!")

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		Global.on_ladder = false
