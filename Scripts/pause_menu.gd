extends Control

@onready var resume_button: Button = %resume
@onready var quit_button: Button = %Quit
@onready var main_menu_button: Button = %"Main Menu"
@onready var fade = $fade_transition
@onready var fade_transition = $fade_transition/AnimationPlayer
@onready var fade_timer: Timer = $fade_transition/fade_timer

var button_type = null

func _ready() -> void:
	resume_button.pivot_offset = resume_button.size /2
	main_menu_button.pivot_offset = main_menu_button.size /2
	quit_button.pivot_offset = quit_button.size /2

func hovering(button: Button):
	var tween = create_tween()
	
	tween.tween_property(button, "scale", Vector2.ONE * 1.25, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func stopped_hovering(button: Button):
	var tween = create_tween()
	
	tween.tween_property(button, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_fade_timer_timeout() -> void:
	if button_type == "main_menu":
		get_tree().change_scene_to_file("uid://1sl6oqalns15")

func _on_resume_mouse_entered() -> void:
	hovering(resume_button)

func _on_resume_mouse_exited() -> void:
	stopped_hovering(resume_button)

func _on_resume_pressed() -> void:
	Global.is_paused = false
	get_tree().set_pause(false)
	queue_free()

func _on_main_menu_pressed() -> void:
	button_type = "main_menu"
	fade.show()
	fade_timer.start()
	fade_transition.play("fade_in")

func _on_main_menu_mouse_entered() -> void:
	hovering(main_menu_button)

func _on_main_menu_mouse_exited() -> void:
	stopped_hovering(main_menu_button)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_quit_mouse_entered() -> void:
	hovering(quit_button)

func _on_quit_mouse_exited() -> void:
	stopped_hovering(quit_button)
