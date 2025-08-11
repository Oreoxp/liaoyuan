# enemy_v2.gd
# 基于PoolableObject接口的Enemy实现
# 展示如何正确实现对象池接口

extends CharacterBody2D
class_name EnemyV2

# 实现PoolableObject接口
func _get(property: StringName):
	if property == "is_in_use":
		return is_in_use
	elif property == "pool":
		return pool
	return null

func _set(property: StringName, value) -> bool:
	if property == "is_in_use":
		is_in_use = value
		return true
	elif property == "pool":
		pool = value
		return true
	return false

# 继承PoolableObject接口
const PoolableObject = preload("res://game/systems/poolable_object.gd")
const Player = preload("res://game/player/player.gd")
const ObjectPoolV2 = preload("res://game/systems/object_pool_v2.gd")

@export var SPEED: float = 150.0
@export var health: float = 100.0
@export var experience_value: float = 25.0

var player: Player = null
var is_dying: bool = false

# 对象池相关（继承自PoolableObject）
var is_in_use: bool = false
var pool: ObjectPoolV2 = null

@onready var hit_area = $HitArea
@onready var gem_pool: ObjectPoolV2 = get_node("/root/Main/GemPool")

func _ready() -> void:
	add_to_group("enemies")
	
	# 查找玩家
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	# 只有在激活状态下才执行逻辑
	if not is_in_use:
		return
		
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		return
		
	var direction: Vector2 = (player.global_position - global_position).normalized()
	velocity = direction * SPEED
	move_and_slide()

## PoolableObject接口实现

func reset_state() -> void:
	# 重置所有状态到初始值
	health = 100.0
	is_dying = false
	velocity = Vector2.ZERO
	player = null
	
	# 重新启用碰撞体
	if hit_area:
		hit_area.monitoring = true
		hit_area.monitorable = true

func activate() -> void:
	is_in_use = true
	# 激活时的特殊逻辑
	show() # 显示对象
	print("EnemyV2: 激活敌人")

func deactivate() -> void:
	is_in_use = false
	# 停用时的特殊逻辑
	hide() # 隐藏对象
	print("EnemyV2: 停用敌人")

func is_available() -> bool:
	return not is_in_use

func set_in_use(value: bool) -> void:
	is_in_use = value
	if value:
		activate()
	else:
		deactivate()

## 敌人特定方法

# 重置并激活敌人的方法
func reset_and_spawn(start_position: Vector2, target_player: Player, owner_pool: ObjectPoolV2):
	global_position = start_position
	player = target_player
	pool = owner_pool
	
	# 调用父类的激活方法
	activate()
	
	print("EnemyV2: 重置并生成在位置 ", start_position)

func take_damage(damage: float) -> void:
	if is_dying:
		return
		
	health -= damage
	print("EnemyV2: 受到伤害 ", damage, "，剩余生命值 ", health)
	
	if health <= 0:
		die()

func die() -> void:
	if is_dying:
		return
		
	is_dying = true
	print("EnemyV2: 敌人死亡")
	
	# 掉落经验宝石
	drop_experience_gem()
	
	# 归还到对象池
	if pool:
		pool.release(self)
	else:
		queue_free()

func drop_experience_gem() -> void:
	if not is_dying or not gem_pool:
		return
		
	var gem = gem_pool.acquire()
	if gem:
		gem.reset_and_drop(global_position, gem_pool, experience_value)
		print("EnemyV2: 掉落经验宝石，价值: ", experience_value)

func _on_hit_area_area_entered(area: Area2D) -> void:
	if area.get_parent() is Player:
		var player_node = area.get_parent() as Player
		player_node.take_damage(20.0)