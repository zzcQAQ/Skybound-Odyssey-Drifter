extends  CharacterBody2D

# 飞船数据
@export var mass: float = 100
@export var move_accel: float = 5
@export var move_speed: float = 300
@export var rotate_accel: float = 3.0
@export var rotate_speed: float = 3

# 移动目标
@export var move_target_pos: Vector2
@export var move_target: MoveTarget

# 目标方向
@export var direction: Vector2

# 获取右键目标位置
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		move_target_pos = get_global_mouse_position()
		print(move_target_pos)
		
		move_target.show_target(move_target_pos)

# 旋转与移动
func _physics_process(delta: float) -> void:
	direction = move_target_pos - global_position

	# 避免目标过近
	if direction.length_squared() < 9.0:
		velocity = Vector2.ZERO
		move_target.hide_target()
		return

	# 计算目标角度
	var target_angle := direction.angle() + PI / 2

	# 平滑转向目标
	rotation = rotate_toward(rotation, target_angle, rotate_speed * delta)

	# 只有基本对准目标后才开始移动
	if absf(angle_difference(rotation, target_angle)) < PI/2:
		velocity = Vector2.UP.rotated(rotation) * move_speed
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()
	queue_redraw()

func _draw():
	if direction.length_squared() > 9:
		
		draw_line(Vector2.ZERO, to_local(move_target_pos), Color.YELLOW, 1)

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
