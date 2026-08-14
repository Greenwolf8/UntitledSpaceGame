extends CharacterBody3D

@onready var down_cast: RayCast3D = %RayCast3D
@onready var camera : Camera3D = %PlayerCamera
@onready var front_cast : RayCast3D = %FrontCast
@onready var climbing_label : Label = %IsClimbing
@onready var chair = "Chair:<StaticBody3D#37094426288>"
@onready var hangar = get_tree().get_first_node_in_group("Hangar")
@onready var ship = get_tree().get_first_node_in_group("player_ship")
@onready var ship_node = $"../Ship" # I know this is weird but the show() function needs it when calling ship. the "ship" variable does not work
@onready var gear_ladder : CollisionShape3D = $"../Ship/Ship/Gear Ladder/GearLadder"
@onready var interior_ladder: CollisionShape3D = $"../Ship/Ship/Interior Ladder/Inside"
@onready var ship_console_camera: Camera3D = $"../Ship/Ship/Camera3D"

var climb_speed : float = 2.5
var walk : float = 5
var sprint : float = 10
var leave_seat_location: Vector3 = Vector3(21,3.38,57.475)
var mouse_locked : bool = true
var gravity : float = 11
var is_sprinting: bool = false
var speed : float = walk
var current_ladder: Area3D = null
var hit_object = null
var in_console: bool = false
var old_position: Vector3
var old_rotation: Vector3
var screen_position: Vector3
var screen_rotation: Vector3 
var rot_diff: Vector3 = Vector3.ZERO
var shortest_target : Vector3
var on_gear_ladder: bool = false
var on_interior_ladder: bool = false

func _ready() -> void:
	reparent(hangar, true)
	if name.is_valid_int():
		set_multiplayer_authority(name.to_int())
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	front_cast.add_exception(self)
	mouse_locked = false
	camera.current = is_multiplayer_authority()
	print("Player spawned! Exact node path: ", get_path())

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return
		
	if not in_console and not Global.in_ship_console:
		if not mouse_locked and event is not InputEventMouseMotion:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			await get_tree().create_timer(0.05).timeout
			mouse_locked = true
		
		if event.is_action_pressed("ui_cancel"):
			if mouse_locked == true:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
				await get_tree().create_timer(0.5).timeout
				mouse_locked = false
		elif event.is_action_pressed("interact"):
			interact_pressed()
		elif event.is_action_pressed("P"):
			print(position)
			print(global_position)
		
		if event is InputEventMouseMotion:
			camera.rotation_degrees.y -= event.relative.x * 0.5
			camera.rotation_degrees.x -= event.relative.y * 0.5
			camera.rotation_degrees.x = clamp(
			camera.rotation_degrees.x, -80.0, 80.0
			)
	else:
		if event.is_action_pressed("interact"):
			hangar_console_interact()

func _physics_process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
	
	if not in_console or not Global.in_ship_console:
		if front_cast.is_colliding():
			%PressE.show()
			hit_object = front_cast.get_collider()
		else:
			%PressE.hide()
			hit_object = null
		
		if Input.is_action_pressed("sprint"):
			speed = sprint
		else:
			speed = walk
		
		if on_gear_ladder or on_interior_ladder: #Movement on a ladder
			var ship_velocity = ship.linear_velocity
			var climb_input = Input.get_axis("move_back", "move_forward") 
			
			if on_gear_ladder: #Movement on landing gear ladder
				var local_ladder_dir: Vector3 = Vector3(0.4663, 1.0, 0.0).normalized()
				var world_climb_dir : Vector3 = ship.global_transform.basis * local_ladder_dir * climb_input
				
				if position.y < -5.82 and climb_input < 0:
					climb_gear_ladder()
					reparent(get_tree().current_scene, true)
					Global.in_ship = false
				elif position.y > 0 and climb_input > 0:
					climb_gear_ladder()
					Global.in_ship = true
				else:
					velocity = ship_velocity + (world_climb_dir * climb_speed)
			
			elif on_interior_ladder: #Movement on the interior ladder
				var world_climb_dir : Vector3 = ship.global_transform.basis.y * climb_input
				
				if position.y < 0 and climb_input < 0:
					climb_interior_ladder()
				elif position.y > 3.5 and climb_input > 0:
					climb_interior_ladder()
				else:
					velocity = ship_velocity + (world_climb_dir * climb_speed)
			move_and_slide()
		
		elif Global.in_ship: #Movement on ship 
			var input_dir := Input.get_vector ("move_left","move_right","move_forward", "move_back")
			var cam_basis := camera.global_transform.basis
			var ship_basis : Basis = ship.global_transform.basis
			var forward := -cam_basis.z
			var right := cam_basis.x
			@warning_ignore("shadowed_variable")
			
			forward = (forward - forward.project(ship_basis.y)).normalized()
			right = (right - right.project(ship_basis.y)).normalized()
			
			var direction := Vector3.ZERO
			if input_dir != Vector2.ZERO:
				direction = (forward * -input_dir.y) + (right * input_dir.x)
			
			
			var current_horizontal_velocity = velocity - velocity.project(ship_basis.y)
			var current_vertical_velocity = velocity.project(ship_basis.y)
			
			if direction != Vector3.ZERO:
				current_horizontal_velocity = direction * speed
			else:
				current_horizontal_velocity = current_horizontal_velocity.move_toward(Vector3.ZERO, speed * delta * 10)
			if down_cast.is_colliding():
				current_vertical_velocity = Vector3.ZERO
				if Input.is_action_just_pressed("jump"):
					current_vertical_velocity = ship_basis.y * 4.5
			else:
				current_vertical_velocity += -ship_basis.y * 11 * delta
			
			velocity = current_horizontal_velocity + current_vertical_velocity
			
			move_and_slide()
		
		else: #Movement on ground
			var input_dir := Input.get_vector("move_left", "move_right", "move_back", "move_forward")
			var direction := Vector3.ZERO
			
			if not is_on_floor():
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
				velocity.x = direction.x * speed
				velocity.z = direction.z * speed
			else:
				velocity.x = move_toward(velocity.x, 0, speed)
				velocity.z = move_toward(velocity.z, 0, speed)
			if not in_console:
				move_and_slide()

