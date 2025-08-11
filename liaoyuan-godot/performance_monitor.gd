# performance_monitor.gd
# 实时性能监控脚本

extends Node

var frame_count: int = 0
var last_time: float = 0.0
var fps: float = 0.0
var frame_times: Array[float] = []
const MAX_FRAME_TIMES = 60

# 性能监控设置
@export var output_interval: float = 2.0 # 输出间隔（秒）
@export var enable_detailed_output: bool = false # 是否启用详细输出
@export var enable_object_pool_check: bool = true # 是否检查对象池

func _ready():
	# 设置处理优先级，确保在其他脚本之前执行
	set_process_priority(100)
	if enable_detailed_output:
		print("性能监控器已启动")

func _process(delta: float):
	frame_count += 1
	
	# 计算FPS
	var current_time = Time.get_time_dict_from_system()["second"]
	if current_time - last_time >= output_interval:
		fps = frame_count / output_interval
		frame_count = 0
		last_time = current_time
		
		# 只在启用详细输出时输出性能信息
		if enable_detailed_output:
			output_performance_info()
		else:
			# 简化输出，只在性能问题时输出
			check_performance_warnings()
	
	# 记录帧时间
	frame_times.append(delta)
	if frame_times.size() > MAX_FRAME_TIMES:
		frame_times.pop_front()

func check_performance_warnings():
	if frame_times.size() == 0:
		return
		
	var avg_frame_time = 0.0
	for time in frame_times:
		avg_frame_time += time
	avg_frame_time /= frame_times.size()
	
	# 只在性能问题时输出警告
	if fps < 30.0 or avg_frame_time > 0.033:
		output_performance_info()

func output_performance_info():
	if frame_times.size() == 0:
		return
		
	var avg_frame_time = 0.0
	for time in frame_times:
		avg_frame_time += time
	avg_frame_time /= frame_times.size()
	
	var max_frame_time = 0.0
	for time in frame_times:
		if time > max_frame_time:
			max_frame_time = time
	
	print("=== 性能监控 ===")
	print("FPS: ", fps)
	print("平均帧时间: ", avg_frame_time * 1000, " ms")
	print("最大帧时间: ", max_frame_time * 1000, " ms")
	
	# 统计场景中的对象数量
	var enemy_count = get_tree().get_nodes_in_group("enemies").size()
	var bullet_count = get_tree().get_nodes_in_group("bullets").size()
	var item_count = get_tree().get_nodes_in_group("items").size()
	
	print("敌人数量: ", enemy_count)
	print("子弹数量: ", bullet_count)
	print("物品数量: ", item_count)
	
	# 检查对象池状态
	if enable_object_pool_check:
		check_object_pools()
	
	# 性能警告
	if fps < 30.0:
		print("🚨 警告：FPS过低！当前FPS: ", fps)
	if avg_frame_time > 0.033: # 超过33ms
		print("🚨 警告：帧时间过长！平均帧时间: ", avg_frame_time * 1000, " ms")
	
	print("==================")

func check_object_pools():
	var main = get_tree().get_root().find_child("Main", true, false)
	if not main:
		return
	
	# 检查子弹池
	var bullet_pool = main.find_child("BulletPool", true, false)
	if bullet_pool:
		var bullet_pool_size = bullet_pool.pool.size()
		var bullet_in_use = 0
		for bullet in bullet_pool.pool:
			if bullet and bullet.get("is_in_use"):
				bullet_in_use += 1
		print("子弹池: ", bullet_in_use, "/", bullet_pool_size, " 使用中")
	
	# 检查敌人池
	var enemy_pool = main.find_child("EnemyPool", true, false)
	if enemy_pool and enemy_pool.pool:
		var enemy_pool_size = enemy_pool.pool.size()
		var enemy_in_use = 0
		for enemy in enemy_pool.pool:
			if enemy and enemy.get("is_in_use") != null:
				if enemy.is_in_use:
					enemy_in_use += 1
		print("敌人池: ", enemy_in_use, "/", enemy_pool_size, " 使用中")
	
	# 暂时屏蔽宝石池检查
	# 检查宝石池
	# var gem_pool = main.find_child("GemPool", true, false)
	# if gem_pool:
	# 	var gem_pool_size = gem_pool.pool.size()
	# 	var gem_in_use = 0
	# 	for gem in gem_pool.pool:
	# 		if gem and gem.get("is_in_use"):
	# 			gem_in_use += 1
	# 	print("宝石池: ", gem_in_use, "/", gem_pool_size, " 使用中")
