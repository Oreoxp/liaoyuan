extends Node2D

@onready var player_node: Player = $Player
@onready var enemy_node: Enemy = $Enemy
@onready var spawner = $EnemySpawner

func _ready() -> void:
	enemy_node.player = player_node
	spawner.player = player_node
