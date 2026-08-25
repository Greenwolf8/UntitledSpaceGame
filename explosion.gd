extends Node3D

@onready var flash: GPUParticles3D = %Flash
@onready var fireball: GPUParticles3D = %Debris
@onready var smoke: GPUParticles3D = %Smoke
@onready var animation_player: AnimationPlayer = %AnimationPlayer
@onready var explosionSFX: AudioStreamPlayer3D = %Explosion
@onready var bulletstrike1: AudioStreamPlayer3D = %BulletStrike1
@onready var bulletstrike2: AudioStreamPlayer3D = %BulletStrike2
@onready var bulletstrike3: AudioStreamPlayer3D = %BulletStrike3
@onready var bulletstrike4: AudioStreamPlayer3D = %BulletStrike4

func Boom():
	flash.restart()
	fireball.restart()
	smoke.restart()
	explosionSFX.play()
	animation_player.play("Flash")
	await get_tree().create_timer(1).timeout
	bulletstrike1.play()
	await get_tree().create_timer(0.05).timeout
	bulletstrike3.play()
	await get_tree().create_timer(0.05).timeout
	bulletstrike4.play()
	await get_tree().create_timer(0.05).timeout
	bulletstrike1.play()
	await get_tree().create_timer(0.05).timeout
	bulletstrike2.play()
	await get_tree().create_timer(0.05).timeout
	bulletstrike4.play()
	await get_tree().create_timer(2.5).timeout
	queue_free()
