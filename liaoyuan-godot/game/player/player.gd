extends CharacterBody2D
class_name Player

const BASE_SPEED: float = 300.0
@export var FRICTION: float = 500.0
@export var current_weapon: Resource

# 导入ExperienceGem类以确保类型检查正确
const ExperienceGemClass = preload("res://game/items/experience_gem.gd")

@onready var attack_timer = $AttackTimer
@onready var pickup_area = $PickupArea
@onready var player_data = get_node("/root/PlayerData")

# 提前获取对象池的引用
@onready var bullet_pool = get_tree().get_root().find_child("BulletPool", true, false)

var can_attack: bool = true

func _ready() -> void:
	# 重置玩家数据，确保每次游戏开始时都是干净的状态
	player_data.reset()
	
	# 只在调试模式下打印，减少日志噪音
	if OS.is_debug_build():
		print("Player: PlayerData reset completed")
		print("Player: Initial level: ", player_data.level)
		print("Player: Initial exp: ", player_data.current_exp)
	
	# 将自己添加到player组中
	add_to_group("player")
	
	# 强制设置Z-index和碰撞层，确保场景文件中的设置生效
	z_index = 10
	collision_layer = 1 # 玩家碰撞层
	collision_mask = 28 # 检测敌人(3)、物品(4)、边界(16)
	pickup_area.collision_layer = 1
	pickup_area.collision_mask = 4 # 只检测碰撞层4的宝石
	
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	pickup_area.area_entered.connect(_on_pickup_area_entered)
	
	# 如果没有设置武器，创建一个默认武器
	if not current_weapon:
		current_weapon = preload("res://game/weapons/weapon_data.gd").new()
	
	# 只在调试模式下打印，减少日志噪音
	if OS.is_debug_build():
		print("Player: Ready at position ", global_position)
		print("Player: Can attack: ", can_attack)
		print("Player: Attack timer wait time: ", attack_timer.wait_time)
		print("Player: Z-index: ", z_index)
		print("Player: Pickup area collision layer: ", pickup_area.collision_layer)
		print("Player: Pickup area collision mask: ", pickup_area.collision_mask)
	
	# 延迟开始攻击，等待敌人生成
	await get_tree().create_timer(2.0).timeout

func _physics_process(delta: float) -> void:
	var direction: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction != Vector2.ZERO:
		velocity = direction * BASE_SPEED * player_data.move_speed_modifier
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	move_and_slide()

	# 攻击逻辑：检查是否可以攻击
	if can_attack:
		shoot()

func shoot() -> void:
	var enemy = find_nearest_enemy()
	if enemy:
		# 额外验证：确保这是一个真正的敌人
		if not enemy.has_method("take_damage"):
			if OS.is_debug_build():
				print("Player: Error: find_nearest_enemy returned non-enemy object: ", enemy.name, " of class: ", enemy.get_class())
			return
			
		# 只在调试模式下打印，减少日志噪音
		if OS.is_debug_build():
			print("Player: Shooting at enemy at position ", enemy.global_position)
		
		# 1. 从池中申请一个子弹
		var bullet = bullet_pool.acquire() as Bullet
		
		# 2. 如果成功申请到，就激活它
		if bullet:
			# 调用子弹的激活函数，传递所有必要信息
			var bullet_damage = current_weapon.current_damage * player_data.damage_modifier
			bullet.reset_and_shoot(
				global_position,
				(enemy.global_position - global_position).normalized(),
				bullet_damage,
				bullet_pool
			)
			
			# 只在调试模式下打印，减少日志噪音
			if OS.is_debug_build():
				print("Player: Bullet acquired and activated at position ", bullet.global_position)
				print("Player: Bullet direction: ", bullet.direction)
		else:
			if OS.is_debug_build():
				print("Player: Warning: Failed to acquire bullet from pool!")
		
		# 从武器数据获取冷却时间
		if current_weapon and current_weapon.has_method("get_current_cooldown"):
			var cooldown = current_weapon.get_current_cooldown()
			attack_timer.wait_time = cooldown
		elif current_weapon and current_weapon.has_method("get"):
			var cooldown = current_weapon.get("current_cooldown")
			if cooldown != null:
				attack_timer.wait_time = cooldown
		else:
			# 如果没有武器数据，使用默认冷却时间
			attack_timer.wait_time = 0.5
		
		# 只在调试模式下打印，减少日志噪音
		if OS.is_debug_build():
			print("Player: Attack cooldown set to ", attack_timer.wait_time, " seconds")
		
		# 启动攻击冷却
		can_attack = false
		attack_timer.start()
	else:
		# 只在调试模式下打印，减少日志噪音
		if OS.is_debug_build():
			print("Player: No enemy found to shoot at")

func _on_attack_timer_timeout() -> void:
	can_attack = true

# 缓存最近的敌人，避免每帧都搜索
var cached_nearest_enemy: Node2D = null
var last_enemy_search_time: float = 0.0
const ENEMY_SEARCH_INTERVAL: float = 0.5 # 每0.5秒搜索一次敌人，进一步减少频率

func find_nearest_enemy() -> Node2D:
	# 检查缓存是否有效
	if is_instance_valid(cached_nearest_enemy):
		# 验证缓存的敌人是否仍然有效
		if cached_nearest_enemy.has_method("take_damage") and cached_nearest_enemy.is_in_group("enemies"):
			return cached_nearest_enemy
	
	# 如果缓存无效或搜索间隔到了，重新搜索
	var current_time = Time.get_time_dict_from_system()["second"]
	if current_time - last_enemy_search_time < ENEMY_SEARCH_INTERVAL:
		return cached_nearest_enemy
	
	last_enemy_search_time = current_time
	
	# 只查找enemies组中的敌人，不包含items
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	var nearest_enemy: Node2D = null
	var min_dist_sq = INF # 使用距离的平方进行比较，可以避免开方运算，效率更高

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		
		# 额外检查：确保这是一个真正的敌人，而不是宝石
		if not enemy.has_method("take_damage"):
			if OS.is_debug_build():
				print("Player: Skipping non-enemy object: ", enemy.name, " of class: ", enemy.get_class())
			continue
			
		var dist_sq = self.global_position.distance_squared_to(enemy.global_position)
		if dist_sq < min_dist_sq:
			min_dist_sq = dist_sq
			nearest_enemy = enemy
	
	# 更新缓存
	cached_nearest_enemy = nearest_enemy
	
	if nearest_enemy and OS.is_debug_build():
		print("Player: Nearest enemy at distance ", sqrt(min_dist_sq))
	
	return nearest_enemy

func _on_pickup_area_entered(area: Area2D) -> void:
	# 检查进入我们拾取范围的是否是一颗"待机"的经验宝石
	if area is ExperienceGemClass:
		print("Player: Found ExperienceGem, activating magnet...")
		# 类型转换，并调用宝石的公共方法，命令它开始追踪我们
		var gem = area as ExperienceGemClass
		gem.activate_magnet(self)
	else:
		print("Player: Area is not an ExperienceGem, it's a: ", area.get_class())
