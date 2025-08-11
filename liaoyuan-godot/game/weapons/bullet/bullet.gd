# res://game/weapons/bullet/bullet.gd
extends Area2D
class_name Bullet

# 预加载ObjectPool类
const ObjectPool = preload("res://game/systems/object_pool.gd")

@export var speed: float = 600.0

var direction: Vector2 = Vector2.ZERO
var damage: float = 50.0

# 增加一个变量来存储自己所属的池子
var my_pool: ObjectPool = null
# 记录发射位置，用于计算飞行距离
var start_position: Vector2 = Vector2.ZERO
# 最大飞行距离
var max_distance: float = 1000.0
# 防止重复伤害
var has_hit_target: bool = false

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	
	# 检查是否飞得太远
	var distance_traveled = global_position.distance_to(start_position)
	if distance_traveled > max_distance:
		hit_target()

# 这是新的"激活"函数，将由Player在申请到子弹后调用
func reset_and_shoot(start_position: Vector2, shoot_direction: Vector2, bullet_damage: float, owner_pool: ObjectPool):
	global_position = start_position
	self.start_position = start_position # 记录发射位置
	direction = shoot_direction
	damage = bullet_damage
	my_pool = owner_pool
	has_hit_target = false # 重置击中状态
	
func _on_body_entered(body: Node2D):
	# 防止重复伤害
	if has_hit_target:
		return
		
	# 处理与CharacterBody2D的碰撞
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		print("Bullet: Hit enemy body at position ", body.global_position)
		# 对敌人造成伤害
		body.take_damage(damage)
		# 击中目标后归还到对象池
		hit_target()
	elif body.is_in_group("items"):
		# 忽略与物品的碰撞
		pass
	else:
		# 与其他物体的碰撞，也归还到对象池
		print("Bullet: Hit something else (body), returning to pool")
		hit_target()
	
func hit_target():
	# 防止重复调用
	if has_hit_target:
		return
		
	has_hit_target = true
	# 当击中目标时，调用此方法来归还自己
	if my_pool:
		my_pool.release(self)
