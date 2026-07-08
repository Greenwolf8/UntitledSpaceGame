extends RigidBody3D

@export var engine_power = 100.0
@export var turn_torque = 30.0
@onready var camera_3d: Camera3D = %Camera3D
@onready var front_cast: RayCast3D = %FrontCast

var Cameralocked = true
var withPlayer = false


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
	apply_central_force(forward_force)
	
	var rotation_input = Input.get_axis("move_right", "move_left")
	apply_torque(transform.basis.x * rotation_input * turn_torque)
	
	var pitch_input = Input.get_axis("move_back", "move_forward")
	apply_torque(transform.basis.z * pitch_input * turn_torque)
	
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

		

func _enter_ship():
	withPlayer = true
	%OmniLight3D.light_color = Color(1,1,1)
	
	var player = get_tree().get_first_node_in_group("Player")
	player.enter_ship()

func _leave_ship():
	withPlayer = false
	%OmniLight3D.light_color = Color(1,.25,.25)
	
	var player = get_tree().get_first_node_in_group("Player")
	player.leave_ship()
