extends CharacterBody2D
class_name Enemy

@export var SPEED: float = 150.0
@export var health: float = 100.0
var player: Player = null

@onready var hit_area = $HitArea

func _ready() -> void:
	add_to_group("enemies")
	hit_area.area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	if player == null:
		return
	var direction: Vector2 = (player.global_position - global_position).normalized()
	velocity = direction * SPEED
	move_and_slide()

func take_damage(damage_amount: float) -> void:
	health -= damage_amount
	if health <= 0:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("get") and area.get("direction") != null:
		take_damage(50.0)  # 每发子弹造成50点伤害
		area.queue_free()  # 销毁子弹	
