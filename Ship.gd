extends RigidBody3D

@export var engine_power = 130
@export var turn_torque = 4.5
@export var bullet_scene : PackedScene = preload("res://Bullet.tscn")
@onready var fire_point = %Hardpoint_1/Cannon/Cannon/MuzzleExit
@onready var fire_timer = %Hardpoint_1/Cannon/Cannon/Fire_timer
@onready var camera_3d: Camera3D = %Camera3D
@onready var front_cast: RayCast3D = %FrontCast
@onready var speed_label: Label = %Speed
@onready var health_label: Label = %HealthLabel

var health: int = 100
var Cameralocked = true
var withPlayer = false

func _ready() -> void:
	health_label.text = "Health: " + str(health)
	%Exterior.area_entered.connect(_on_area_entered)

func _unhandled_input(event: InputEvent) -> void:
	if not Cameralocked and event is InputEventMouseMotion:
		%Camera3D.rotation_degrees.y -= event.relative.x * 0.2
		%Camera3D.rotation_degrees.y = clamp(
			%Camera3D.rotation_degrees.y, 0,180
		)
		%Camera3D.rotation_degrees.x -= event.relative.y * 0.2
		%Camera3D.rotation_degrees.x = clamp(
		%Camera3D.rotation_degrees.x, -60, 75
		)

func _physics_process(_delta):
	if not withPlayer: return	
	var forward_input = Input.get_axis("throttle_down", "throttle_up")
	var forward_force = -global_transform.basis.x * forward_input * engine_power
	var current_speed = snapped(linear_velocity.length(), 0.1)
	
	apply_central_force(forward_force)
	
	var rotation_input = Input.get_axis("move_right", "move_left")
	apply_torque(transform.basis.x * rotation_input * turn_torque)
	
	var pitch_input = Input.get_axis("move_back", "move_forward")
	apply_torque(transform.basis.z * pitch_input * turn_torque)
	
	speed_label.text = "Speed: " + str(current_speed)
	
	if Input.is_action_pressed("fire") and withPlayer:
		shoot()
	
func interact_pressed():
	var canEnter = not withPlayer
	var hit_object = front_cast.get_collider()
	if canEnter:
		if hit_object == %Chair:
			_enter_ship()
	else:
		_leave_ship()

func _input(_event: InputEvent) -> void:
	var cantlock = Cameralocked
	
	if Input.is_action_just_pressed("interact"):
		interact_pressed()
	elif Input.is_action_pressed("camera_lock") and cantlock:
		Cameralocked = false
	elif Input.is_action_just_released("camera_lock"):
		Cameralocked = true		
		%Camera3D.rotation_degrees.x = 0
		%Camera3D.rotation_degrees.y = 90

func shoot():
	if fire_timer.is_stopped():
		fire_timer.start()
		var bullet = bullet_scene.instantiate()
		get_tree().root.add_child(bullet)
		bullet.global_transform = fire_point.global_transform
	
	
func _enter_ship():
	health_label.show()
	withPlayer = true
	%OmniLight3D.light_color = Color(1.0, 0.945, 0.949, 1.0)
	%"Press E".visible = false
	%Speed.visible = true
	var player = get_tree().get_first_node_in_group("Player")
	player.enter_ship()

func _leave_ship():
	health_label.hide()
	withPlayer = false
	%OmniLight3D.light_color = Color(1.0, 0.0, 0.0, 1.0)
	%Speed.visible = false
	var player = get_tree().get_first_node_in_group("Player")
	player.leave_ship()

func _on_area_entered(area: Area3D) -> void:
	if area.is_in_group("enemy_bullet"):
		hit()
		area.queue_free() 

func hit():
	health -= 10
	if health < 0:
		health = 0
	health_label.text = "Ship Health: " + str(health)
	if health <= 0:
		self.hide()
		print("Destroyed!")
		set_physics_process(false)
