extends Node3D

@onready var multiplayer_ui = $UI/Multiplayer
@onready var screen_left_mesh: MeshInstance3D = $ScreenLeft
@onready var screen_viewport: SubViewport = $ScreenViewport

const PLAYER = preload("res://Player.tscn")
var peer = ENetMultiplayerPeer.new()

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var viewport_texture = screen_viewport.get_texture()
	var mat = screen_left_mesh.material_override as StandardMaterial3D
	Global.in_hangar = true
	print(get_tree().get_nodes_in_group("Player"))

	if mat:
		mat.albedo_texture = viewport_texture

func _on_join_pressed() -> void:
	peer.create_client("localhost", 25565)
	multiplayer.multiplayer_peer = peer
	multiplayer_ui.hide()
	$UI.hide()


func _on_host_pressed() -> void:
	peer.create_server(25565)
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(add_player)
	add_player()
	$UI.hide()
	
	multiplayer.peer_disconnected.connect(remove_player)
	multiplayer_ui.hide()

func add_player(id = 1):
	if not multiplayer.is_server():
		return
	var player = PLAYER.instantiate()
	player.name = str(id)
	add_child(player)

func exit_game(id):
	multiplayer.peer_disconnected.connect(remove_player)
	remove_player(id)
	

func remove_player(id):
	rpc("_remove_player", id)

@rpc("any_peer", "call_local")
func _remove_player(id):
	get_node(str(id)).queue_free()
