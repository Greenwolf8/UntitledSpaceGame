extends Node


@onready var player_ship_destroyed: bool = false
@onready var in_hangar: bool = false
@onready var hangar_open: bool = false
@onready var is_pilot: bool = false
@onready var is_wo: bool = false
@onready var in_ship: bool = false
@onready var ship: RigidBody3D = get_tree().get_first_node_in_group("player_ship")
@onready var map = get_tree().get_first_node_in_group("Map")
@onready var hangar = get_tree().get_first_node_in_group("Hangar Script")
@onready var player: CharacterBody3D
@onready var ship_on: bool = false
@onready var in_ship_console: bool = false
@onready var ai_attacking: bool = false
@onready var bullet_container: Node3D = $/root/Map/PlayerBulletContainer

var current_task: float = 0

func next_task():
	player = get_tree().get_first_node_in_group("Player") as CharacterBody3D
	player.next_task()

func system_start():
	player = get_tree().get_first_node_in_group("Player") as CharacterBody3D
	ship.system_start()
	if current_task == 2:
		next_task()
	hangar.open_hangar()

func enemy_destroyed():
	player.enemy_destroyed()
	map.spawn_enemy("Random")
