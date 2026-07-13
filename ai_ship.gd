extends CharacterBody3D

@export var speed := 120
@export var rotation_speed := 1.5
@export var pitch_speed := 1.0
@export var bullet_scene : PackedScene = preload("res://Enemy_bullet.tscn")
@export var ai_health_label : Label
@export var state_label : Label
@export var distance_label : Label
@export var roll_threshold: float = 0.25
@onready var state_timer = %StateTimer
@onready var fire_point = %Hardpoint_1/Cannon/Cannon/MuzzleExit
@onready var fire_timer = %Hardpoint_1/Cannon/Cannon/FireTimer
@onready var player : RigidBody3D

enum State { PATROL, CHASE, BOOM, ZOOM}
var current_state = State.CHASE
var player_position := Vector3.ZERO
var ai_health : int = 200
var target_position = Vector3.ZERO
var zooming = false
var new_target_needed = true

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player_ship") as RigidBody3D
	ai_health_label.text = "Enemy Ship Health: " + str(ai_health)
	state_label.text = "State: " + str(current_state) + str(zooming)
	distance_label.text = "Distance: " + str(global_position.distance_to(player_position))
	%Exterior.area_entered.connect(_on_area_entered)
	current_state = State.BOOM
	%Trigger.add_exception(self)

func _physics_process(delta):
	state_label.text = "State: " + str(current_state) + " " + str(zooming)
	distance_label.text = "Distance: " + str(global_position.distance_to(player_position))
	
	if %Trigger.is_colliding():
		shoot()
	
	var current_transform = global_transform
	var forward_direction = -current_transform.basis.z.normalized()
	var upwards_direction = current_transform.basis.y.normalized()
	
	if player:
		player_position = player.global_position
	
	match current_state:
		State.BOOM:
			target_position = player_position
			if global_position.distance_to(player_position) < 100:
				current_state = State.ZOOM
				zooming = true
				target_position = global_position + (upwards_direction * 400)
		State.ZOOM:
			if global_position.distance_to(player_position) > 400:
				zooming = false
				current_state = State.BOOM
	
	var dir_to_target = (target_position - global_position).normalized()
	var local_forward = -global_transform.basis.z 
	var local_up = global_transform.basis.y
	var local_right = global_transform.basis.x
	var dot_up = dir_to_target.dot(local_up)
	var dot_right = dir_to_target.dot(local_right)
	var roll_error = atan2(dot_right, dot_up)
	
	if abs(roll_error) > 0.01: 
		var roll_step = sign(roll_error) * min(abs(roll_error), rotation_speed * delta)
		rotate_object_local(Vector3.BACK, -roll_step) 
	
	if abs(roll_error) < roll_threshold:
		var dot_forward = dir_to_target.dot(local_forward)
		var pitch_error = atan2(dot_up, dot_forward)
		
		if abs(pitch_error) > 0.01:
			var pitch_step = sign(pitch_error) * min(abs(pitch_error), pitch_speed * delta)
			rotate_object_local(Vector3.RIGHT, pitch_step)
	
	velocity = -global_transform.basis.z.normalized() * speed
	move_and_slide()

func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("bullet"):
		hit()
		area.queue_free()

func hit():
	ai_health -= randi_range(2, 10)
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
