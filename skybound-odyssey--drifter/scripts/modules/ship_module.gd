class_name ShipModule
extends Node2D

var data: ModuleData

var grid_position: Vector2i
var current_hp: float

# 初始化模块
func setup(module_data: ModuleData, position_on_grid: Vector2i) -> void:
	data = module_data
	grid_position = position_on_grid
	current_hp = data.max_hp
	
	update_visual()

# 获取贴图
func update_visual() -> void:
	var sprite := get_node_or_null("sprite2D")
	if sprite and data:
		sprite.texture = data.texture

# 被击中
func take_damage(amount: float) -> void:
	current_hp -= amount
	current_hp = max(current_hp, 0.0)
	if current_hp <= 0.0:
		destory()

# 炸了喵
func destory() -> void:
	queue_free()
