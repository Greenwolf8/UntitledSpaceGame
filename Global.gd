extends Node


@onready var player_ship_destroyed: bool = false
@onready var in_hangar: bool = false
@onready var hangar_open: bool = false
@onready var is_pilot: bool = false
@onready var is_wo: bool = false
@onready var in_ship: bool = false
@onready var ship = get_tree().get_first_node_in_group("player_ship") as RigidBody3D
@onready var player = get_tree().get_first_node_in_group("Player") as CharacterBody3D
@onready var ship_on: bool = false
@onready var in_ship_console: bool = false

var current_task: float = 0

func next_task():
	player = get_tree().get_first_node_in_group("Player") as CharacterBody3D
	player.rpc("next_task")

func system_start():
	player = get_tree().get_first_node_in_group("Player") as CharacterBody3D
	ship.system_start()
	if current_task == 2:
		next_task()

func open_hangar():
	pass

func close_hangar():
	pass
