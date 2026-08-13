extends Area3D

signal button_pressed

func _ready():
	# Explicitly tell Godot this object can be clicked by mouse rays
	input_ray_pickable = true

# This built-in Godot function triggers automatically when clicked
func _input_event(_camera: Camera3D, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int):
	# Check if the player left-clicked the 3D shape
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_on_button_clicked()

func _on_button_clicked():
	print("3D Button Clicked!")
	emit_signal("button_pressed")
	# Add visual/audio feedback here (e.g., move the mesh down slightly, play a click sound)
