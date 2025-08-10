extends Node2D
class_name Arena

# 竞技场尺寸
var arena_width: int = 800
var arena_height: int = 600
var grid_size: int = 50  # 网格大小

# 敌人生成相关
const ENEMY_SCENE = preload("res://game/enemies/default_enemy/Enemy.tscn")
@export var max_enemies: int = 5
@export var enemy_spawn_interval: float = 3.0
var enemy_spawn_timer: Timer
var current_enemies: int = 0

func _ready() -> void:
	print("Arena: Ready, size: ", arena_width, "x", arena_height)
	print("Arena: Grid size: ", grid_size)
	print("Arena: Position: ", global_position)
	print("Arena: Global position: ", global_position)
	
	# 设置敌人生成定时器
	setup_enemy_spawning()
	
	# 强制重绘
	queue_redraw()
	# 延迟一帧后再次重绘，确保在场景完全加载后绘制
	await get_tree().process_frame
	queue_redraw()
	
	# 打印调试信息
	print("Arena: Arena global position: ", global_position)
	print("Arena: World boundaries: left=", global_position.x - 400, " right=", global_position.x + 400, " top=", global_position.y - 300, " bottom=", global_position.y + 300)

func _draw() -> void:
	print("Arena: _draw() called")
	# 绘制网格线
	draw_grid()
	# 绘制边界
	draw_boundaries()

func draw_grid() -> void:
	print("Arena: Drawing grid...")
	var lines_drawn = 0
	
	# 计算相对于Arena节点的位置
	var arena_center = Vector2.ZERO
	var left_edge = arena_center.x - float(arena_width)/2.0
	var right_edge = arena_center.x + float(arena_width)/2.0
	var top_edge = arena_center.y - float(arena_height)/2.0
	var bottom_edge = arena_center.y + float(arena_height)/2.0
	
	# 绘制垂直线
	for x in range(0, arena_width + 1, grid_size):
		var world_x = left_edge + x
		var start_pos = Vector2(world_x, top_edge)
		var end_pos = Vector2(world_x, bottom_edge)
		draw_line(start_pos, end_pos, Color.WHITE, 1.0)
		lines_drawn += 1
		print("Drawing vertical line at x=", world_x, " from ", start_pos, " to ", end_pos)
	
	# 绘制水平线
	for y in range(0, arena_height + 1, grid_size):
		var world_y = top_edge + y
		var start_pos = Vector2(left_edge, world_y)
		var end_pos = Vector2(right_edge, world_y)
		draw_line(start_pos, end_pos, Color.WHITE, 1.0)
		lines_drawn += 1
		print("Drawing horizontal line at y=", world_y, " from ", start_pos, " to ", end_pos)
	
	print("Arena: Total grid lines drawn: ", lines_drawn)

func draw_boundaries() -> void:
	print("Arena: Drawing boundaries...")
	# 计算相对于Arena节点的位置
	var arena_center = Vector2.ZERO
	var left_edge = arena_center.x - float(arena_width)/2.0
	var right_edge = arena_center.x + float(arena_width)/2.0
	var top_edge = arena_center.y - float(arena_height)/2.0
	var bottom_edge = arena_center.y + float(arena_height)/2.0
	
	# 绘制四条边界线
	var top_left = Vector2(left_edge, top_edge)
	var top_right = Vector2(right_edge, top_edge)
	var bottom_left = Vector2(left_edge, bottom_edge)
	var bottom_right = Vector2(right_edge, bottom_edge)
	
	draw_line(top_left, top_right, Color.WHITE, 3.0)
	draw_line(top_right, bottom_right, Color.WHITE, 3.0)
	draw_line(bottom_right, bottom_left, Color.WHITE, 3.0)
	draw_line(bottom_left, top_left, Color.WHITE, 3.0)
	
	print("Arena: Boundaries drawn from ", top_left, " to ", bottom_right)
	print("Arena: Arena global position: ", global_position)
	print("Arena: World boundaries: left=", global_position.x + left_edge, " right=", global_position.x + right_edge, " top=", global_position.y + top_edge, " bottom=", global_position.y + bottom_edge)

func setup_enemy_spawning() -> void:
	print("Arena: Setting up enemy spawning...")
	enemy_spawn_timer = Timer.new()
	enemy_spawn_timer.wait_time = enemy_spawn_interval
	enemy_spawn_timer.timeout.connect(_on_enemy_spawn_timer_timeout)
	add_child(enemy_spawn_timer)
	enemy_spawn_timer.start()
	
	print("Arena: Spawning initial enemies...")
	# 立即生成一些敌人
	for i in range(3):
		spawn_enemy()
		# 添加小延迟，避免敌人生成在同一位置
		await get_tree().create_timer(0.1).timeout

func _on_enemy_spawn_timer_timeout() -> void:
	if current_enemies < max_enemies:
		spawn_enemy()

func spawn_enemy() -> void:
	var enemy = ENEMY_SCENE.instantiate()
	add_child(enemy)
	
	# 确保敌人被添加到enemies组中
	enemy.add_to_group("enemies")
	
	# 在边界附近随机生成敌人，使用全局坐标
	var spawn_side = randi() % 4  # 0: 上, 1: 右, 2: 下, 3: 左
	var spawn_pos = Vector2.ZERO
	
	match spawn_side:
		0: # 上边
			spawn_pos = global_position + Vector2(randf_range(-350, 350), -250)
		1: # 右边
			spawn_pos = global_position + Vector2(350, randf_range(-250, 250))
		2: # 下边
			spawn_pos = global_position + Vector2(randf_range(-350, 350), 250)
		3: # 左边
			spawn_pos = global_position + Vector2(-350, randf_range(-250, 250))
	
	enemy.global_position = spawn_pos
	current_enemies += 1
	print("Arena: Spawned enemy at ", spawn_pos, " (global: ", enemy.global_position, "), total enemies: ", current_enemies)
	print("Arena: Enemy is in enemies group: ", enemy.is_in_group("enemies"))
	print("Arena: Enemy collision layer: ", enemy.collision_layer)
	
	# 连接敌人死亡信号
	enemy.tree_exiting.connect(_on_enemy_died)

func _on_enemy_died() -> void:
	current_enemies -= 1
	print("Arena: Enemy died, remaining enemies: ", current_enemies) 
