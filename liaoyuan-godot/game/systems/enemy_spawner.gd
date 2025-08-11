# enemy_spawner.gd

extends Node

# 添加一个标志来跟踪生成器是否正在使用
var is_in_use: bool = false

# 导入Player类以确保类型检查正确
const Player = preload("res://game/player/player.gd")
# 导入Enemy类以确保类型检查正确
const Enemy = preload("res://game/enemies/default_enemy/Enemy.tscn")
# 预加载ObjectPool类
const ObjectPool = preload("res://game/systems/object_pool.gd")

const ENEMY_SCENE = preload("res://game/enemies/default_enemy/Enemy.tscn")

# 暴露一个变量，可以在编辑器里调整生成半径
@export var spawn_radius: float = 600.0
# 生成间隔控制
@export var spawn_interval: float = 1.0
@export var max_enemies_on_screen: int = 50

var player: Player = null
@onready var spawn_timer = $SpawnTimer
@onready var enemy_pool: ObjectPool = get_node("/root/Main/EnemyPool")

func _ready() -> void:
	# 确保计时器已经连接到生成函数
	spawn_timer.timeout.connect(spawn_enemy)
	
	# 获取玩家引用
	player = get_node("/root/Main/Player")
	
	# 设置生成间隔
	spawn_timer.wait_time = spawn_interval
	
	# 启动计时器
	spawn_timer.start()

func spawn_enemy() -> void:
	# 如果player不存在，就什么也不做
	if not is_instance_valid(player):
		return

	# 1. 计算一个随机方向
	var random_angle = randf_range(0, TAU) # TAU = 2 * PI, 代表一个完整的圆
	var direction = Vector2.from_angle(random_angle)
	
	# 2. 计算生成位置 = 玩家位置 + 一个随机方向上的固定距离
	var spawn_position = player.global_position + direction * spawn_radius

	# 3. 从对象池中获取敌人
	if enemy_pool:
		var enemy = enemy_pool.acquire() as Enemy
		if enemy:
			enemy.reset_and_spawn(spawn_position, self.player, enemy_pool)
			print("EnemySpawner: Spawned enemy from pool at position ", spawn_position)
		else:
			print("EnemySpawner: Failed to acquire enemy from pool")
	else:
		print("EnemySpawner: Enemy pool not found")

# 对象池需要的可用性检查方法
func is_available() -> bool:
	return not is_in_use

# 设置使用状态的方法
func set_in_use(value: bool) -> void:
	is_in_use = value
	if value:
		# 开始使用时启动计时器
		if spawn_timer:
			spawn_timer.start()
	else:
		# 停止使用时停止计时器
		if spawn_timer:
			spawn_timer.stop()

# 重置状态方法（对象池调用）
func reset_state() -> void:
	is_in_use = false
	# 停止计时器
	if spawn_timer:
		spawn_timer.stop()
