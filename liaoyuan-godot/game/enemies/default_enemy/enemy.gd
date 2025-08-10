extends CharacterBody2D
class_name Enemy

# 导入Player类以确保类型检查正确
const Player = preload("res://game/player/player.gd")

@export var SPEED: float = 150.0
@export var health: float = 100.0
@export var experience_value: float = 25.0  # 敌人死亡时掉落的经验值
var player: Player = null

@onready var hit_area = $HitArea

# 预加载经验宝石场景
const EXPERIENCE_GEM_SCENE = preload("res://game/items/experience_gem.tscn")

func _ready() -> void:
	print("Enemy: Ready at position ", global_position)
	add_to_group("enemies")
	
	# 查找玩家
	player = get_tree().get_first_node_in_group("player")
	if player:
		print("Enemy: Found player at ", player.global_position)
	else:
		print("Enemy: No player found!")

func _physics_process(delta: float) -> void:
	if player == null:
		# 重新查找玩家
		player = get_tree().get_first_node_in_group("player")
		return
	var direction: Vector2 = (player.global_position - global_position).normalized()
	velocity = direction * SPEED
	move_and_slide()

func take_damage(damage_amount: float) -> void:
	print("Enemy: Taking damage ", damage_amount, " at position ", global_position)
	health -= damage_amount
	print("Enemy: Health remaining: ", health)
	if health <= 0:
		print("Enemy: Dying at position ", global_position)
		# 使用call_deferred延迟执行，避免在销毁过程中改变状态
		call_deferred("drop_experience_gem")
		call_deferred("queue_free")

func drop_experience_gem() -> void:
	# 创建经验宝石
	var gem = EXPERIENCE_GEM_SCENE.instantiate()
	
	# 获取当前场景的根节点，确保宝石被正确添加
	var current_scene = get_tree().current_scene
	if current_scene:
		current_scene.add_child(gem)
	else:
		# 如果无法获取当前场景，添加到根节点
		get_tree().get_root().add_child(gem)
	
	gem.global_position = self.global_position
	gem.experience_value = experience_value
	
	# 确保宝石不在enemies组中
	if gem.is_in_group("enemies"):
		gem.remove_from_group("enemies")
		print("Enemy: Removed gem from enemies group")
	
	print("Enemy: Dropped experience gem at position ", gem.global_position)
	print("Enemy: Gem parent: ", gem.get_parent().name if gem.get_parent() else "No parent")
	print("Enemy: Gem is in items group: ", gem.is_in_group("items"))
	print("Enemy: Gem is in enemies group: ", gem.is_in_group("enemies"))	
