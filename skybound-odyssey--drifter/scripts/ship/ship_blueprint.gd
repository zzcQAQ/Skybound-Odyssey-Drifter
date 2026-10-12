# 飞船蓝图
class_name ShipBlueprint
extends Resource

# 蓝图数组
@export var modules: Array[ModulePlacement] = []

# 添加模块
func add_module(placement: ModulePlacement) -> void:
	modules.append(placement)

# 删除模块
func remove_modules(placement:ModulePlacement) -> void:
	modules.erase(placement)

# 清除蓝图
func clear() -> void:
	modules.clear()
