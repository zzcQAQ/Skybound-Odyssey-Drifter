extends CharacterBody2D

const MOTION_SCALE: float = 300.0

# 飞船数据
@export var mass: float = 50.0
@export var engine_limit: float = 50.0
@export var engine_force: float = 10.0

# 独立制动始终逆着速度方向，不随船头旋转。
@export_range(0.1, 5.0) var brake_multiplier: float = 1.0

# 旋转与导航。响应时间越长，航向修正越柔和。
@export var rotate_speed_max: float = 10.0
@export_range(0.0, 1.5708) var move_angle_tolerance: float = PI / 12.0
@export_range(0.1, 5.0) var navigation_response_time: float = 0.5

# 辅助推力上限为最大推进加速度的此比例，途中不会直接抹去侧滑。
@export_range(0.0, 0.5) var assist_force_ratio: float = 0.15
@export_range(1.0, 100.0) var docking_radius: float = 24.0
@export_range(0.01, 5.0) var arrival_distance: float = 0.5
@export_range(0.01, 5.0) var arrival_speed: float = 0.5

@export var move_target: MoveTarget

var is_docking: bool = false

var move_target_pos: Vector2
var target_direction: Vector2 = Vector2.ZERO
# 自动导航要求的船头角度，修正侧滑时不一定朝向目标点。
var target_angle: float = 0.0
var has_move_target: bool = false

var move_accel_max: float = 0.0
var move_speed_max: float = 0.0
var move_speed: float = 0.0
# 标量速率变化率，并非加速度向量的长度。
var current_accel: float = 0.0
var brake_distance: float = 0.0


func _ready() -> void:
	move_target_pos = global_position
	update_ship()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			# 改变目标不改变当前速度，保留原航向的惯性。
			move_target_pos = get_global_mouse_position()
			has_move_target = true
			is_docking = false
			if is_instance_valid(move_target):
				move_target.show_target(move_target_pos)
			queue_redraw()


func update_ship() -> void:
	if mass <= 0.0 or engine_limit <= 0.0 or engine_force <= 0.0:
		move_speed_max = 0.0
		move_accel_max = 0.0
		return

	move_speed_max = engine_limit / mass * MOTION_SCALE
	move_accel_max = engine_force / mass * MOTION_SCALE


func _physics_process(delta: float) -> void:
	if delta <= 0.0:
		return

	update_ship()
	var previous_speed: float = velocity.length()
	brake_distance = 0.0

	if has_move_target:
		target_direction = move_target_pos - global_position
		# 高速经过目标不能瞬间停车；必须同时满足位置与速度容差。
		if can_finish_movement():
			finish_movement()
			return

		if move_speed_max > 0.0 and move_accel_max > 0.0:
			navigate(delta)

	# 没有目标或引擎失效时仍移动，不清除已有惯性。
	move_and_slide()
	move_speed = velocity.length()
	current_accel = (move_speed - previous_speed) / delta

	if has_move_target:
		target_direction = move_target_pos - global_position
		if can_finish_movement():
			finish_movement()

	queue_redraw()


