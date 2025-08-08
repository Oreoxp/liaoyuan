extends CharacterBody2D
class_name Player

const BULLET_SCENE = preload("res://Bullet.tscn")

@export var SPEED: float = 300.0
@export var FRICTION: float = 500.0

func _physics_process(delta: float) -> void:
	var direction: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if direction != Vector2.ZERO:
		velocity = direction * SPEED
	else:
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	move_and_slide()

	# 自动攻击
	var enemy = find_nearest_enemy()
	if enemy:
		var bullet = BULLET_SCENE.instantiate()
		bullet.global_position = self.global_position
		bullet.direction = (enemy.global_position - self.global_position).normalized()
		get_tree().get_root().add_child(bullet)
		queue_free() # 测试代码：发射后自毁

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
