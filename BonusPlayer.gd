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
	
	var current_vertical_velocity = velocity.project(ship_basis.y)
	var current_horizontal_velocity = velocity - velocity.project(ship_basis.y)
	
	if not down_cast.is_colliding():
		current_vertical_velocity = Vector3.ZERO
	else:
		current_vertical_velocity += gravity_dir * 11 * delta
	
	velocity = current_horizontal_velocity + current_vertical_velocity

	move_and_slide()
