extends Node3D

func call_ship():
	if Global.hangar_open == false:
		%AnimationPlayer.play("Global/ElevatorAction_2")
		%"Avro Vulcan_001".show()
		await get_tree().create_timer(41.6667).timeout
		%"Avro Vulcan_001".hide()
		Global.hangar_open = true

	elif Global.hangar_open == true:
		%"Avro Vulcan_001".show()
		%AnimationPlayer.play_backwards("Global/ElevatorAction_2")
		Global.hangar_open = false
