# debug_hud.gd
extends CanvasLayer

@onready var label = $MarginContainer/Label

# 一个字典来存储所有调试信息，方便统一更新
var debug_data = {
    "Level": 1,
    "Health": "100/100",
    "EXP": "0/100"
}

func _ready() -> void:
    # 连接EventBus信号
    EventBus.game_event.connect(_on_game_event)
    
    # 强制进行一次初始更新
    on_health_updated(PlayerData.current_health, PlayerData.max_health)
    on_exp_updated(PlayerData.current_exp, PlayerData.get_required_exp_for_level(PlayerData.level))
    on_level_up(PlayerData.level)

# ---- 事件处理函数 ----
func _on_game_event(event_name: EventBus.Events, data: Dictionary) -> void:
    match event_name:
        EventBus.Events.PLAYER_HEALTH_UPDATED:
            on_health_updated(data.get("current", 0), data.get("max", 0))
        EventBus.Events.PLAYER_EXP_UPDATED:
            on_exp_updated(data.get("current", 0), data.get("required", 0))
        EventBus.Events.PLAYER_LEVEL_UP:
            on_level_up(data.get("new_level", 1))

# ---- 信号处理函数 ----
func on_health_updated(current: float, max_val: float) -> void:
    debug_data["Health"] = "%d/%d" % [current, max_val]
    update_display()
    
func on_exp_updated(current: float, required: float) -> void:
    debug_data["EXP"] = "%d/%d" % [current, required]
    update_display()

func on_level_up(new_level: int) -> void:
    debug_data["Level"] = new_level
    update_display()

# ---- 核心显示函数 ----
func update_display() -> void:
    # 将字典里的所有数据显示出来
    var text_to_show = ""
    for key in debug_data:
        text_to_show += "%s: %s\n" % [key, debug_data[key]]
    label.text = text_to_show