extends CharacterBody3D
@onready var camera: Camera3D = %PlayerCamera
@onready var down_cast: RayCast3D = %RayCast3D
@onready var front_cast: RayCast3D = %FrontCast

const walk := 5
const sprint := 10
var leave_seat_location: Vector3 = Vector3(21,5,0)
var parent_node = get_parent()
var mouse_locked = true

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	front_cast.add_exception(self)
	mouse_locked = true
	camera.current = true

func _unhandled_input(event: InputEvent) -> void:
	if mouse_locked == false and event is not InputEventMouseMotion:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		await get_tree().create_timer(0.05).timeout
		mouse_locked = true
	
	elif event.is_action_pressed("ui_cancel") and mouse_locked == true:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		await get_tree().create_timer(0.5).timeout
		mouse_locked = false
	
	if event is InputEventMouseMotion:
		camera.rotation_degrees.y -= event.relative.x * 0.5
		camera.rotation_degrees.x -= event.relative.y * 0.5
		camera.rotation_degrees.x = clamp(
			camera.rotation_degrees.x, -80.0, 80.0
		)
	

func _physics_process(delta: float) -> void:
	var parent = get_parent() as RigidBody3D
	if not parent:
		return
	
	var input_dir := Input.get_vector ("move_left","move_right","move_forward", "move_back")
	var cam_basis := camera.global_transform.basis
	var ship_basis : Basis = parent.global_transform.basis
	var forward := -cam_basis.z
	var right := cam_basis.x
	var is_sprinting := Input.is_action_pressed("sprint")
	var current_speed := sprint if is_sprinting else walk
	
	
	if front_cast.is_colliding():
		%"Press E".visible = true
	else:
		%"Press E".visible = false
	
	forward = (forward - forward.project(ship_basis.y)).normalized()
	right = (right - right.project(ship_basis.y)).normalized()
	
	var direction := Vector3.ZERO
	if input_dir != Vector2.ZERO:
		direction = (forward * -input_dir.y) + (right * input_dir.x)
	
	
	var current_horizontal_velocity = velocity - velocity.project(ship_basis.y)
	var current_vertical_velocity = velocity.project(ship_basis.y)
	
	if direction != Vector3.ZERO:
		current_horizontal_velocity = direction * current_speed
	else:
		current_horizontal_velocity = current_horizontal_velocity.move_toward(Vector3.ZERO, current_speed * delta * 10)
	if down_cast.is_colliding():
		current_vertical_velocity = Vector3.ZERO
		if Input.is_action_just_pressed("jump"):
			current_vertical_velocity = ship_basis.y * 4.5
	else:
		current_vertical_velocity += -ship_basis.y * 11 * delta
	
	velocity = current_horizontal_velocity + current_vertical_velocity
	
	move_and_slide()

func enter_ship():
	set_physics_process(false)
	hide()
	camera.current = false
	
func leave_ship():
	position = leave_seat_location
	velocity = get_platform_velocity()
	set_physics_process(true)
	show()
	camera.current = true 
