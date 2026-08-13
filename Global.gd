extends Node


@onready var player_ship_destroyed: bool = false
@onready var shoot_colliding: bool = false
@onready var in_hangar: bool = false
@onready var hangar_open: bool = false
@onready var can_enter: bool = true
@onready var in_ship: bool = false
@onready var ship = get_tree().get_first_node_in_group("player_ship") as RigidBody3D
@onready var ship_on: bool = false
@onready var in_ship_console: bool = false

func system_start():
	ship.system_start()

func open_hangar():
	pass

func close_hangar():
	pass
