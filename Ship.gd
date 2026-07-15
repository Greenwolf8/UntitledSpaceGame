extends RigidBody3D

@export var engine_power = 250
@export var roll_torque = 1200
@export var pitch_torque = 1000
@export var bullet_scene : PackedScene = preload("res://Bullet.tscn")
@export var muzzle_spread: float = 0.1
@onready var fire_point = %Hardpoint_1/Cannon/Cannon/MuzzleExit
@onready var fire_timer = %Hardpoint_1/Cannon/Cannon/FireTimer
@onready var pre_fire_timer = %Hardpoint_1/Cannon/Cannon/PreFireTimer
@onready var fire_time = %Hardpoint_1/Cannon/Cannon/FireTime
@onready var camera_3d: Camera3D = %Camera3D
@onready var front_cast: RayCast3D = %FrontCast
@onready var speed_label: Label = %Speed
@onready var health_label: Label = %HealthLabel	
@onready var radar_mesh: MeshInstance3D = $RadarScreen
@onready var radar_viewport: SubViewport = $RadarMesh

var mouse_input: Vector2 = Vector2.ZERO
var health: int = 200
var Camerafree = false
var withPlayer = false


func _ready() -> void:
	var viewport_texture = radar_viewport.get_texture()
	var mat = radar_mesh.material_override as StandardMaterial3D
	health_label.text = "Health: " + str(health)
	%Exterior.area_entered.connect(_on_area_entered)
	
	if mat:
		mat.albedo_texture = viewport_texture

func _unhandled_input(event: InputEvent) -> void:
	if Camerafree and event is InputEventMouseMotion:
		%Camera3D.rotation_degrees.y -= event.relative.x * 0.2
		%Camera3D.rotation_degrees.y = clamp(
			%Camera3D.rotation_degrees.y, 0,180
		)
		%Camera3D.rotation_degrees.x -= event.relative.y * 0.2
		%Camera3D.rotation_degrees.x = clamp(
		%Camera3D.rotation_degrees.x, -60, 75 
		)
	elif not Camerafree and event is InputEventMouseMotion:
		mouse_input += event.relative

func _physics_process(_delta):
	if not withPlayer: 
		return
	var forward_input = Input.get_axis("throttle_down", "throttle_up")
	var forward_force = -global_transform.basis.x * forward_input * engine_power
	var current_speed = snapped(linear_velocity.length(), 0.1)
	var yaw_input = Input
	var roll_input = Input.get_axis("move_right", "move_left")
	var pitch_input = Input.get_axis("move_back", "move_forward")
	
	if forward_input != 0:
		%Engine_2.volume_db = 5.0
	else:
		%Engine_2.volume_db = 0.0
	
	if not Camerafree:
		pitch_input += mouse_input.y * 0.1
		yaw_input = -mouse_input.x * 0.1
	else:
		yaw_input = 0
	
	if %StartupTimer.is_stopped():
		apply_central_force(forward_force)
		apply_torque(transform.basis.z * pitch_input * pitch_torque)
		apply_torque(transform.basis.y * yaw_input * pitch_torque)
		apply_torque(transform.basis.x * roll_input * roll_torque)
	
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

func interact_pressed():
	var canEnter = not withPlayer
	var hit_object = front_cast.get_collider()
	
	if canEnter:
		if hit_object == %Chair:
			_enter_ship()
		else:
			pass
	else:
		_leave_ship()

func _input(_event: InputEvent) -> void:
	var cantlock = Camerafree
	
	if Input.is_action_just_pressed("interact"):
		interact_pressed()
	elif Input.is_action_just_pressed("camera_lock") and not cantlock:
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

func _enter_ship():
	health_label.show()
	withPlayer = true
	%OmniLight3D.light_color = Color(1.0, 0.945, 0.949, 1.0)
	%"Press E".visible = false
	%Speed.visible = true
	var player = get_tree().get_first_node_in_group("Player")
	player.enter_ship()
	%Engine_1.play()
	%StartupTimer.start()
	await get_tree().create_timer(6.2).timeout
	%Engine_2.play()
	

func _leave_ship():
	health_label.hide()
	withPlayer = false
	%OmniLight3D.light_color = Color(1.0, 0.0, 0.0, 1.0)
	%Speed.visible = false
	var player = get_tree().get_first_node_in_group("Player")
	player.leave_ship()
	%Engine_2.stop()
	%Engine_3.play()

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
	health -= randi_range(2, 15)
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
