extends CharacterBody2D
class_name Player

const BULLET_SCENE = preload("res://game/weapons/bullet/Bullet.tscn")
const BASE_SPEED: float = 300.0
@export var FRICTION: float = 500.0
@export var current_weapon: Resource

# 导入ExperienceGem类以确保类型检查正确
const ExperienceGemClass = preload("res://game/items/experience_gem.gd")

@onready var attack_timer = $AttackTimer
@onready var pickup_area = $PickupArea
@onready var player_data = get_node("/root/PlayerData")
var can_attack: bool = true

func _ready() -> void:
	# 将自己添加到player组中
	add_to_group("player")
	
	# 强制设置Z-index和碰撞层，确保场景文件中的设置生效
	z_index = 10
	collision_layer = 1  # 玩家碰撞层
	collision_mask = 28  # 检测敌人(3)、物品(4)、边界(16)
	pickup_area.collision_layer = 1
	pickup_area.collision_mask = 4  # 只检测碰撞层4的宝石
	
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	pickup_area.area_entered.connect(_on_pickup_area_entered)
	
	# 如果没有设置武器，创建一个默认武器
	if not current_weapon:
		current_weapon = preload("res://game/weapons/weapon_data.gd").new()
	
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
			print("Player: Error: find_nearest_enemy returned non-enemy object: ", enemy.name, " of class: ", enemy.get_class())
			return
			
		print("Player: Shooting at enemy at position ", enemy.global_position)
		var bullet = BULLET_SCENE.instantiate()
		get_tree().get_root().add_child(bullet)
		bullet.global_position = self.global_position
		bullet.direction = (enemy.global_position - self.global_position).normalized()
		
		print("Player: Bullet created at position ", bullet.global_position)
		print("Player: Bullet direction: ", bullet.direction)
		
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
		
		print("Player: Attack cooldown set to ", attack_timer.wait_time, " seconds")
		
		# 开始冷却
		can_attack = false
		attack_timer.start()
	else:
		# 只在调试模式下打印，减少日志噪音
		if OS.is_debug_build():
			print("Player: No enemy found to shoot at")

func _on_attack_timer_timeout() -> void:
	can_attack = true

func find_nearest_enemy() -> Node2D:
	# 只查找enemies组中的敌人，不包含items
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	print("Player: Found ", enemies.size(), " enemies")
	
	# 打印所有敌人的位置和详细信息
	for i in range(enemies.size()):
		var enemy = enemies[i]
		if is_instance_valid(enemy):
			print("Player: Enemy ", i, " at position ", enemy.global_position)
			print("Player: Enemy ", i, " class: ", enemy.get_class())
			print("Player: Enemy ", i, " is in enemies group: ", enemy.is_in_group("enemies"))
			print("Player: Enemy ", i, " is in items group: ", enemy.is_in_group("items"))
			print("Player: Enemy ", i, " has method 'take_damage': ", enemy.has_method("take_damage"))
		else:
			print("Player: Enemy ", i, " is invalid")
	
	var nearest_enemy: Node2D = null
	var min_dist_sq = INF # 使用距离的平方进行比较，可以避免开方运算，效率更高

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		
		# 额外检查：确保这是一个真正的敌人，而不是宝石
		if not enemy.has_method("take_damage"):
			print("Player: Skipping non-enemy object: ", enemy.name, " of class: ", enemy.get_class())
			continue
			
		var dist_sq = self.global_position.distance_squared_to(enemy.global_position)
		if dist_sq < min_dist_sq:
			min_dist_sq = dist_sq
			nearest_enemy = enemy
	
	if nearest_enemy and OS.is_debug_build():
		print("Player: Nearest enemy at distance ", sqrt(min_dist_sq))
	
	return nearest_enemy

func _on_pickup_area_entered(area: Area2D) -> void:
	print("Player: Pickup area entered by: ", area.name, " of type: ", area.get_class())
	print("Player: Area collision layer: ", area.collision_layer, " mask: ", area.collision_mask)
	print("Player: Area is in items group: ", area.is_in_group("items"))
	
	# 检查进入我们拾取范围的是否是一颗"待机"的经验宝石
	if area is ExperienceGemClass:
		print("Player: Found ExperienceGem, activating magnet...")
		# 类型转换，并调用宝石的公共方法，命令它开始追踪我们
		var gem = area as ExperienceGemClass
		gem.activate_magnet(self)
	else:
		print("Player: Area is not an ExperienceGem, it's a: ", area.get_class())
