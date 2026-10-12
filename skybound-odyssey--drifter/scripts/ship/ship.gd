class_name Ship
extends Node2D

@onready var ship_grid: ShipGrid = $ShipGrid

var modules: Array[ShipModule] = []

# =====建造模块=====
func add_module(module_data: ModuleData, grid_position: Vector2i) -> ShipModule:
	# 判断能否放置
	if not ship_grid.can_place(grid_position, module_data.size):
		return null
	
	# 创建模块场景
	var module_scene := module_data.scene
	
	if module_scene == null:
		push_error("模块没有设置场景：" + module_data.module_name)
		return null
		
	# 实例化场景
	var module := module_scene.instantiate() as ShipModule
	if module == null:
		push_error("模块场景不是 ShipModule")
		return null
	
	# 挂载场景于飞船
	add_child(module)
	
	# 初始化模块场景
	module.setup(module_data, grid_position)
	
	# 设置模块世界坐标
	module.position = ship_grid.grid_to_world(grid_position)
	
	# 加入模块列表
	modules.append(module)
	
	# 占据格子
	ship_grid.occupy(module)
	
	return module

# =====删除模块=====
func remove_module(module: ShipModule) -> void:
	
	if module == null:
		return
	
	ship_grid.remove_module(module)
	module.erase(module)
	module.queue_free()
