extends Node

signal level_complete
signal level_failed

@export var required_robots: int = 5
@export var goal_radius_override: float = 0.0  # 若 >0 则覆盖 GoalZone 自身的 radius

var is_complete: bool = false
var is_failed: bool = false
var total_robots: int = 0
var reached_count: int = 0

func _ready():
	# 记录初始小球数量
	await get_tree().process_frame
	total_robots = get_tree().get_nodes_in_group("robots").size()

func _process(_delta):
	if is_complete or is_failed:
		return
	
	var robots = get_tree().get_nodes_in_group("robots")
	var goals = get_tree().get_nodes_in_group("goals")
	
	for robot in robots:
		for goal in goals:
			var radius = goal_radius_override if goal_radius_override > 0 else goal.zone_radius
			if robot.global_position.distance_to(goal.global_position) < radius:
				reached_count += 1
				robot.remove_from_group("robots") # 立即移除防止同帧重复处理
				robot.queue_free() # 立即消失
				break
	
	var alive_count = get_tree().get_nodes_in_group("robots").size()
	
	# 更新 HUD
	var hud = get_node_or_null("../HUD")
	if hud:
		hud.update_status(alive_count, reached_count, required_robots)
	
	# 通关判定
	if reached_count >= required_robots:
		is_complete = true
		level_complete.emit()
		if hud:
			hud.show_result("通关！", true)
	elif (alive_count + reached_count) < required_robots:
		is_failed = true
		level_failed.emit()
		if hud:
			hud.show_result("失败 - 存活机器人不足", false)

func reset_state():
	is_complete = false
	is_failed = false
	reached_count = 0
	total_robots = 0
