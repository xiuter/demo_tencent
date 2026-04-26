extends Node

## 关卡数据的 JSON 序列化/反序列化（Autoload 单例）

func save_level(path: String, data: Dictionary) -> void:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()

func load_level(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var json_text = file.get_as_text()
	file.close()
	var json = JSON.new()
	var err = json.parse(json_text)
	if err != OK:
		return {}
	return json.data

func serialize_scene(main_node: Node, required_robots: int) -> Dictionary:
	var data = {
		"required_robots": required_robots,
		"robots": [],
		"beacons": [],
		"abysses": [],
		"goals": []
	}
	for r in main_node.get_tree().get_nodes_in_group("robots"):
		data["robots"].append({"x": r.global_position.x, "y": r.global_position.y})
	for b in main_node.get_tree().get_nodes_in_group("beacons"):
		data["beacons"].append({
			"x": b.global_position.x, "y": b.global_position.y,
			"intensity": b.intensity, "is_on": b.is_on
		})
	for a in main_node.get_tree().get_nodes_in_group("abyss"):
		data["abysses"].append({
			"x": a.global_position.x, "y": a.global_position.y,
			"inner_radius": a.inner_radius, "outer_radius": a.outer_radius
		})
	for g in main_node.get_tree().get_nodes_in_group("goals"):
		data["goals"].append({
			"x": g.global_position.x, "y": g.global_position.y,
			"radius": g.zone_radius
		})
	return data

func instantiate_level(main_node: Node, data: Dictionary) -> void:
	# 清空现有实体
	for group_name in ["robots", "beacons", "abyss", "goals"]:
		for node in main_node.get_tree().get_nodes_in_group(group_name):
			node.queue_free()
	
	# 等一帧让 queue_free 生效
	await main_node.get_tree().process_frame
	
	var robot_scene = load("res://scenes/robot.tscn")
	var beacon_scene = load("res://scenes/beacon.tscn")
	var abyss_scene = load("res://scenes/abyss.tscn")
	var goal_scene = load("res://scenes/goal_zone.tscn")
	
	# 找到或创建容器节点
	var robots_container = _get_or_create_container(main_node, "Robots")
	var beacons_container = _get_or_create_container(main_node, "Beacons")
	var abysses_container = _get_or_create_container(main_node, "Abysses")
	var goals_container = _get_or_create_container(main_node, "Goals")
	
	for r_data in data.get("robots", []):
		var r = robot_scene.instantiate()
		r.position = Vector2(r_data["x"], r_data["y"])
		print("[LevelData] Instantiating robot at: ", r.position)
		robots_container.add_child(r)
	
	for b_data in data.get("beacons", []):
		var b = beacon_scene.instantiate()
		b.position = Vector2(b_data["x"], b_data["y"])
		b.intensity = b_data.get("intensity", 1.0)
		b.is_on = b_data.get("is_on", true)
		beacons_container.add_child(b)
	
	for a_data in data.get("abysses", []):
		var a = abyss_scene.instantiate()
		a.position = Vector2(a_data["x"], a_data["y"])
		a.inner_radius = a_data.get("inner_radius", 50.0)
		a.outer_radius = a_data.get("outer_radius", 100.0)
		abysses_container.add_child(a)
	
	for g_data in data.get("goals", []):
		var g = goal_scene.instantiate()
		g.position = Vector2(g_data["x"], g_data["y"])
		g.zone_radius = g_data.get("radius", 60.0)
		goals_container.add_child(g)

func _get_or_create_container(parent: Node, cname: String) -> Node2D:
	var container = parent.get_node_or_null(cname)
	if not container:
		container = Node2D.new()
		container.name = cname
		parent.add_child(container)
	return container
