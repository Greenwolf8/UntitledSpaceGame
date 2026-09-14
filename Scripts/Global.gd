extends Node


@onready var player_ship_destroyed: bool = false
@onready var in_hangar: bool = false
@onready var hangar_open: bool = false
@onready var is_pilot: bool = false
@onready var is_wo: bool = false
@onready var in_ship: bool = false
@onready var ship: RigidBody3D = null
@onready var map = null
@onready var hangar = null
@onready var player: CharacterBody3D = null
@onready var ship_on: bool = false
@onready var in_ship_console: bool = false
@onready var ai_attacking: bool = false
@onready var bullet_container: Node3D = null
@onready var player_type = null
@onready var is_paused: bool = false

var current_task: float = 0

func game_start():
	player = get_tree().get_first_node_in_group("Player")
	ship = get_tree().get_first_node_in_group("player_ship")
	player = get_tree().get_first_node_in_group("Player")
	map = get_tree().get_first_node_in_group("Map")
	hangar = get_tree().get_first_node_in_group("Hangar Script")
	bullet_container = $/root/Map/PlayerBulletContainer

func next_task():
	player.next_task()

func system_start():
	ship.system_start()
	if current_task == 2:
		next_task()
	hangar.open_hangar()

func enemy_destroyed():
	player.enemy_destroyed()
	map.spawn_enemy("random")

func game_reset():
	player_ship_destroyed = false
	in_hangar = false
	hangar_open = false
	is_pilot = false
	is_wo = false
	in_ship = false
	ship = null
	map = null
	hangar = null
	player = null
	ship_on = false
	in_ship_console = false
	ai_attacking = false
	bullet_container = null
	player_type = null
	is_paused = false
	current_task = 0
