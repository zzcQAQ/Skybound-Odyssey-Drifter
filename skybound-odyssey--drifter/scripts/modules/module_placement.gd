class_name ModulePlacement
extends Resource

# 确定放置的模块
@export var module_data: ModuleData

# 模块位置
@export var grid_pos: Vector2i = Vector2i.ZERO

# 模块旋转角度
@export_range(0, 3) var rotation_index: int = 0
