extends CharacterBody3D
@onready var camera_3d2: Camera3D = %Camera3D2
@export var speed: float = 5.0
@export var camera: Camera3D
@onready var down_cast: RayCast3D = %RayCast3D

var leave_seat_location: Vector3 = Vector3(21,5,0)
var parent_node = get_parent()

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

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
	var parent = get_parent() as RigidBody3D
	if not parent:
		return
	
	var input_dir := Input.get_vector ("move_left","move_right","move_forward", "move_back")
	var cam_basis := camera_3d2.global_transform.basis
	var ship_basis : Basis = parent.global_transform.basis
	var forward := -cam_basis.z
	var right := cam_basis.x
	
	forward = (forward - forward.project(ship_basis.y)).normalized()
	right = (right - right.project(ship_basis.y)).normalized()
	
	var direction := Vector3.ZERO
	if input_dir != Vector2.ZERO:
		direction = (forward * -input_dir.y) + (right * input_dir.x)
	
	var gravity_dir = -ship_basis.y
	
	var current_horizontal_velocity = velocity - velocity.project(ship_basis.y)
	var current_vertical_velocity = velocity.project(ship_basis.y)
	
	if direction != Vector3.ZERO:
		current_horizontal_velocity = direction * speed
	else:
		current_horizontal_velocity = current_horizontal_velocity.move_toward(Vector3.ZERO, speed * delta * 10)
	if not down_cast.is_colliding():
		current_vertical_velocity = Vector3.ZERO
		if Input.is_action_just_pressed("jump"):
			current_vertical_velocity = ship_basis.y * 4.5
	else:
		current_vertical_velocity += gravity_dir * 11 * delta
	
	velocity = current_horizontal_velocity + current_vertical_velocity
	
	
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
