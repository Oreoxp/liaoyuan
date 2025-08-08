extends CharacterBody2D
class_name Enemy

@export var SPEED: float = 150.0
var player: Player = null

func _ready() -> void:
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	if player == null:
		return
	var direction: Vector2 = (player.global_position - global_position).normalized()
	velocity = direction * SPEED
	move_and_slide()
