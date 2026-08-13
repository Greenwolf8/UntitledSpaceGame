extends CanvasLayer

@onready var history_label: RichTextLabel = $VBoxContainer/RichTextLabel
@onready var command_input: LineEdit = $VBoxContainer/HBoxContainer/LineEdit
@onready var player: CharacterBody3D

const PROMPT: String = "C:/DOS>"

func _ready() -> void:
	history_label.text = " "
	visibility_changed.connect(_on_visibility_changed)
	print(player)

func _on_visibility_changed() -> void:
	if visible:
		command_input.grab_focus()

func _on_line_edit_text_submitted(new_text: String) -> void:
	var input_clean = new_text.strip_edges()
	if input_clean.is_empty():
		return
		
	history_label.append_text(PROMPT + input_clean + "\n")
	_process_command(input_clean)
	command_input.clear()

func _process_command(command: String) -> void:
	var parts = command.to_lower()
	
	match parts:
		"help":
			history_label.append_text("AVAILABLE COMMANDS:\n EXEC SYS_START\n BOOT /REACTOR\n BOOT /LIFE_SUPPORT\n BOOT /DEFENCE_SYS\n LEAVE\n")
		"exec sys_start":
			history_label.append_text("SYSTEM STARTING\n")
			Global.system_start()
		"leave":
			command_input.release_focus()
		
	await get_tree().process_frame
	var scrollbar = history_label.get_v_scroll_bar()
	scrollbar.value = scrollbar.max_value

func _on_line_edit_focus_exited() -> void:
	player = $"/root/Node3D/Ship/Ship/1"
	player.ship_console_interact()
