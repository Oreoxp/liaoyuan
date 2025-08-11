extends CharacterBody2D
class_name Enemy

# 导入Player类以确保类型检查正确
const Player = preload("res://game/player/player.gd")
# 预加载ObjectPool类
const ObjectPool = preload("res://game/systems/object_pool.gd")

@export var SPEED: float = 150.0
@export var health: float = 100.0
@export var experience_value: float = 25.0 # 敌人死亡时掉落的经验值
var player: Player = null
# 防止重复死亡处理
var is_dying: bool = false

# 对象池相关
var my_pool: ObjectPool = null
var is_in_use: bool = false
var gem_pool: ObjectPool = null

@onready var hit_area = $HitArea

func _ready() -> void:
	# 只在调试模式下打印，减少日志噪音
	if OS.is_debug_build():
		print("Enemy: Ready at position ", global_position)
	add_to_group("enemies")
	
	# 查找玩家
	player = get_tree().get_first_node_in_group("player")
	if OS.is_debug_build() and player:
		print("Enemy: Found player at ", player.global_position)
	elif OS.is_debug_build() and not player:
		print("Enemy: No player found!")

# 缓存玩家查找时间，避免频繁查找
var last_player_search_time: float = 0.0
const PLAYER_SEARCH_INTERVAL: float = 2.0 # 每2秒查找一次玩家，进一步减少频率

func _physics_process(delta: float) -> void:
	if player == null:
		# 限制查找玩家的频率
		var current_time = Time.get_time_dict_from_system()["second"]
		if current_time - last_player_search_time >= PLAYER_SEARCH_INTERVAL:
			player = get_tree().get_first_node_in_group("player")
			last_player_search_time = current_time
		return
	
	var direction: Vector2 = (player.global_position - global_position).normalized()
	velocity = direction * SPEED
	move_and_slide()

# 重置并激活敌人的方法
func reset_and_spawn(start_position: Vector2, target_player: Player, owner_pool: ObjectPool):
	self.health = 100.0 # 重置生命值
	self.global_position = start_position
	self.player = target_player
	self.my_pool = owner_pool
	self.is_dying = false # 重置死亡状态
	self.is_in_use = true # 设置为使用中状态
	
	# 重置其他状态
	velocity = Vector2.ZERO
	
	# 重新启用碰撞体
	if hit_area:
		hit_area.set_deferred("monitoring", true)
		hit_area.set_deferred("monitorable", true)
	
	# 确保宝石池引用正确
	if gem_pool == null:
		gem_pool = get_node("/root/Main/GemPool")
	
	print("Enemy: Reset and spawned at position ", start_position)

func take_damage(damage_amount: float) -> void:
	# 防止重复死亡处理
	if is_dying:
		return
		
	health -= damage_amount
	if health <= 0:
		is_dying = true
		# 先掉落宝石，然后再释放到对象池
		drop_experience_gem()
		# 延迟释放到对象池，确保宝石生成完成
		call_deferred("release_to_pool")

func release_to_pool() -> void:
	# 归还到对象池而不是销毁
	if my_pool:
		my_pool.release(self)
	else:
		# 如果没有池，则销毁（备用方案）
		queue_free()

func drop_experience_gem() -> void:
	# 防止重复掉落宝石
	if not is_dying:
		print("Enemy: Not dying, skipping gem drop")
		return
		
	print("Enemy: Starting gem drop process at position ", global_position)
		
	# 如果还没有找到宝石池，现在查找
	if gem_pool == null:
		gem_pool = get_node("/root/Main/GemPool")
		print("Enemy: Found gem pool: ", gem_pool)
		
	# 从宝石池中获取一个宝石
	if gem_pool:
		print("Enemy: Attempting to acquire gem from pool")
		var gem = gem_pool.acquire() as ExperienceGem
		if gem:
			print("Enemy: Successfully acquired gem, resetting and dropping")
			gem.reset_and_drop(global_position, gem_pool, experience_value)
			print("Enemy: Dropped experience gem with value: ", experience_value, " at position ", gem.global_position)
		else:
			print("Enemy: Failed to acquire gem from pool - pool returned null")
	else:
		print("Enemy: Gem pool not found at /root/Main/GemPool")

# 对象池需要的可用性检查方法
func is_available() -> bool:
	return not is_in_use

# 设置使用状态的方法
func set_in_use(value: bool) -> void:
	is_in_use = value

# 重置状态方法（对象池调用）
func reset_state() -> void:
	is_in_use = false
	is_dying = false
	health = 100.0
	velocity = Vector2.ZERO
	player = null
	my_pool = null
	gem_pool = null # 重置宝石池引用
	
	# 使用延迟调用来重新启用碰撞体，避免在信号处理中修改
	if hit_area:
		hit_area.set_deferred("monitoring", true)
		hit_area.set_deferred("monitorable", true)
