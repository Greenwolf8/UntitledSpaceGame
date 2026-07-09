extends CharacterBody3D

@export var speed := 80
@export var rotation_speed := 1
@onready var player : RigidBody3D
@export var ai_health_label : Label


enum State { PATROL, CHASE, ATTACK}
var current_state = State.CHASE
var player_position := Vector3.ZERO
var ai_health : int = 100



func _ready() -> void:
	player = get_tree().get_first_node_in_group("player_ship") as RigidBody3D
	ai_health_label.text = "Enemy Ship Health: " + str(ai_health)
	$CollisionArea.area_entered.connect(_on_area_entered)

func _physics_process(delta):
	var target_position = Vector3.ZERO
	if player:
		player_position = player.global_position
	match current_state:
		State.PATROL:
			target_position = Vector3(250,200,400)
		State.CHASE:
			target_position = player_position
	
	if global_position.distance_to(target_position) > 100:
		var target_transform = global_transform.looking_at(target_position, Vector3.UP)
		global_transform = global_transform.interpolate_with(target_transform, rotation_speed * delta)
	else:
		var target_transform = global_transform.looking_at(target_position + (player.global_transform.basis.y * 200), Vector3.UP)
		global_transform = global_transform.interpolate_with(target_transform, rotation_speed * delta)
	
	velocity = -global_transform.basis.z.normalized() * speed
	move_and_slide()

func hit():
	ai_health -= 10
	ai_health_label.text = "Enemy Ship Health: " + str(ai_health)
	if ai_health <= 0:
		self.hide()
		print("Enemy Destroyed!")
		set_physics_process(false)
	

func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("bullet"):
		hit()
		area.queue_free() 
