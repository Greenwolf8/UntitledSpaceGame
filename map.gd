extends Node3D

@onready var multiplayer_ui = $UI/Multiplayer
@onready var hangar = %Node3D
@onready var ship = get_tree().get_first_node_in_group("player_ship")

const AI_SHIP = preload("res://AI_Ship.tscn")
const PLAYER = preload("res://Player.tscn")
const THRESHOLD = 4000

var peer = WebSocketMultiplayerPeer.new()

func _ready() -> void:
	spawn_enemy("start")

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

func spawn_enemy(Position: String) -> void:
	await get_tree().create_timer(5).timeout
	var enemy = AI_SHIP.instantiate()
	get_tree().current_scene.add_child(enemy)
	if Position == "Random":
		enemy.global_position = Vector3(randf_range(-15000, -6000), randf_range(-1000, 5000), randf_range(-10000, 10000))
	elif Position == "start":
		enemy.global_position = Vector3(-10000, 3500, 4500)
		enemy.rotation = Vector3(0.0, 56.6, -90)
