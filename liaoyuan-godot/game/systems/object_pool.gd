# res://game/systems/object_pool.gd
extends Node
class_name ObjectPool

# 要池化的对象场景
@export var scene: PackedScene
# 初始池大小
@export var initial_size: int = 20
# 最大池大小
@export var max_size: int = 100
# 是否延迟初始化
@export var lazy_init: bool = true

# 用于存放我们所有对象的数组
var pool: Array = []
var is_initialized: bool = false

func _ready() -> void:
	# 如果启用延迟初始化，不立即填充池子
	if not lazy_init:
		call_deferred("populate_pool")

# 预填充池子
func populate_pool() -> void:
	if is_initialized:
		return
		
	if not scene:
		print("错误：ObjectPool '%s' 的 scene 属性未设置！" % name)
		return
	
	# 确保我们在场景树中
	if not is_inside_tree():
		print("警告：ObjectPool '%s' 不在场景树中，等待下一帧" % name)
		call_deferred("populate_pool")
		return
	
	# 限制初始大小，避免启动时创建过多对象
	var actual_initial_size = min(initial_size, 20)
	
	for i in range(actual_initial_size):
		var obj = scene.instantiate()
		if obj:
			add_child(obj)
			pool.append(obj)
			release(obj) # 初始化后立即"归还"，让它进入休眠
		else:
			print("错误：无法实例化场景对象！")
	
	is_initialized = true
	print("对象池 '%s' 已初始化，包含 %d 个对象" % [name, pool.size()])

# 从池中获取一个对象
func acquire() -> Node:
	# 如果还没初始化，先初始化
	if not is_initialized:
		populate_pool()
	
	# 寻找一个休眠的对象
	var available_obj = find_available_object()
	if available_obj:
		# 安全地调用show方法，确保对象是CanvasItem
		if available_obj is CanvasItem:
			available_obj.show()
		else:
			print("警告：对象不是CanvasItem，无法调用show()方法")
		
		# 设置对象为使用中状态
		if available_obj.has_method("set_in_use"):
			available_obj.set_in_use(true)
		elif available_obj.get("is_in_use") != null:
			available_obj.is_in_use = true
		
		return available_obj
	else:
		# 如果池子不够大且未达到最大限制，动态扩容
		if pool.size() < max_size:
			return grow_pool()
		else:
			print("警告：对象池 '%s' 已达到最大大小 %d，无法创建更多对象" % [name, max_size])
			return null

# 归还一个对象到池中
func release(obj: Node) -> void:
	# 确保对象存在并且是我们的子节点
	if obj and is_instance_valid(obj) and obj.get_parent() == self:
		# 安全地调用hide方法，确保对象是CanvasItem
		if obj is CanvasItem:
			obj.hide()
		else:
			print("警告：对象不是CanvasItem，无法调用hide()方法")
		
		# 设置对象为未使用状态
		if obj.has_method("set_in_use"):
			obj.set_in_use(false)
		elif obj.get("is_in_use") != null:
			obj.is_in_use = false
		
		# 如果对象有自己的reset方法，可以调用它
		if obj.has_method("reset_state"):
			obj.reset_state()
	else:
		print("警告：尝试释放无效对象或不属于此池的对象")

## ---- 私有辅助函数 ---- ##
func find_available_object() -> Node:
	# 清理无效对象
	cleanup_invalid_objects()
	
	for obj in pool:
		# 安全地检查对象状态
		if is_object_available(obj):
			return obj
	return null

# 清理池中的无效对象
func cleanup_invalid_objects() -> void:
	var valid_objects: Array = []
	
	for obj in pool:
		# 检查对象是否仍然有效（没有被释放）
		if is_instance_valid(obj) and obj.get_parent() == self:
			valid_objects.append(obj)
		else:
			# 对象已被释放，从场景树中移除（如果还在的话）
			if is_instance_valid(obj) and obj.get_parent():
				obj.get_parent().remove_child(obj)
			print("ObjectPool: 清理了无效对象")
	
	# 更新池数组
	if valid_objects.size() != pool.size():
		pool = valid_objects
		print("ObjectPool: 池大小从 %d 更新为 %d" % [pool.size() + (valid_objects.size() - pool.size()), valid_objects.size()])

# 检查对象是否可用（未被使用）
func is_object_available(obj: Node) -> bool:
	# 首先检查对象是否仍然有效
	if not is_instance_valid(obj):
		return false
	
	# 优先使用对象自己的可用性检查方法
	if obj.has_method("is_available"):
		return obj.is_available()
	
	# 对于有 is_in_use 属性的对象，检查该属性
	if obj.get("is_in_use") != null:
		return not obj.is_in_use
	
	# 对于CanvasItem，使用visible属性
	if obj is CanvasItem:
		return not obj.visible
	
	# 如果都没有，假设对象可用（这是一个后备方案）
	return true
	
func grow_pool() -> Node:
	# 如果需要动态扩容
	var obj = scene.instantiate()
	if obj:
		add_child(obj)
		pool.append(obj)
		# 安全地调用show方法，确保对象是CanvasItem
		if obj is CanvasItem:
			obj.show() # 新创建的直接激活使用
		else:
			print("警告：对象不是CanvasItem，无法调用show()方法")
		return obj
	else:
		print("错误：无法创建新对象进行扩容！")
		return null

# 获取池状态信息
func get_pool_info() -> Dictionary:
	# 清理无效对象
	cleanup_invalid_objects()
	
	var active_count = 0
	var total_count = pool.size()
	
	for obj in pool:
		if not is_object_available(obj):
			active_count += 1
	
	return {
		"total": total_count,
		"active": active_count,
		"available": total_count - active_count,
		"max_size": max_size
	}
