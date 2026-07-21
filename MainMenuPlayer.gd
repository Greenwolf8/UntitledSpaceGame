extends CharacterBody3D
class_name Player

@onready var camera : Camera3D = %PlayerCamera
@onready var front_cast : RayCast3D = %FrontCast
@onready var animation_player : AnimationPlayer = %AnimationPlayer
@onready var climbing_label : Label = %IsClimbing

var climb_speed : float = 2.5
var walk : float = 5
var sprint : float = 10
var leave_seat_location: Vector3 = Vector3(21,5,0)
var mouse_locked : bool = true
var gravity : float = 11
var speed : float = walk
var current_ladder: Area3D = null
var is_climbing: bool = false

func _ready() -> void:
	Global.in_hangar = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	front_cast.add_exception(self)
	mouse_locked = true
	#%AvroVulcan.hide()
	%"Avro Vulcan".hide()
	if Global.in_hangar == true:
		camera.current = true

func _unhandled_input(event: InputEvent) -> void:
	if mouse_locked == false and event is not InputEventMouseMotion:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		await get_tree().create_timer(0.05).timeout
		mouse_locked = true
	
	if event.is_action_pressed("ui_cancel") and mouse_locked == true:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		await get_tree().create_timer(0.5).timeout
		mouse_locked = false
	elif event.is_action_pressed("fire"):
		open_hangar()
	
	if event is InputEventMouseMotion:
		camera.rotation_degrees.y -= event.relative.x * 0.5
		camera.rotation_degrees.x -= event.relative.y * 0.5
		camera.rotation_degrees.x = clamp(
			camera.rotation_degrees.x, -80.0, 80.0
		)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("sprint"):
		speed = sprint
	else:
		speed = walk

func _physics_process(delta: float) -> void:
	if front_cast.is_colliding():
		%"Press E".visible = true
	else:
		%"Press E".visible = false
	
	if Global.on_ladder == true:
		is_climbing = true
	else:
		is_climbing = false
	
	climbing_label.text = "is_climbing = " + str(is_climbing)
	
	var input_dir := Input.get_vector("move_left", "move_right", "move_back", "move_forward")
	var direction := Vector3.ZERO
	
	if is_climbing:
		velocity.y = input_dir.y * climb_speed
		velocity.x = input_dir.y * walk
		velocity.z = input_dir.x * walk
	else:
		if not is_on_floor() and not is_climbing:
			velocity.y -= gravity * delta
		if Input.is_action_just_pressed("jump") and is_on_floor():
			velocity.y = 4.5
	
		if input_dir != Vector2.ZERO:
			var cam_forward := -camera.global_transform.basis.z
			var cam_right := camera.global_transform.basis.x
			
			cam_forward.y = 0
			cam_right.y = 0
			cam_forward = cam_forward.normalized()
			cam_right = cam_right.normalized()
			
			direction = (cam_right * input_dir.x + cam_forward * input_dir.y).normalized()
	
		if direction:
			velocity.x = direction.x * walk
			velocity.z = direction.z * walk
		else:
			velocity.x = move_toward(velocity.x, 0, walk)
			velocity.z = move_toward(velocity.z, 0, walk)
	
	move_and_slide()

func open_hangar():
	animation_player.play("All")
	%"Avro Vulcan".show()
	await get_tree().create_timer(25).timeout
	%AvroVulcan.show()
	get_parent().get_node("Node3D/Avro Vulcan").visible = false
