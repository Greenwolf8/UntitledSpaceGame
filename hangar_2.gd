extends Node3D

#func _ready() -> void:
	#%AvroVulcan.hide()


func call_ship():
	if Global.hangar_open == false:
		%AnimationPlayer.play("Global/ElevatorAction_2")
		%"Avro Vulcan".show()
		await get_tree().create_timer(41.6667).timeout
		%"Avro Vulcan".hide()
		Global.hangar_open = true

	elif Global.hangar_open == true:
		%"Avro Vulcan".show()
		%AnimationPlayer.play_backwards("Global/ElevatorAction_2")
		Global.hangar_open = false
