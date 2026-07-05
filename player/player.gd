extends CharacterBody3D

@export var ship: RigidBody3D
@export var speed: float = 5.5
@export var jump_velocity: float = 10.0
@export var gravity_strength: float = 25.0
@onready var camera_3d2: Camera3D = %Camera3D2

var _last_ship_transform: Transform3D
var leave_seat_location: Vector3 = Vector3(21,5,0)

func _ready() -> void:
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if ship:
		_last_ship_transform = ship.global_transform

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		%Camera3D2.rotation_degrees.y -= event.relative.x * 0.5
		%Camera3D2.rotation_degrees.x -= event.relative.y * 0.5
		%Camera3D2.rotation_degrees.x = clamp(
			%Camera3D2.rotation_degrees.x, -80.0, 80.0
		)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _physics_process(delta: float) -> void:
	if not ship:
		_run_standard_movement(delta)
		return
	
	var ship_movement = ship.global_transform * _last_ship_transform.inverse()
	
	global_transform = ship_movement * global_transform
	
	var ship_rotation = Basis(ship_movement.basis.get_rotation_quaternion())
	velocity = ship_rotation * velocity

	var input_direction_2D = Input.get_vector(
		"move_left", "move_right", "move_forward", "move_back"
		)
	var input_direction_3D = Vector3(
		input_direction_2D.x, 0.0, input_direction_2D.y)
	
	var target_dir = transform.basis * input_direction_3D

	var ship_up = ship.global_transform.basis.y.normalized()
	up_direction = ship_up

	if not is_on_floor():
		velocity -= ship_up * (gravity_strength * delta)
	else:
		var vertical_speed = velocity.dot(ship_up)
		if vertical_speed < 0:
			velocity -= ship_up * vertical_speed
			
		if Input.is_action_just_pressed("jump"):
			velocity += ship_up * jump_velocity

	var current_vertical = velocity.dot(ship_up) * ship_up
	var current_horizontal = target_dir * speed
	
	velocity = current_horizontal + current_vertical

	move_and_slide()
	_last_ship_transform = ship.global_transform


func _run_standard_movement(delta: float) -> void:
	up_direction = Vector3.UP
	var input_direction_2D = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = transform.basis * Vector3(input_direction_2D.x, 0.0, input_direction_2D.y)
	
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed
	velocity.y -= gravity_strength * delta
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		
	move_and_slide()
func enter_ship():
	set_physics_process(false)
	hide()
	camera_3d2.current = false
	
func leave_ship():
	position = leave_seat_location
	velocity = get_platform_velocity()
	set_physics_process(true)
	show()
	camera_3d2.current = true 
	
