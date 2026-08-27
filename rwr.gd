extends Control

@onready var rwr_radius: float = 242

var threats_to_draw: Array = []

func update_threats(threats: Array) -> void:
	threats_to_draw = threats
	queue_redraw()

func _draw() -> void:
	var center = size / 2
	
	for threat in threats_to_draw:
		var distance_multiplier = threat.get("distance", 1)
		var blip_distance = rwr_radius * distance_multiplier
		
		var x = center.x + sin(threat["angle"]) * blip_distance
		var y = center.y - cos(threat["angle"]) * blip_distance
		
		var blip_colour = Color.RED if threat["locking"] else Color.GREEN
		draw_circle(Vector2(x,y), 15, blip_colour)
		draw_string(ThemeDB.fallback_font, Vector2(x + 20, y - 25), threat["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 75, blip_colour)
