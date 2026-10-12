class_name ShipGrid
extends Node

# 每格像素大小
@export var cell_size: int = 32

var cells: Dictionary = {}

# 坐标转换
func grid_to_world(grid_position: Vector2i) -> Vector2:
	return Vector2(grid_position) * cell_size

func world_to_grid(world_position: Vector2) -> Vector2i:
	return Vector2i(
		floor(world_position.x / cell_size),
		floor(world_position.y / cell_size)
	)

# 判定能否放置
func can_place(position: Vector2i, size: Vector2i) -> bool:
	for x in range(size.x):
		for y in range(size.y):
			var cell := position + Vector2i(x, y)
			if cells.has(cell):
				return false
	
	if cells.is_empty():
		return true
	
	return has_adjacent_module(position,size)

# 判定是否相邻
func has_adjacent_module(position: Vector2i, size: Vector2i) -> bool:
	for x in range(size.x):
		for y in range(size.y):
			var cell := position + Vector2i(x, y)
			var neighbors := [
				cell + Vector2i.UP,
				cell + Vector2i.DOWN,
				cell + Vector2i.LEFT,
				cell + Vector2i.RIGHT
			]
			
			for neighbor in neighbors:
				if cells.has(neighbor):
					return true
	
	return false

# 占据格子
func occupy(module: ShipModule) -> void:
	for x in range(module.data.size.x):
		for y in range(module.data.size.y):
			var cell := ( module.grid_position + Vector2i(x, y) )
			cells[cell] = module

# 删除模块
func remove_module(module: ShipModule) -> void:
	for x in range(module.data.size.x):
		for y in range(module.data.size.y):
			var cell := ( module.grid_position + Vector2i(x, y) )
			if cells.get(cell) == module:
				cells.erase(cell)
