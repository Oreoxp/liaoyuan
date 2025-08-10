extends Area2D
class_name Bullet

@export var SPEED: float = 500.0
var direction: Vector2 = Vector2.ZERO
var can_move: bool = false

# 信号已经在场景文件中连接，不需要在这里重复连接

func _ready() -> void:
	# 等待一帧再开始移动，确保位置设置正确
	await get_tree().process_frame
	can_move = true

func _physics_process(delta: float) -> void:
	if can_move:
		global_position += direction * SPEED * delta

# 当子弹的碰撞区域进入另一个 Area2D 时调用 (例如敌人的HitArea).
func _on_area_entered(area: Area2D) -> void:
	print("Bullet: Hit area ", area.name, " at position ", area.global_position)
	
	# 检查是否是敌人的HitArea
	if area.name == "HitArea" and area.get_parent() and area.get_parent().has_method("take_damage"):
		print("Bullet: Damaging enemy at position ", area.get_parent().global_position)
		area.get_parent().take_damage(50.0)
	
	queue_free()

# 当子弹的碰撞区域进入一个 PhysicsBody2D (例如 CharacterBody2D, RigidBody2D) 时调用.
func _on_body_entered(body: Node) -> void:
	print("Bullet: Hit body ", body.name, " at position ", body.global_position)
	
	# 检查是否是敌人
	if body.has_method("take_damage"):
		print("Bullet: Damaging enemy body at position ", body.global_position)
		body.take_damage(50.0)
	
	queue_free()
