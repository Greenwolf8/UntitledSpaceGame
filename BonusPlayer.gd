extends CharacterBody3D
@onready var down_cast: RayCast3D = %BPRayCast3D

var parent_node = get_parent()

func _ready() -> void:
	down_cast.add_exception(self)
	return
	
func _physics_process(delta: float) -> void:
	var parent = get_parent() as RigidBody3D
	if not parent:
		return
	
	var ship_basis : Basis = parent.global_transform.basis
	var gravity_dir = -ship_basis.y
	var _current_vertical_velocity = velocity.project(ship_basis.y)
	
	if not down_cast.is_colliding():
		_current_vertical_velocity = Vector3.ZERO
		if Input.is_action_just_pressed("jump"):
			_current_vertical_velocity = ship_basis.y * 4.5
	else:
		_current_vertical_velocity += gravity_dir * 11 * delta
	
	move_and_slide()