func navigate(delta: float) -> void:
	var distance: float = target_direction.length()
	var speed: float = velocity.length()
	var brake_accel: float = move_accel_max * maxf(brake_multiplier, 0.1)
	brake_distance = speed * speed / (2.0 * brake_accel)

	var assist_accel: float = move_accel_max * clampf(assist_force_ratio, 0.0, 0.5)
	# 只在辅助推力足以制停的低速区进入停靠；高速掠过不触发。
	# 停靠状态保持到完成或切换目标，避免在半径边界反复切换。
	if assist_accel > 0.0:
		var assist_stop_distance: float = speed * speed / (2.0 * assist_accel)
		if distance <= docking_radius and assist_stop_distance <= docking_radius * 0.25:
			is_docking = true
		if is_docking:
			apply_docking_assist(delta, assist_accel)
			return

	# 为有限转向速度及离散物理帧留出制动余量。
	# 近距离使用线性接近速度，避免终点附近不断加速、反向。
	var response_time: float = maxf(navigation_response_time, delta)
	var usable_distance: float = maxf(distance - speed * delta, 0.0)
	var safe_speed: float = sqrt(brake_accel * usable_distance)
	var desired_speed: float = minf(
		move_speed_max,
		minf(safe_speed, distance / response_time)
	)
	var desired_velocity: Vector2 = target_direction.normalized() * desired_speed
	var requested_accel: Vector2 = (desired_velocity - velocity) / response_time

	# 将导航需求拆成逆速度的独立制动与需要船头提供的推进。
	# 这里只计算期望速度，绝不把 velocity 直接改成目标方向。
	var velocity_direction: Vector2 = velocity.normalized()
	var requested_brake: float = maxf(
		-requested_accel.dot(velocity_direction), 0.0
	)
	var thrust_request: Vector2 = (
		requested_accel + velocity_direction * requested_brake
	)

	# 优先让辅助推进承担小幅修正，主引擎只追踪剩余的大幅需求。
	var assist_request: Vector2 = thrust_request.limit_length(assist_accel)
	thrust_request -= assist_request

	if thrust_request.length_squared() > 0.000001:
		target_angle = thrust_request.angle() + PI / 2.0
		global_rotation = rotate_toward(
			global_rotation,
			target_angle,
			maxf(rotate_speed_max, 0.0) * delta
		)

	# 先积分制动，最多减至零，不允许制动把速度反转。
	var braking: float = minf(requested_brake, brake_accel)
	velocity -= velocity_direction * minf(braking * delta, speed)
	apply_assist_velocity(assist_request * delta)

	if thrust_request.length_squared() <= 0.000001:
		return

	if absf(angle_difference(global_rotation, target_angle)) > move_angle_tolerance:
		# 未对准时不点火，但已有速度继续保留。
		return

	# 推力只沿船头方向，不能直接消除侧向速度。
	var forward: Vector2 = Vector2.UP.rotated(global_rotation)
	var requested_thrust: float = maxf(thrust_request.dot(forward), 0.0)
	var speed_ratio: float = clampf(velocity.length() / move_speed_max, 0.0, 1.0)
	var available_accel: float = move_accel_max * (1.0 - speed_ratio)
	var thrust_delta: float = minf(requested_thrust, available_accel) * delta

	# 只限制此次船头推力，不缩放整个速度向量或抹去侧滑。
	# 解 |velocity + forward * thrust_delta| <= move_speed_max。
	if velocity.length_squared() < move_speed_max * move_speed_max:
		var forward_speed: float = velocity.dot(forward)
		var max_thrust_delta: float = maxf(
			-forward_speed + sqrt(maxf(
				forward_speed * forward_speed
				+ move_speed_max * move_speed_max - velocity.length_squared(),
				0.0
			)),
			0.0
		)
		thrust_delta = minf(thrust_delta, max_thrust_delta)
	else:
		thrust_delta = 0.0

	velocity += forward * thrust_delta


func apply_assist_velocity(delta_velocity: Vector2) -> void:
	var amount: float = delta_velocity.length()
	if amount <= 0.000001:
		return
	var direction: Vector2 = delta_velocity / amount
	# 限制新增的辅助推力，不强制截断已有惯性（例如质量变化后超速）。
	var speed_cap: float = maxf(move_speed_max, velocity.length())
	var projected_speed: float = velocity.dot(direction)
	var allowed_delta: float = maxf(
		-projected_speed + sqrt(maxf(
			projected_speed * projected_speed
			+ speed_cap * speed_cap - velocity.length_squared(), 0.0
		)), 0.0
	)
	velocity += direction * minf(amount, allowed_delta)


func apply_docking_assist(delta: float, assist_accel: float) -> void:
	# 临界阻尼的位置控制：a = omega² * 位置误差 - 2 * omega * 速度。
	# 不再旋转船头，也不使用主引擎追逐微小的坐标误差。
	var omega: float = minf(
		sqrt(assist_accel / maxf(docking_radius, 1.0)),
		0.5 / delta
	)
	var correction: Vector2 = (
		target_direction * omega * omega - velocity * (2.0 * omega)
	).limit_length(assist_accel)
	apply_assist_velocity(correction * delta)


func can_finish_movement() -> bool:
	return (
		target_direction.length_squared() <= arrival_distance * arrival_distance
		and velocity.length_squared() <= arrival_speed * arrival_speed
	)


func finish_movement() -> void:
	# 只在极低速且极近时收敛数值误差，不在高速掠过时吸附。
	global_position = move_target_pos
	velocity = Vector2.ZERO
	move_speed = 0.0
	current_accel = 0.0
	brake_distance = 0.0
	target_direction = Vector2.ZERO
	has_move_target = false
	is_docking = false

	if is_instance_valid(move_target):
		move_target.hide_target()

	queue_redraw()


func _draw() -> void:
	if has_move_target:
		draw_line(
			Vector2.ZERO,
			to_local(move_target_pos),
			Color.YELLOW,
			1.0
		)
