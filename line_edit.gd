extends LineEdit

func _on_text_changed(new_text: String) -> void:
	var current_caret = caret_column
	text = new_text.to_upper()
	caret_column = current_caret
