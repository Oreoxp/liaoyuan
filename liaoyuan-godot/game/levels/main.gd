extends Node2D

# 导入Player类以确保类型检查正确
const Player = preload("res://game/player/player.gd")

@onready var player_node: Player = $Player
@onready var enemy_node: Enemy = $Enemy
@onready var spawner = $EnemySpawner

func _ready() -> void:
	enemy_node.player = player_node
	spawner.player = player_node
