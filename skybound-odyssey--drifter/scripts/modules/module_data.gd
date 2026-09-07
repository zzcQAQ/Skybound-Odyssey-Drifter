class_name ModuleData
extends Resource

@export_category("基本信息")
@export var module_name: String = "模块"
@export var description: String = ""

@export_category("外观")
@export var texture: Texture2D

@export_category("网格")
@export var size: Vector2i = Vector2i(1, 1)

@export_category("属性")
@export var mass: float = 10.0
@export var max_hp: float = 100.0
