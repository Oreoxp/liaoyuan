# player_data.gd
# 这是一个全局单例(Autoload)，用于存储和管理所有与玩家相关的核心数据。
# 任何地方都可以通过 PlayerData.变量 或 PlayerData.函数() 来访问它。
extends Node

## 信号 (Signals)
# --------------------
# 信号是模块间解耦的生命线。UI或其他系统可以监听这些信号来响应数据变化。

# 当经验值发生变化时发出。传递参数：当前经验值，升级所需经验值。
signal experience_updated(current_exp: float, required_exp: float)
# 当玩家等级提升时发出。传递参数：新的等级。
signal level_up(new_level: int)
# 当生命值发生变化时发出。传递参数：当前生命值，最大生命值。
signal health_updated(current_health: float, max_health: float)
# 当玩家死亡时发出。
signal died

## 核心战斗属性 (Core Combat Stats)
# --------------------
# 这些是玩家的基础数据，未来可以通过升级或装备来改变。

# 使用setter函数来管理生命值，这样每次改变时都能自动发出信号并检查死亡。
@export var max_health: float = 100.0
@export var current_health: float = 100.0:
	set(value):
		# 使用clamp确保生命值不会超过上限或低于0
		current_health = clamp(value, 0, max_health)
		health_updated.emit(current_health, max_health)
		if current_health == 0:
			died.emit()

## 属性修正器 (Attribute Modifiers)
# --------------------
# 这些是升级系统主要改变的数值。它们作为乘数，提供了极大的灵活性。

# 移动速度修正，默认为1.0 (100%)
var move_speed_modifier: float = 1.0
# 伤害修正，默认为1.0 (100%)
var damage_modifier: float = 1.0
# 攻击冷却时间修正，默认为1.0 (100%)
var cooldown_modifier: float = 1.0


## 经验与等级系统 (Experience & Leveling System)
# --------------------
# 游戏成长的核心驱动。

var level: int = 1
var current_exp: float = 0

## 核心功能 (Core Functions)
# --------------------

# 该函数用于为玩家增加经验值
func add_experience(amount: float) -> void:
	current_exp += amount
	var required_exp_for_current_level = get_required_exp_for_level(level)

	# 使用while循环来健壮地处理一次性升多级的情况
	while current_exp >= required_exp_for_current_level:
		# 1. 扣除本级升级所消耗的经验值
		current_exp -= required_exp_for_current_level
		# 2. 等级提升
		level += 1
		level_up.emit(level) # 发出等级提升信号，触发升级UI等
		# 3. 为下一次循环，更新“下一级”所需经验
		required_exp_for_current_level = get_required_exp_for_level(level)
	
	# 循环结束后，发出最终的经验值更新信号
	experience_updated.emit(current_exp, required_exp_for_current_level)

# 该函数定义了升级所需的经验曲线
func get_required_exp_for_level(target_level: int) -> float:
	# 一个简单的线性增长曲线：1级升2级要100, 2级升3级要200, ...
	# 未来我们可以改成更复杂的公式，比如指数增长 pow(target_level, 2) * 50
	return float(target_level * 100)
	
# 重置所有玩家数据，用于开始新游戏
func reset() -> void:
	level = 1
	current_exp = 0
	max_health = 100.0
	current_health = max_health
	move_speed_modifier = 1.0
	damage_modifier = 1.0
	cooldown_modifier = 1.0
	# 在重置后，也发出一次信号，确保UI能显示正确的初始状态
	health_updated.emit(current_health, max_health)
	experience_updated.emit(current_exp, get_required_exp_for_level(level))
