extends CharacterBody2D

const MOTION_SCALE: float = 300.0

# 飞船数据
@export var mass: float = 100
@export var engine_limit: float = 50.0
@export var engine_force: float = 100.0

@export var rotate_speed: float = 5

# 独立制动始终逆着速度方向，不随船头旋转。
@export_range(0.1, 5.0) var brake_multiplier: float = 1.0

@export var move_target: MoveTarget

var is_docking: bool = false

var move_target_pos: Vector2
var target_angle: float = 0.0

var move_accel_max: float = 0.0
var move_speed_max: float = 0.0
var move_speed: float = 0.0
# 标量速率变化率，并非加速度向量的长度。
var current_accel: float = 0.0
var brake_distance: float = 0.0

@export var target_distance: float = 0
var accelDistance: float = 0
var direction: Vector2

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			move_target_pos = get_global_mouse_position()
			move_target.show_target(move_target_pos)
			queue_redraw()
			update_ship()

# 更新飞船数值
func update_ship() -> void:
	move_accel_max = engine_force / mass
	move_speed_max = (engine_limit / mass) * 500

# ==========物理帧========== #
func _physics_process(delta):
	direction = (move_target_pos - position).normalized()
	target_distance = position.distance_to(move_target_pos)
	
	target_angle = direction.angle() + PI/2
	
	rotate_ship(delta)
	
	if absf(angle_difference(rotation, target_angle)) <= PI/45:
		boost_ship(delta)
	
	move_and_slide()

	queue_redraw()

# 飞船旋转
func rotate_ship(delta: float) -> void:
	if target_distance < 1:
		return
	rotation = rotate_toward(rotation, target_angle, rotate_speed * delta)

# 飞船推进
func boost_ship(delta: float) -> void:
	accelDistance = velocity.dot(direction) / (move_accel_max * 2)
	
	if target_distance <= 5:
		move_target.hide_target()
		velocity = Vector2.ZERO
	
	if target_distance < accelDistance + 5:
		velocity = velocity.move_toward(
			(position - move_target_pos).normalized() * move_speed_max, 
			move_accel_max * move_speed_max * delta 
		)
	else:
		velocity = velocity.move_toward(
			direction * move_speed_max, 
			move_accel_max * move_speed_max * delta
		)

func _draw() -> void:
	draw_line(
		Vector2.ZERO,
		to_local(move_target_pos),
		Color.YELLOW,
		1.0
		)
