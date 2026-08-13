extends RigidBody3D

@export var engine_power = 150
@export var roll_torque = 1200
@export var pitch_torque = 1250
@export var bullet_scene : PackedScene = preload("res://Bullet.tscn")
@export var muzzle_spread: float = 0.1
@export var shoot_colliding_label: Label
@onready var fire_point = %Hardpoint_1/Cannon/Cannon/MuzzleExit
@onready var fire_timer = %Hardpoint_1/Cannon/Cannon/FireTimer
@onready var pre_fire_timer = %Hardpoint_1/Cannon/Cannon/PreFireTimer
@onready var fire_time = %Hardpoint_1/Cannon/Cannon/FireTime
@onready var camera: Camera3D = %ShipCamera

@onready var speed_label: Label = %Speed
@onready var health_label: Label = %HealthLabel	
@onready var player: CharacterBody3D = get_tree().get_first_node_in_group("Player")

var mouse_input: Vector2 = Vector2.ZERO
var health: int = 200
var Camerafree = false
var withPlayer = false



func _ready() -> void:
	health_label.text = "Health: " + str(health)
	shoot_colliding_label.text = str(Global.shoot_colliding)
	%Exterior.area_entered.connect(_on_area_entered)
	print($Camera3D.position)

func _unhandled_input(event: InputEvent) -> void:
	if Camerafree and event is InputEventMouseMotion:
		camera.rotation_degrees.y -= event.relative.x * 0.2
		camera.rotation_degrees.y = clamp(
			camera.rotation_degrees.y, 0,180
		)
		camera.rotation_degrees.x -= event.relative.y * 0.2
		camera.rotation_degrees.x = clamp(
		camera.rotation_degrees.x, -60, 75 
		)
	elif not Camerafree and event is InputEventMouseMotion:
		mouse_input += event.relative

func _physics_process(_delta):
	shoot_colliding_label.text = str(Global.shoot_colliding)
	if not withPlayer: 
		return
	var forward_input = Input.get_axis("throttle_down", "throttle_up")
	var forward_force = -global_transform.basis.x * forward_input * engine_power
	var current_speed = snapped(linear_velocity.length(), 0.1)
	var yaw_input = Input
	var roll_input = Input.get_axis("move_right", "move_left")
	var pitch_input = Input.get_axis("move_back", "move_forward")
	
	if %ShipShoot.is_colliding():
		Global.shoot_colliding = true
	else: 
		Global.shoot_colliding = false
	
	if forward_input != 0:
		if %Engine_2.volume_db < 5.0:
			%Engine_2.volume_db += 0.1
	elif %Engine_2.volume_db > -5:
		%Engine_2.volume_db -= 0.2
	
	if not Camerafree:
		pitch_input += mouse_input.y * 0.1
		yaw_input = -mouse_input.x * 0.1
	else:
		yaw_input = 0
	
	if Global.ship_on:
		apply_central_force(forward_force)
		apply_torque(transform.basis.z * pitch_input * pitch_torque)
		apply_torque(transform.basis.y * yaw_input * pitch_torque)
		apply_torque(transform.basis.x * roll_input * roll_torque)
		
		if not %Engine_2.playing:
			%Engine_2.play()
	
	mouse_input = Vector2.ZERO
	
	speed_label.text = "Speed: " + str(current_speed)
	
	if Input.is_action_pressed("fire") and withPlayer:
		shoot()
	
	if Input.is_action_just_pressed("fire") and withPlayer:
		%Gun1.play()
		just_shot()
	
	if Input.is_action_just_released("fire"):
		%Gun2.stop()
		%Gun3.play()

func _input(_event: InputEvent) -> void:
	var cantlock = Camerafree

	if Input.is_action_just_pressed("camera_lock") and not cantlock:
		Camerafree = true
	elif Input.is_action_just_pressed("camera_lock") and cantlock:
		Camerafree = false
		%Camera3D.rotation_degrees.x = 0
		%Camera3D.rotation_degrees.y = 90

func just_shot():
	pre_fire_timer.start()
	await get_tree().create_timer(0.05).timeout
	fire_time.start()


func shoot():
	if fire_timer.is_stopped() and pre_fire_timer.is_stopped() and fire_time.time_left > 0:
			%Gun2.play()
			fire_timer.start()
			var bullet = bullet_scene.instantiate()
			get_tree().root.add_child(bullet)
			bullet.global_transform = fire_point.global_transform
			bullet.rotate_object_local(Vector3.RIGHT, randf_range(-muzzle_spread, muzzle_spread))
			bullet.rotate_object_local(Vector3.UP, randf_range(-muzzle_spread, muzzle_spread))

func enter_ship():
	health_label.show()
	withPlayer = true
	%Speed.visible = true
	player = get_tree().get_first_node_in_group("Player")
	camera.current = true
	print("enter ship called!")


func leave_ship():
	health_label.hide()
	withPlayer = false
	%Speed.visible = false
	player = get_tree().get_first_node_in_group("Player")
	print("leave ship called!")

func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("enemy_bullet"):
		hit()
		area.queue_free() 

func ship_destroyed():
	self.hide()
	print("Destroyed!")
	set_physics_process(false)
	Global.player_ship_destroyed = true
	%Engine_2.stop()

func hit():
	health -= randi_range(1, 10)
	if health < 0:
		health = 0
	health_label.text = "Ship Health: " + str(health)
	if health <= 0:
		ship_destroyed()
	
	var bullet_sfx = randi_range(1, 4)
	if bullet_sfx == 1:
		%BulletStrike1.play()
	elif bullet_sfx == 2:
		%BulletStrike2.play()
	elif bullet_sfx == 3:
		%BulletStrike3.play()
	elif bullet_sfx == 4:
		%BulletStrike4.play()

func system_start():
	%OmniLight3D.light_color = Color(1.0, 0.945, 0.949, 1.0)
	%OmniLight3D2.show()
	%OmniLight3D3.show()
	%OmniLight3D4.show()
	%OmniLight3D5.show()
	%SpotLight3D.show()
	%SpotLight3D.show()
	%Computer_Boot.play()
	await get_tree().create_timer(5).timeout
	%RadarScreen.show()
	%Engine_1.play()
	await get_tree().create_timer(6.2).timeout
	Global.ship_on = true
	if not %Engine_2.playing:
		%Engine_2.play() 

func system_shutdown():
	%OmniLight3D.light_color = Color(1.0, 0.0, 0.0, 1.0)
	%Engine_2.stop()
	%Engine_3.play()
