# weapon_data.gd
extends Resource
class_name WeaponData # 给予一个全局名称，方便使用

# 基础属性
@export var weapon_name: String = "步枪"
@export var base_damage: float = 50.0
@export var base_cooldown: float = 1.0 # 基础冷却时间

# 成长属性
var level: int = 1
var current_damage: float = base_damage
var current_cooldown: float = base_cooldown

func get_current_cooldown() -> float:
	return current_cooldown

func get_current_damage() -> float:
	return current_damage

func level_up():
	level += 1
	# 一个简单的升级例子：伤害每次提升10%，冷却减少5%
	current_damage *= 1.10
	current_cooldown *= 0.95 