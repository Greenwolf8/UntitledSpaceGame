extends CharacterBody3D

@onready var camera : Camera3D = %PlayerCamera
@onready var front_cast : RayCast3D = %FrontCast
@onready var climbing_label : Label = %IsClimbing
@onready var player_ship = get_tree().get_first_node_in_group("player_ship")
@onready var chair = "Chair:<StaticBody3D#37094426288>"
@onready var hangar = get_tree().get_first_node_in_group("Hangar")
@onready var ship = get_tree().get_first_node_in_group("player_ship")

var climb_speed : float = 2.5
var walk : float = 5
var sprint : float = 10
var leave_seat_location: Vector3 = Vector3(21,5,0)
var mouse_locked : bool = true
var gravity : float = 11
var speed : float = walk
var current_ladder: Area3D = null
var is_climbing: bool = false
var hit_object = null
var in_console: bool = false
var old_position: Vector3
var old_rotation: Vector3

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	front_cast.add_exception(self)
	mouse_locked = false
	if Global.in_hangar == true:
		camera.current = true
	print(camera.global_position)
	print(camera.global_rotation)

func _unhandled_input(event: InputEvent) -> void:
	if not in_console:
		if not mouse_locked and event is not InputEventMouseMotion:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			await get_tree().create_timer(0.05).timeout
			mouse_locked = true
		
		if event.is_action_pressed("ui_cancel") and mouse_locked == true:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			await get_tree().create_timer(0.5).timeout
			mouse_locked = false
		elif event.is_action_pressed("interact"):
			interact_pressed()
		
		if event is InputEventMouseMotion:
			camera.rotation_degrees.y -= event.relative.x * 0.5
			camera.rotation_degrees.x -= event.relative.y * 0.5
			camera.rotation_degrees.x = clamp(
				camera.rotation_degrees.x, -80.0, 80.0
			)
	else:
		if event.is_action_pressed("interact"):
			console_interact()
	

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("sprint"):
		speed = sprint
	else:
		speed = walk

func _physics_process(delta: float) -> void:
	
	if not is_multiplayer_authority():
		return
	
	if not in_console:
		if front_cast.is_colliding():
			%"Press E".visible = true
			hit_object = front_cast.get_collider()
		else:
			%"Press E".visible = false
			hit_object = null
		
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
	else:
		pass

func console_interact():
	var screen_position: Vector3 = Vector3(8.3377744, 1.37692, -53.19952)
	var screen_rotation: Vector3 = Vector3(-1.186824, 3.1416, 0.0)
	var rot_diff: Vector3 = Vector3.ZERO
	var shortest_target : Vector3
	var tween = create_tween()
	
	if not in_console:
		old_rotation.x = wrapf(camera.global_rotation.x, -PI, PI)
		old_rotation.y = wrapf(camera.global_rotation.y, -PI, PI)
		old_position = camera.global_position
		
		rot_diff.x = wrapf(screen_rotation.x - camera.global_rotation.x, -PI, PI)
		rot_diff.y = wrapf(screen_rotation.y - camera.global_rotation.y, -PI, PI)
		shortest_target = camera.global_rotation + rot_diff
		tween.tween_property(camera, "global_position", screen_position, 0.25)
		tween.parallel().tween_property(camera, "global_rotation", shortest_target, 0.25)
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		open_hangar()
		in_console = true
	else:
		rot_diff.x = wrapf(old_rotation.x - camera.global_rotation.x, -PI, PI)
		rot_diff.y = wrapf(old_rotation.y - camera.global_rotation.y, -PI, PI)
		shortest_target = camera.global_rotation + rot_diff
		tween.tween_property(camera, "global_position", old_position, 0.5)
		tween.parallel().tween_property(camera, "global_rotation", shortest_target, 0.5)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		open_hangar()
		in_console = false 

func open_hangar():
	if Global.hangar_open:
		hangar.call_ship()
		ship.hide()
	else:
		hangar.call_ship()
		await get_tree().create_timer(41.6).timeout
		ship.show()

func interact_pressed():
	if Global.can_enter:
		if hit_object and hit_object.is_in_group("chair"):
			print(hit_object)
			camera.current = false
			player_ship._enter_ship()
			hide()
			_physics_process(false)
		elif hit_object and hit_object.is_in_group("Screen"):
			console_interact()
			print(hit_object)
			
	else:
			player_ship._leave_ship()

#func _enter_tree():
#	set_multiplayer_authority(int(str(name)))
