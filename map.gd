extends Node3D

@onready var multiplayer_ui = $UI/Multiplayer
@onready var hangar = %Node3D

const PLAYER = preload("res://Player.tscn")

var peer = WebSocketMultiplayerPeer.new()


func _on_join_pressed() -> void:
	var error = peer.create_client("wss://reexamine-swooned-sloping.ngrok-free.dev")
	if error == OK:
		multiplayer.multiplayer_peer = peer
		multiplayer_ui.hide()
		$UI.hide()
	else:
		print("Failed to connect: ", error)

func _on_host_pressed() -> void:
	var error = peer.create_server(80)
	if error == OK:
		multiplayer.multiplayer_peer = peer
		multiplayer.peer_connected.connect(add_player)
		multiplayer.peer_disconnected.connect(remove_player)
		add_player(1)
		$UI.hide()
		multiplayer_ui.hide()
	else:
		print("Failed to start server: ", error)

func add_player(id = 1):
	if not multiplayer.is_server():
		return
	var player = PLAYER.instantiate()
	player.name = str(id)
	hangar.add_child(player)
	player.global_position = Vector3(-1920, 2628.3, 0)

func exit_game(id):
	multiplayer.peer_disconnected.connect(remove_player)
	remove_player(id)

func remove_player(id):
	rpc("_remove_player", id)

@rpc("any_peer", "call_local")
func _remove_player(id):
	get_node(str(id)).queue_free()

func _on_single_player_pressed() -> void:
	$UI.hide()
	multiplayer_ui.hide()
	
	var player = PLAYER.instantiate()
	player.name = "1"
	hangar.add_child(player)
	player.global_position = Vector3(-1920, 2628.3, 0)
