extends CharacterBody2D
class_name Player

const BULLET_SCENE = preload("res://Bullet.tscn")

@export var SPEED: float = 300.0
@export var FRICTION: float = 500.0

@onready var attack_timer = $AttackTimer
var can_attack: bool = true

func _ready() -> void:
	attack_timer.timeout.connect(_on_attack_timer_timeout)

func _physics_process(delta: float) -> void:
	var direction: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction != Vector2.ZERO:
		velocity = direction * SPEED
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	move_and_slide()

	# 攻击逻辑：检查是否可以攻击
	if can_attack:
		shoot()

func shoot() -> void:
	var enemy = find_nearest_enemy()
	if enemy:
		var bullet = BULLET_SCENE.instantiate()
		get_tree().get_root().add_child(bullet)
		bullet.global_position = self.global_position
		bullet.direction = (enemy.global_position - self.global_position).normalized()
		
		# 开始冷却
		can_attack = false
		attack_timer.start()

func _on_attack_timer_timeout() -> void:
	can_attack = true

func find_nearest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest_enemy: Node2D = null
	var min_dist_sq = INF # 使用距离的平方进行比较，可以避免开方运算，效率更高

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist_sq = self.global_position.distance_squared_to(enemy.global_position)
		if dist_sq < min_dist_sq:
			min_dist_sq = dist_sq
			nearest_enemy = enemy
	
	return nearest_enemy
