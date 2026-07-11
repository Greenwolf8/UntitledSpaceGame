extends CharacterBody3D

@export var speed := 120
@export var rotation_speed := 1.5
@onready var player : RigidBody3D
@export var bullet_scene : PackedScene = preload("res://Enemy_bullet.tscn")
@export var ai_health_label : Label
@onready var state_timer = %StateTimer
@onready var fire_point = %Hardpoint_1/Cannon/Cannon/MuzzleExit
@onready var fire_timer = %Hardpoint_1/Cannon/Cannon/FireTimer

enum State { PATROL, CHASE, ATTACK, ZOOM}
var current_state = State.CHASE
var player_position := Vector3.ZERO
var ai_health : int = 100
var target_position = Vector3.ZERO

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player_ship") as RigidBody3D
	ai_health_label.text = "Enemy Ship Health: " + str(ai_health)
	$CollisionArea.area_entered.connect(_on_area_entered)
	current_state = State.ATTACK
	%Trigger.add_exception(self)

func _physics_process(delta):
	
	var current_transform = global_transform
	var forward_direction = -current_transform.basis.z.normalized()
	var upwards_direction = current_transform.basis.y.normalized()
	if player:
		player_position = player.global_position
	match current_state:
		State.ATTACK:
			target_position = player_position
		State.ZOOM:
			pass
	if global_position.distance_to(player_position) >= 100 and state_timer.is_stopped() and current_state == State.ZOOM:
		current_state = State.ATTACK
		state_timer.start()
	elif global_position.distance_to(player_position) < 100 and current_state == State.ATTACK:
		current_state = State.ZOOM
		state_timer.start()
		target_position = current_transform.origin + (forward_direction * 500) + (upwards_direction * 500)
	
	if %Trigger.is_colliding():
		shoot()
	
	var target_transform = global_transform.looking_at(target_position, Vector3.UP)
	global_transform = global_transform.interpolate_with(target_transform, rotation_speed * delta)
	
	velocity = -global_transform.basis.z.normalized() * speed
	move_and_slide()

func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("bullet"):
		hit()
		area.queue_free() 

func hit():
	ai_health -= 10
	if ai_health <0:
		ai_health = 0
	ai_health_label.text = "Enemy Ship Health: " + str(ai_health)
	if ai_health <= 0:
		self.hide()
		print("Enemy Destroyed!")
		set_physics_process(false)

func shoot():
	if fire_timer.is_stopped():
		fire_timer.start()
		var bullet = bullet_scene.instantiate()
		get_tree().root.add_child(bullet)
		bullet.global_transform = fire_point.global_transform
