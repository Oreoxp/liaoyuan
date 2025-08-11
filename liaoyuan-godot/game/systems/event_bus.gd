extends Node

# 定义游戏中的所有事件名称，方便管理和自动补全
enum Events {
    PLAYER_HEALTH_UPDATED,
    PLAYER_EXP_UPDATED,
    PLAYER_LEVEL_UP,
    PLAYER_DIED,
    ENEMY_DIED
}

signal game_event(event_name: Events, data: Dictionary)

func emit(event_name: Events, data: Dictionary = {}):
    emit_signal("game_event", event_name, data)