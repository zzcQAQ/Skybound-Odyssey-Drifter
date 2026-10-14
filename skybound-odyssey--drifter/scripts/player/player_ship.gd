extends  CharacterBody2D

# 飞船数据
@export var mass: float = 100

@export var move_accel: float = 500
@export var move_speed_max: float = 500
@export var move_speed: float = 0
@export var accel_distance: float = 0

@export var rotate_accel: float = 3
@export var rotate_speed_max: float = 10
@export var rotate_speed: float = 0

# 移动目标
@export var move_target_pos: Vector2
@export var move_target: MoveTarget

@export var target_angle: float

# 目标向量
@export var target_direction: Vector2

# 获取右键目标位置
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		move_target_pos = get_global_mouse_position()
		#print(rotation)
		#print(target_angle)
		
		move_target.show_target(move_target_pos)



# 旋转与移动判定
func _physics_process(delta: float) -> void:
	
	update_target()
	
	# 目标距离过近
	if target_direction.length_squared() < 9.0:
		velocity = Vector2.ZERO
		move_target.hide_target()
		rotate_speed = 0
		move_speed = 0
		return

	rotate_ship(delta)

	# 只有基本对准目标后才开始移动
	if absf(angle_difference(rotation, target_angle)) < PI/2:
		
		boost_ship(delta)
	else:
		velocity = Vector2.ZERO
	
	move_and_slide()
	queue_redraw()

# 目标状态//每帧更新
func update_target() -> void:
	# 目标向量
	target_direction = move_target_pos - global_position
	
	# 目标方向
	target_angle = target_direction.angle() + PI/2
	
	# 加速距离
	accel_distance = (pow(move_speed_max, 2) / move_accel) / 2

# 飞船转向//每帧更新
func rotate_ship(delta: float) -> void:
	if rotate_speed < rotate_speed_max:
		rotate_speed += rotate_accel * delta
	rotation = rotate_toward(rotation, target_angle, rotate_speed * delta)

# 飞船推进//每帧更新
func boost_ship(delta: float) -> void:
	var y = exp(- move_speed )
	var current_accel = move_accel * y
	move_speed += current_accel * delta
	velocity = Vector2.UP.rotated(rotation) * move_speed
	print(move_speed)
	
	# y = e ^ (- 1/mass * x) y是加速度乘数， x是当前速度

func _draw():
	if target_direction.length_squared() > 9:
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
