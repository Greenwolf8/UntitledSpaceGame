extends CharacterBody3D
@onready var camera_3d2: Camera3D = %Camera3D2
@export var speed: float = 5.0
@export var camera: Camera3D

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
	var input_dir := Input.get_vector ("move_left","move_right","move_forward", "move_back")
	var local_dir := (transform.basis.x * input_dir.x + transform.basis.z * input_dir.y).normalized()
	var gravity_dir = -parent.basis.y.normalized()
	var direction:= Vector3.ZERO
	
	if camera and input_dir != Vector2.ZERO:
		var cam_basis := camera.global_transform.basis
		var forward := -cam_basis.z
		var right := cam_basis.x
		
		forward.y = 0
		forward = forward.normalized()
		right.y = 0
		right = right.normalized()
		
		direction = (forward * -input_dir.y) + (right * input_dir.x)
		
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed

	if is_on_floor():
		velocity.y = 0
	elif not is_on_floor():
		velocity += gravity_dir * 11 * delta
		
	if local_dir:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
		
	if Input.is_action_pressed("jump") and is_on_floor():
			velocity.y = 4.5

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
	
