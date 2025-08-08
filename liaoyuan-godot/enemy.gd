extends Area2D
class_name Enemy

@export var SPEED: float = 150.0
var player: Player = null

func _physics_process(delta: float) -> void:
	if player == null:
		return
	var direction: Vector2 = (player.global_position - global_position).normalized()
	global_position += direction * SPEED * delta
