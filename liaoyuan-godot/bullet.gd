extends Area2D
class_name Bullet

@export var SPEED: float = 500.0
var direction: Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	global_position += direction * SPEED * delta

# 当子弹的碰撞区域进入另一个 Area2D 时调用 (例如我们的敌人).
func _on_area_entered(area: Area2D) -> void:
	queue_free()

# 当子弹的碰撞区域进入一个 PhysicsBody2D (例如 CharacterBody2D, RigidBody2D) 时调用.
func _on_body_entered(body: Node) -> void:
	queue_free()
