extends Node2D

const BULLET = preload("res://scenes/weapons/bouncy_bullet.tscn")

func _on_player_shoot():
	var bullet = BULLET.instantiate()
	bullet.position =
