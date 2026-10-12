extends  CharacterBody2D

# 飞船数据
@export var move_accel: float = 1
@export var rotate_accel: float = 3.0

# 目标位置
@export var target_pos: Vector2

# 获取右键目标位置
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		target_pos = get_global_mouse_position()
		print(target_pos)

# 旋转与移动
func _physics_process(delta: float) -> void:
	
	var direction = position - target_pos
	
	# 避免目标过近
	if direction.length_squared() > 1.0:
		# 移动
		var distance = position.distance_to(target_pos)
		
	
#func _input(event):
	#if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		#target_position = get_global_mouse_position()
		#print(distance)
		#print(accelDistance)
		#queue_redraw()
#
#func _physics_process(delta):
	#distance = position.distance_to(target_position)
	#var direction = (target_position - position).normalized()
	#accelDistance = velocity.dot(direction) / (accel * 2)
	#if distance <= 3:
		#velocity = Vector2.ZERO
	#
	#if distance < accelDistance + 3:
		#velocity = velocity.move_toward(
			#(position - target_position).normalized() * maxSpeed, 
			#accel * maxSpeed * delta 
		#)
	#else:
		#velocity = velocity.move_toward(
			#direction * maxSpeed, 
			#accel * maxSpeed * delta
		#)
	#move_and_slide()
	#queue_redraw()

#func _draw():
	#if position.distance_to(target_position) > 3:
		#
		#var local_target = to_local(target_position)
		#draw_line(Vector2.ZERO, local_target, Color.YELLOW, line_width)
