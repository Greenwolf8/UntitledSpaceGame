extends Control

@onready var circle_radius: int = 100
@onready var line_width: int = 7
@onready var line_colour: Color = Color.GREEN
@onready var speed_label: Label = %SpeedLabel
@onready var distance_label: Label = %DistLabel
@onready var speed: int = 0
@onready var distance: float = 0

func _draw() -> void:
	var center_position = Vector2(size.x / 2, size.y / 2 + 100)
	draw_arc(center_position, circle_radius, 0, TAU, 100, line_colour, line_width, true)
	draw_circle(center_position, 15, line_colour)

func _process(delta: float) -> void:
	speed_label.text = str(speed) + " Km/h"
	var display_distance = round(distance)
	if distance <= 999:
		distance_label.text = str(display_distance) + " m"
	else:
		distance_label.text = str(snapped(display_distance / 1000, 0.1)) + " Km"
