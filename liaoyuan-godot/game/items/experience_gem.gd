# res://game/items/experience_gem.gd
extends Area2D
class_name ExperienceGem

# 导入Player类以确保类型检查正确
const Player = preload("res://game/player/player.gd")
# 预加载ObjectPool类
const ObjectPool = preload("res://game/systems/object_pool.gd")

@export var experience_value: float = 25.0

# 这两个变量将被"激活"函数赋值
var target_player: Player = null
var move_speed: float = 300.0 # 吸附时的飞行速度
var is_collected: bool = false # 防止重复收集

# 对象池相关
var my_pool: ObjectPool = null
var is_in_use: bool = false

func _ready() -> void:
	# 将自己添加到items组中，这样玩家就能检测到
	add_to_group("items")
	
	# 确保不在enemies组中
	if is_in_group("enemies"):
		remove_from_group("enemies")
		print("ExperienceGem: Removed from enemies group")
	
	# 强制设置Z-index和碰撞层，确保场景文件中的设置生效
	z_index = 5
	collision_layer = 4 # 确保碰撞层是4
	
	# 强制启用碰撞体
	$CollisionShape2D.disabled = false
	
	# 初始化完成

# _physics_process只在被激活后才做有效的工作
func _physics_process(delta: float) -> void:
	# 检查目标是否依然有效，这是一个好习惯
	if not is_instance_valid(target_player):
		return
		
	# 使用move_toward，这是一个更平滑和安全的移动方法
	var old_pos = global_position
	global_position = global_position.move_toward(target_player.global_position, move_speed * delta)
	
	# 如果距离足够近，就被收集
	var distance_sq = global_position.distance_squared_to(target_player.global_position)
	if distance_sq < 25 and not is_collected: # 使用距离平方避免开方运算
		collect()

## --- 公共方法 --- ##

# 重置并激活宝石的方法
func reset_and_drop(start_position: Vector2, owner_pool: ObjectPool, gem_value: float = 25.0):
	print("ExperienceGem: Starting reset_and_drop at position ", start_position)
	
	self.global_position = start_position
	self.target_player = null # 重置追踪目标
	self.my_pool = owner_pool
	self.experience_value = gem_value
	self.is_collected = false # 重置收集状态
	
	# 重新启用碰撞体
	if $CollisionShape2D:
		$CollisionShape2D.disabled = false
		print("ExperienceGem: Collision shape enabled")
	else:
		print("ExperienceGem: Warning - CollisionShape2D not found!")
	
	# 确保宝石可见
	if self is CanvasItem:
		self.show()
		print("ExperienceGem: Made visible")
	else:
		print("ExperienceGem: Warning - not a CanvasItem, cannot call show()")
	
	print("ExperienceGem: Reset and dropped at position ", start_position, " with value ", gem_value)

# 这是该宝石的"激活"开关，将由Player的拾取区域来调用
func activate_magnet(player_node: Player):
	# 如果已经被激活，就不要重复执行
	if target_player:
		return

	target_player = player_node
	# 使用call_deferred延迟执行，避免在物理查询刷新过程中改变监控状态
	call_deferred("_disable_collision")

# 延迟禁用碰撞体的辅助方法
func _disable_collision():
	# 技巧：暂时禁用宝石自己的碰撞体，防止在飞行过程中触发不必要的碰撞信号
	$CollisionShape2D.disabled = true

# 被收集时执行的最终逻辑
func collect():
	if is_collected:
		print("ExperienceGem: Already collected, ignoring duplicate collection")
		return # 防止重复收集
	
	is_collected = true
	print("ExperienceGem: Collecting experience value: ", experience_value)
	PlayerData.add_experience(experience_value)
	
	# 归还到对象池而不是销毁
	if my_pool:
		my_pool.release(self)
	else:
		# 如果没有池，则销毁（备用方案）
		queue_free()

# 对象池需要的可用性检查方法
func is_available() -> bool:
	return not is_in_use

# 设置使用状态的方法
func set_in_use(value: bool) -> void:
	is_in_use = value

# 重置状态方法（对象池调用）
func reset_state() -> void:
	is_in_use = false
	is_collected = false
	target_player = null
	# 重新启用碰撞体
	if $CollisionShape2D:
		$CollisionShape2D.disabled = false
