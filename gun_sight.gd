extends Control

@onready var circle_radius: int = 100
@onready var line_width: int = 5
@onready var line_colour: Color = Color.GREEN

func _draw() -> void:
	var center_position = size / 2
	draw_arc(center_position, circle_radius, 0, TAU, 100, line_colour, line_width, true)
	draw_circle(center_position, 20, line_colour)
