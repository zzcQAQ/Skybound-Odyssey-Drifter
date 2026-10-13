class_name MoveTarget
extends Node2D

@export var move_target_pos: Vector2

# 初始化
func _ready() -> void:
	modulate.a = 0

# 显示
func show_target(target_pos) -> void:
	modulate.a = 1
	global_position = target_pos

func hide_target() -> void:
	modulate.a = 0
# 隐藏
