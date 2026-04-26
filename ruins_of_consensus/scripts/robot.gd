extends CharacterBody2D

signal died

var panic: float = 0.0
var angle_history: Array[float] = []

@onready var params = get_node("/root/GameParams")


func _ready():
	add_to_group("robots")
	print("[Robot] Spawned at ", global_position)
	velocity = Vector2.RIGHT.rotated(randf() * TAU) * 50.0

func _physics_process(delta):
	if velocity.length_squared() > 10.0:
		var current_angle = velocity.angle()
		if angle_history.size() > 0:
			var delta_angle = wrapf(current_angle - angle_history[-1], -PI, PI)
			var angular_vel = delta_angle / delta
			if abs(angular_vel) > params.panic_angular_threshold and panic < 0.5:
				panic += params.panic_angular_gain * delta
		angle_history.push_back(current_angle)
		if angle_history.size() > 5:
			angle_history.pop_front()
	
	# 深渊双圈检测
	var abysses = get_tree().get_nodes_in_group("abyss")
	for abyss in abysses:
		var dist = global_position.distance_to(abyss.global_position)
		# 内圈：小球中心进入 → 吞噬死亡
		if dist < abyss.inner_radius:
			died.emit()
			queue_free()
			return
		# 外圈：小球边缘碰到 → 瞬间恐慌
		if dist - params.robot_radius < abyss.outer_radius:
			panic = 1.0
			
	panic -= params.panic_decay * delta
	panic = clamp(panic, 0.0, 1.0)
	
	# 视觉效果已移至 _draw()
	
	# 单次循环处理：排斥、对齐、感染
	var forces = process_neighbors(delta)
	var sep = forces["separation"]
	var ali = forces["alignment"]
	
	var acc = Vector2.ZERO
	var current_max_speed = params.normal_max_speed
	
	if panic < 0.5:
		var light = get_light_force()
		acc = ali * params.align_weight + sep * params.sep_weight + light * params.light_weight
	else:
		var random_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		acc = sep * 0.3 + random_dir * params.panic_random_force
		current_max_speed = params.panic_max_speed
		
	velocity += acc * delta * 1000.0 
	velocity *= params.damping
	
	if velocity.length() > current_max_speed:
		velocity = velocity.normalized() * current_max_speed
	elif velocity.length() < 5.0 and acc.length_squared() < 0.1:
		velocity = Vector2.ZERO
		
	move_and_slide()
	queue_redraw()

func process_neighbors(delta) -> Dictionary:
	var separation = Vector2.ZERO
	var alignment = Vector2.ZERO
	var num_ali = 0
	var group = get_tree().get_nodes_in_group("robots")
	
	for r in group:
		if r == self: continue
		var dist = global_position.distance_to(r.global_position)
		
		# 1. 恐慌传播逻辑
		if dist < params.panic_spread_radius * params.robot_radius:
			if r.panic >= 0.5 and panic < 0.5:
				panic += params.panic_spread_intensity * delta
				panic = min(1.0, panic)
				
		# 2. 排斥逻辑
		var sep_dist = params.robot_radius * 4.0
		if dist < sep_dist and dist > 0.1:
			var push_dir = (global_position - r.global_position).normalized()
			var strength = 1.0 - (dist / sep_dist)
			separation += push_dir * strength * 2.0 
			
		# 3. 对齐逻辑
		if panic < 0.5:
			if dist < 100.0:
				alignment += r.velocity
				num_ali += 1
				
	var final_ali = Vector2.ZERO
	if num_ali > 0:
		var avg_vel = alignment / num_ali
		var speed_factor = min(avg_vel.length() / params.normal_max_speed, 1.0)
		if avg_vel.length_squared() > 0.1:
			final_ali = avg_vel.normalized() * speed_factor
			
	return {"separation": separation, "alignment": final_ali}

func get_light_force() -> Vector2:
	var light_force = Vector2.ZERO
	var total_weight = 0.0
	var closest_dist = 999999.0
	
	var beacons = get_tree().get_nodes_in_group("beacons")
	for b in beacons:
		if b.is_on:
			var d_vec = b.global_position - global_position
			var dist = d_vec.length()
			if dist < closest_dist:
				closest_dist = dist
			if dist > 1.0:
				var dist_u = dist / 100.0
				var weight = b.intensity / (dist_u * dist_u + 0.1)
				light_force += d_vec.normalized() * weight
				total_weight += weight
				
	if total_weight > 0.0:
		var result = light_force / total_weight
		if closest_dist < 20.0:
			result *= (closest_dist / 20.0) 
		return result
	return Vector2.ZERO

func _draw():
	# 绘制机器人主体
	var normal_color = Color(1.0, 0.85, 0.2) # 黄色
	var panic_color = Color(1.0, 0.2, 0.1) # 红色
	var body_color = normal_color.lerp(panic_color, panic)
	
	if panic >= 0.5:
		# 恐慌状态：红色实心
		draw_circle(Vector2.ZERO, params.robot_radius, body_color)
	else:
		# 正常状态：黄色实心 + 灰色描边
		draw_circle(Vector2.ZERO, params.robot_radius, body_color)
		draw_arc(Vector2.ZERO, params.robot_radius, 0, TAU, 32, Color(0.3, 0.3, 0.3, 0.8), 1.0)
	
	# 绘制朝向小箭头
	if velocity.length() > 5.0:
		var dir = velocity.normalized()
		var tip = dir * (params.robot_radius + 6)
		var side1 = dir.rotated(0.4) * (params.robot_radius - 2)
		var side2 = dir.rotated(-0.4) * (params.robot_radius - 2)
		var arrow_color = Color.WHITE
		draw_polyline([side1, tip, side2], arrow_color, 2.0, true)
