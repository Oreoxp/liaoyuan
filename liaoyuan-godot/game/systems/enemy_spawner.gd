# enemy_spawner.gd

extends Node

# 导入Player类以确保类型检查正确
const Player = preload("res://game/player/player.gd")
# 导入Enemy类以确保类型检查正确
const Enemy = preload("res://game/enemies/default_enemy/Enemy.tscn")

const ENEMY_SCENE = preload("res://game/enemies/default_enemy/Enemy.tscn")

# 暴露一个变量，可以在编辑器里调整生成半径
@export var spawn_radius: float = 600.0

var player: Player = null
@onready var spawn_timer = $SpawnTimer

func _ready() -> void:
	# 确保计时器已经连接到生成函数
	spawn_timer.timeout.connect(spawn_enemy)

func spawn_enemy() -> void:
	# 如果player不存在，就什么也不做
	if not is_instance_valid(player):
		return

	# 1. 计算一个随机方向
	var random_angle = randf_range(0, TAU) # TAU = 2 * PI, 代表一个完整的圆
	var direction = Vector2.from_angle(random_angle)
	
	# 2. 计算生成位置 = 玩家位置 + 一个随机方向上的固定距离
	var spawn_position = player.global_position + direction * spawn_radius

	# 3. 实例化并配置敌人
	var enemy = ENEMY_SCENE.instantiate() as Enemy
	if not is_instance_valid(enemy):
		return
		
	# 添加到主场景的根节点，而不是生成器的子节点
	get_tree().get_root().add_child(enemy)
	
	# 设置位置和追踪目标
	enemy.global_position = spawn_position
	enemy.player = self.player