func hangar_console_interact():
	screen_position = Vector3(8.3377744, 1.37692, -53.19952)
	screen_rotation = Vector3(-1.186824, 3.1416, 0.0)
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
		rpc("sync_open_hangar")
		in_console = true
	else:
		rot_diff.x = wrapf(old_rotation.x - camera.global_rotation.x, -PI, PI)
		rot_diff.y = wrapf(old_rotation.y - camera.global_rotation.y, -PI, PI)
		shortest_target = camera.global_rotation + rot_diff
		tween.tween_property(camera, "global_position", old_position, 0.5)
		tween.parallel().tween_property(camera, "global_rotation", shortest_target, 0.5)
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		await get_tree().create_timer(0.5).timeout
		in_console = false 

func ship_console_interact():
	screen_position = Vector3(0.554, 3, -57)
	screen_rotation = Vector3(0.7854, -1.5708, 57)
	var tween = create_tween()
	print("console interact called")
	
	if not Global.in_ship_console:
		old_rotation.x = wrapf(camera.rotation.x, -PI, PI)
		old_rotation.y = wrapf(camera.rotation.y, -PI, PI)
		old_position = camera.position
		
		rot_diff.x = wrapf(screen_rotation.x - camera.rotation.x, -PI, PI)
		rot_diff.y = wrapf(screen_rotation.y - camera.rotation.y, -PI, PI)
		shortest_target = camera.rotation + rot_diff
		tween.tween_property(camera, "position", screen_position, 0.25)
		tween.parallel().tween_property(camera, "rotation", shortest_target, 0.25)
		$Control.show()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		Global.in_ship_console = true
		set_physics_process(false)
	else:
		print("console leave called")
		rot_diff.x = wrapf(old_rotation.x - camera.global_rotation.x, -PI, PI)
		rot_diff.y = wrapf(old_rotation.y - camera.global_rotation.y, -PI, PI)
		shortest_target = camera.global_rotation + rot_diff
		tween.tween_property(camera, "position", old_position, 0.5)
		tween.parallel().tween_property(camera, "rotation", shortest_target, 0.5)
		$Control.hide()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		Global.in_ship_console = false 
		set_physics_process(true)

func enter_ship():
	set_physics_process(false)
	hide()
	%PressE.hide()
	ship.enter_ship()
	camera.current = false
	Global.can_enter = false

func leave_ship():
	position = leave_seat_location
	velocity = get_platform_velocity()
	set_physics_process(true)
	show()
	ship.leave_ship()
	camera.current = true 
	Global.can_enter = true

@rpc("any_peer", "call_local", "reliable")
func sync_open_hangar():
	if Global.hangar_open:
		hangar.call_ship()
		ship.hide()
	else:
		hangar.call_ship()
		await get_tree().create_timer(41.6667).timeout
		ship_node.show()

func interact_pressed():
	if Global.can_enter:
		if hit_object and hit_object.is_in_group("chair"):
			camera.current = false
			enter_ship()
			hide()
			_physics_process(false)
		elif hit_object and hit_object.is_in_group("Hangar_Screen"):
			hangar_console_interact()
			_physics_process(false)
		elif (hit_object and hit_object.is_in_group("Ship_Console")) or Global.in_ship_console:
			ship_console_interact()
			set_physics_process(false)
			Global.in_ship_console = true
		elif hit_object and hit_object.is_in_group("Ladder Gear"):
			print("gear climb called")
			climb_gear_ladder()
		elif hit_object and hit_object.is_in_group("Ladder Interior"):
			print("interior climb called")
			climb_interior_ladder()
		elif on_gear_ladder:
			climb_gear_ladder()
	else:
		leave_ship()

func _enter_tree():
	set_multiplayer_authority(name.to_int())

func climb_gear_ladder():
	var ladder_local = Vector3(20,-5.5,57.475)
	if not on_gear_ladder:
		var tween = create_tween()
		reparent(ship, true)
		tween.tween_property(self, "position", ladder_local, 0.25)
		on_gear_ladder = true
		%CollisionShape3D2.disabled = true
	else:
		on_gear_ladder = false
		%CollisionShape3D2.disabled = false

func climb_interior_ladder():
	var ladder_local = Vector3(23,0,59.416)
	if not on_interior_ladder:
		var tween = create_tween()
		tween.tween_property(self, "position", ladder_local, 0.25)
		on_interior_ladder = true
	else:
		on_interior_ladder = false
