extends CharacterBody3D

@export var speed: float = 250
@export var rotation_speed: float = 1.6
@export var pitch_speed: float = 0.8
@export var ai_health_label: Label
@export var state_label: Label
@export var distance_label: Label
@export var roll_threshold: float = 0.25
@export var muzzle_spread: float = 0.25

@onready var bullet_scene : PackedScene = preload("res://Enemy_bullet.tscn")
@onready var state_timer: Timer = %StateTimer
@onready var fire_point = %Hardpoint_1/Cannon/Cannon/MuzzleExit
@onready var fire_timer = %Hardpoint_1/Cannon/Cannon/FireTimer
@onready var sight_area = %Sight
@onready var player : RigidBody3D

enum State {PATROL, BOOM, ZOOM, EVADE, PLAYER_DESTROYED}
var current_state = State.PATROL
var player_position: Vector3 = Vector3.ZERO
var ai_health : int = 200
var target_position: Vector3 = Vector3.ZERO
var zooming: bool = false
var current_speed: int = 175
var evade_vector: Vector3 = Vector3.ZERO
var boom_offset: Vector3 = Vector3.ZERO
var evade_roll_dir: float = 1

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player_ship") as RigidBody3D
	if ai_health_label:
		ai_health_label.text = "Enemy Ship Health: " + str(ai_health)
	%Exterior.area_entered.connect(_on_area_entered)
	%Trigger.add_exception(self)

func _physics_process(delta):
	if not player:
		return
	
	player_position = player.global_position
	var dist_to_player = global_position.distance_to(player_position)
	
	if state_label:
		state_label.text = "State: " + str(current_state)
	if distance_label:
		if global_position.distance_to(player_position) > 999:
			distance_label.text = "Distance To Enemy: " + str(snappedf(global_position.distance_to(player_position) / 1000, 0.1)) + "km"
		else:
			distance_label.text = "Distance To Enemy: " + str(int(round(global_position.distance_to(player_position)))) + "m"
	
	if %Trigger.is_colliding() and current_state == State.BOOM:
		shoot()
	
	var local_forward = -global_transform.basis.z
	var local_up = global_transform.basis.y
	var local_right = global_transform.basis.x
	
	match current_state:
		State.PATROL:
			if current_speed < speed * 0:
				current_speed += 1
			elif current_speed > speed * 0:
				current_speed -= 1
			
			target_position = global_position
			if global_position.distance_to(player_position) <= 1500:
				current_state = State.BOOM
				if Global.current_task == 3:
					Global.next_task()
		
		State.BOOM:
			if current_speed < speed * 1.025:
				current_speed += 1
			elif current_speed > speed * 0.975:
				current_speed -= 1
				
			target_position = player_position + (player.global_transform.basis.x * boom_offset.x)
				
			if dist_to_player < 220:
				current_state = State.ZOOM
				state_timer.start(2.5)
				
			if Global.player_ship_destroyed:
				current_state = State.PLAYER_DESTROYED
			
		State.ZOOM:
			if current_speed < speed * 1.5:
				current_speed += 1
			elif current_speed > speed * 1.5:
				current_speed -= 1
				
			target_position = global_position + (local_forward * 500) + (local_up * 150)
			
			if state_timer.is_stopped():
				boom_offset = Vector3(randf_range(-40.0, 40.0), randf_range(-20.0, 20.0), 0)
				current_state = State.BOOM
		State.EVADE:
			if current_speed < speed * 1.3:
				current_speed += 1
			elif current_speed > speed * 1.3:
				current_speed -= 1
			rotate_object_local(Vector3.RIGHT, pitch_speed * 1.3 * delta)
			rotate_object_local(Vector3.BACK, rotation_speed * 0.9 * evade_roll_dir * delta)
			
			if state_timer.is_stopped():
				current_state = State.BOOM
		
		State.PLAYER_DESTROYED:
			if current_speed < speed * 0.5:
				current_speed += 1
			elif current_speed > speed * 0.5:
				current_speed -= 1
			target_position = global_position + (local_up * 250) + (local_forward * 250)
	
	if current_state != State.EVADE:
		var dir_to_target = (target_position - global_position).normalized()
		var dot_up = dir_to_target.dot(local_up)
		var dot_right = dir_to_target.dot(local_right)
		var roll_error = atan2(dot_right, dot_up)
		
		if current_state == State.BOOM:
			pitch_speed = 1
		elif current_state == State.ZOOM:
			pitch_speed = 1.25
		else:
			pitch_speed = 0.8
		
		if abs(roll_error) > 0.01: 
			var roll_step = sign(roll_error) * min(abs(roll_error), rotation_speed * delta)
			rotate_object_local(Vector3.BACK, -roll_step) 
		
		if abs(roll_error) < roll_threshold:
			var dot_forward = dir_to_target.dot(local_forward)
			var pitch_error = atan2(dot_up, dot_forward)
			
			if abs(pitch_error) > 0.01:
				var pitch_step = sign(pitch_error) * min(abs(pitch_error), pitch_speed * delta)
				rotate_object_local(Vector3.RIGHT, pitch_step)
	
	velocity = -global_transform.basis.z.normalized() * current_speed
	
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
	if current_state != State.EVADE and randf() < 0.6:
		trigger_evasion()
	if ai_health <= 0:
		self.hide()
		print("Enemy Destroyed!")
		set_physics_process(false)

func shoot():
	var bullet = bullet_scene.instantiate()
	if fire_timer.is_stopped():
		fire_timer.start()
		get_tree().root.add_child(bullet)
		bullet.global_transform = fire_point.global_transform
		bullet.rotate_object_local(Vector3.RIGHT, randf_range(-muzzle_spread, muzzle_spread))
		bullet.rotate_object_local(Vector3.UP, randf_range(-muzzle_spread, muzzle_spread))

func trigger_evasion():
	current_state = State.EVADE
	evade_roll_dir = 1 if randf() > 0.5 else -1
	state_timer.start(randf_range(2, 4))
