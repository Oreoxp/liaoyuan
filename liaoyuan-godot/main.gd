extends Node2D

@onready var player_node: Player = $Player
@onready var enemy_node: Enemy = $Enemy

func _ready() -> void:
	enemy_node.player = player_node
