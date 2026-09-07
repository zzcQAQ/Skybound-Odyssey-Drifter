class_name ShipGrid
extends Node

# 每格像素大小
@export var cell_size: int = 32

var cells: Dictionary = {}

func grid_to_world(grid_position: Vector2i) -> Vector2:
	return Vector2(grid_position) * cell_size

func world_to_grid(world_position: Vector2) -> Vector2i:
	return Vector2i(
		floor(world_position.x / cell_size),
		floor(world_position.y / cell_size)
	)
