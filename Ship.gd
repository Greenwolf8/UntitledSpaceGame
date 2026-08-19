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
@onready var pilot_camera: Camera3D = %PilotCamera
@onready var wo_camera: Camera3D = %WOCamera
@onready var throttle_label: Label = %Throttle
@onready var speed_label: Label = %Speed
@onready var health_label: Label = %HealthLabel	
@onready var player: CharacterBody3D = get_tree().get_first_node_in_group("Player")
@onready var bullet_container: Node3D = $"../../../PlayerBulletContainer"

var mouse_input: Vector2 = Vector2.ZERO
var health: int = 200
var Camerafree = false
var throttle: float = 0
var forward_move: float = 0.0



func _ready() -> void:
	health_label.text = "Health: " + str(health)
	shoot_colliding_label.text = str(Global.shoot_colliding)
	%Exterior.area_entered.connect(_on_area_entered)
	print("camera location: " + str(%Camera3D.position))
	print("camera rotation: " + str(%Camera3D.rotation))

func _unhandled_input(event: InputEvent) -> void:
	if Camerafree and event is InputEventMouseMotion:
		pilot_camera.rotation_degrees.y -= event.relative.x * 0.2
		pilot_camera.rotation_degrees.y = clamp(
			pilot_camera.rotation_degrees.y, 0,180
		)
		pilot_camera.rotation_degrees.x -= event.relative.y * 0.2
		pilot_camera.rotation_degrees.x = clamp(
		pilot_camera.rotation_degrees.x, -60, 75 
		)
	elif not Camerafree and event is InputEventMouseMotion:
		mouse_input += event.relative

func _physics_process(_delta):
	shoot_colliding_label.text = str(Global.shoot_colliding)
	if not Global.is_pilot: 
		return
	var forward_input = Input.get_axis("throttle_down", "throttle_up")
	var current_speed = snapped(linear_velocity.length(), 0.1)
	var yaw_input = Input
	var roll_input = Input.get_axis("move_right", "move_left")
	var pitch_input = Input.get_axis("move_back", "move_forward")
	var forward_force: Vector3 = Vector3.ZERO
	
	if %ShipShoot.is_colliding():
		Global.shoot_colliding = true
	else: 
		Global.shoot_colliding = false
	
	if not Camerafree:
		pitch_input += mouse_input.y * 0.1
		yaw_input = -mouse_input.x * 0.1
	else:
		yaw_input = 0
	
	if forward_input > 0 and forward_move < 1.985:
		forward_move += 0.015
	elif forward_input < 0 and forward_move > -1:
		forward_move -= 0.015
	else:
		pass
	
	if forward_move > 0:
		%Engine_2.volume_db = forward_move * 2
	else:
		%Engine_2.volume_db = -forward_move * 2

	if forward_move > 0.1 or forward_move < -0.1:
		forward_force = forward_move * -global_transform.basis.x * engine_power
	else:
		forward_force = Vector3.ZERO
	if Global.ship_on:
		apply_central_force(forward_force)
		apply_torque(transform.basis.z * pitch_input * pitch_torque)
		apply_torque(transform.basis.y * yaw_input * pitch_torque)
		apply_torque(transform.basis.x * roll_input * roll_torque)
		
		if not %Engine_2.playing:
			%Engine_2.play()
	
	mouse_input = Vector2.ZERO
	
	speed_label.text = "Speed: " + str(current_speed)
	throttle_label.text = "Throttle: " + str(int(ceil((forward_move * 50)))) + "%"
	
	if Global.is_pilot:
		if Input.is_action_pressed("fire"):
			request_shoot.rpc(fire_point.global_transform)
		
		if Input.is_action_just_pressed("fire"):
			%Gun1.play()
			just_shot.rpc()
		
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

@rpc("any_peer", "call_local", "reliable")
func just_shot() -> void:
	pre_fire_timer.start()
	await get_tree().create_timer(0.05).timeout
	fire_time.start()
	if pre_fire_timer.is_stopped():
		%Gun2.play()

@rpc("any_peer", "call_local", "reliable")
func request_shoot(muzzle_transform:  Transform3D) -> void:
	if not multiplayer.is_server():
		return
	print("1")
	if fire_timer.is_stopped() and pre_fire_timer.is_stopped() and fire_time.time_left > 0:
		print("firing... apparently")
		var bullet = bullet_scene.instantiate()
		bullet.global_transform = muzzle_transform
		%Gun2.play()
		fire_timer.start()
		bullet.rotate_object_local(Vector3.RIGHT, randf_range(-muzzle_spread, muzzle_spread))
		bullet.rotate_object_local(Vector3.UP, randf_range(-muzzle_spread, muzzle_spread))
		if bullet_container:
			bullet_container.add_child(bullet, true)

func enter_pilot():
	health_label.show()
	%Speed.visible = true
	player = get_tree().get_first_node_in_group("Player")
	Camerafree = false
	pilot_camera.current = true
	pilot_camera.rotation_degrees = Vector3(0, 90, 0)
	print("enter Pilot called!")

func leave_pilot():
	health_label.hide()
	%Speed.visible = false
	player = get_tree().get_first_node_in_group("Player")
	print("leave Pilot called!")

func enter_wo():
	health_label.show()
	%Speed.visible = true
	player = get_tree().get_first_node_in_group("Player")
	Camerafree = false
	wo_camera.current = true
	wo_camera.rotation_degrees = Vector3(0, 90, 0)
	print("enter WO called!")

func leave_wo():
	health_label.hide()
	%Speed.visible = false
	player = get_tree().get_first_node_in_group("Player")
	print("leave WO called!")

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
	rpc("sync_system_start")

@rpc(	"any_peer", "call_local", "reliable")
func sync_system_start():
	%OmniLight3D.light_color = Color("fff1f2ff")
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
