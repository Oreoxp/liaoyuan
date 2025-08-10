# res://game/items/experience_gem.gd
extends Area2D
class_name ExperienceGem

# 导入Player类以确保类型检查正确
const Player = preload("res://game/player/player.gd")

@export var experience_value: float = 25.0

# 这两个变量将被"激活"函数赋值
var target_player: Player = null
var move_speed: float = 300.0 # 吸附时的飞行速度

func _ready() -> void:
	# 将自己添加到items组中，这样玩家就能检测到
	add_to_group("items")
	
	# 确保不在enemies组中
	if is_in_group("enemies"):
		remove_from_group("enemies")
		print("ExperienceGem: Removed from enemies group")
	
	# 强制设置Z-index和碰撞层，确保场景文件中的设置生效
	z_index = 5
	collision_layer = 4  # 确保碰撞层是4
	
	# 强制启用碰撞体
	$CollisionShape2D.disabled = false
	
	print("ExperienceGem: Ready at position ", global_position)
	print("ExperienceGem: Z-index: ", z_index)
	print("ExperienceGem: Collision layer: ", collision_layer)
	print("ExperienceGem: Collision mask: ", collision_mask)
	print("ExperienceGem: Is in items group: ", is_in_group("items"))
	print("ExperienceGem: Is in enemies group: ", is_in_group("enemies"))

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
	if distance_sq < 25: # 使用距离平方避免开方运算
		collect()

## --- 公共方法 --- ##

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
	PlayerData.add_experience(experience_value)
	queue_free()
