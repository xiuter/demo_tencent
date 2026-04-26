extends Control

## 关卡编辑器 - 按 Tab 切换编辑/游戏模式

enum PlaceType { ROBOT, BEACON, ABYSS, GOAL }

var edit_mode: bool = false
var dragging_node: Node2D = null
var drag_offset: Vector2 = Vector2.ZERO
var selected_node: Node2D = null
var active_place_type: int = -1 # -1 表示未选中任何放置类型

# 属性面板引用
@onready var editor_ui = $EditorUI
@onready var toolbar = $EditorUI/ToolbarPanel/Toolbar
@onready var props_panel = $EditorUI/PropsPanel
@onready var required_input = $EditorUI/ToolbarPanel/Toolbar/RequiredInput

@onready var main_node: Node2D = get_tree().root.get_node("Main")

@onready var robot_scene = load("res://scenes/robot.tscn")
@onready var beacon_scene = load("res://scenes/beacon.tscn")
@onready var abyss_scene = load("res://scenes/abyss.tscn")
@onready var goal_scene = load("res://scenes/goal_zone.tscn")

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS # 确保在暂停状态下依然能响应输入
	editor_ui.visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	# 为工具栏添加半透明背景
	var toolbar_panel = editor_ui.get_node("ToolbarPanel")
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.9)
	style.border_width_top = 2
	style.border_color = Color(0.3, 0.3, 0.3)
	style.set_content_margin_all(10)
	toolbar_panel.add_theme_stylebox_override("panel", style)

func _unhandled_input(event):
	if not edit_mode: return
	
	if event is InputEventMouseButton:
		var mouse_pos = get_global_mouse_position()
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				# 尝试拖拽已有实体
				var hit = _find_entity_at(mouse_pos)
				if hit:
					dragging_node = hit
					drag_offset = hit.global_position - mouse_pos
					selected_node = hit
					_update_props_panel()
					_set_active_type(-1) # 选中物体时取消放置模式
				elif active_place_type != -1:
					_place_entity(mouse_pos)
				else:
					selected_node = null
					_update_props_panel()
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				# 右键删除
				var hit = _find_entity_at(mouse_pos)
				if hit:
					if selected_node == hit:
						selected_node = null
						_update_props_panel()
					hit.queue_free()
		else:
			# 释放拖拽
			if event.button_index == MOUSE_BUTTON_LEFT:
				dragging_node = null
	
	elif event is InputEventMouseMotion and dragging_node:
		dragging_node.global_position = get_global_mouse_position() + drag_offset

func _input(event):
	# Tab 键切换模式需要全局响应
	if event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
		print("[Editor] Toggle: ", !edit_mode)
		edit_mode = !edit_mode
		_toggle_edit_mode()
		get_viewport().set_input_as_handled()

func _toggle_edit_mode():
	editor_ui.visible = edit_mode
	if edit_mode:
		get_tree().paused = true
		# 保持 IGNORE，由 _input 全局处理，避免 CanvasLayer 阻挡 layer 0
		mouse_filter = Control.MOUSE_FILTER_IGNORE 
		var lm = main_node.get_node_or_null("LevelManager")
		if lm:
			required_input.value = lm.required_robots
	else:
		get_tree().paused = false
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		selected_node = null
		_update_props_panel()

func _place_entity(pos: Vector2):
	var instance: Node2D
	var container_name: String
	
	match active_place_type:
		PlaceType.ROBOT:
			instance = robot_scene.instantiate()
			container_name = "Robots"
		PlaceType.BEACON:
			instance = beacon_scene.instantiate()
			container_name = "Beacons"
		PlaceType.ABYSS:
			instance = abyss_scene.instantiate()
			container_name = "Abysses"
		PlaceType.GOAL:
			instance = goal_scene.instantiate()
			container_name = "Goals"
		_:
			return
	
	instance.position = pos
	var container = main_node.get_node_or_null(container_name)
	if not container:
		container = Node2D.new()
		container.name = container_name
		main_node.add_child(container)
	container.add_child(instance)
	selected_node = instance
	_update_props_panel()

func _find_entity_at(pos: Vector2) -> Node2D:
	var best: Node2D = null
	var best_dist = 40.0  # 最大点击距离
	
	for group_name in ["robots", "beacons", "abyss", "goals"]:
		for node in get_tree().get_nodes_in_group(group_name):
			var dist = pos.distance_to(node.global_position)
			if dist < best_dist:
				best_dist = dist
				best = node
	return best

func _update_props_panel():
	# 清空属性面板
	for child in props_panel.get_children():
		child.queue_free()
	
	if not selected_node:
		props_panel.visible = false
		return
	
	props_panel.visible = true
	
	# 1. 基础坐标编辑 (所有物体通用)
	_add_prop_control("Pos X", 0, 1280, selected_node.position.x, func(val): 
		if is_instance_valid(selected_node): selected_node.position.x = val)
	_add_prop_control("Pos Y", 0, 720, selected_node.position.y, func(val): 
		if is_instance_valid(selected_node): selected_node.position.y = val)
	
	# 2. 特定属性编辑
	if selected_node.is_in_group("beacons"):
		_add_prop_control("Intensity", 0, 5, selected_node.intensity, func(val): 
			if is_instance_valid(selected_node): selected_node.intensity = val)
	elif selected_node.is_in_group("abysses"):
		_add_prop_control("In Radius", 10, 200, selected_node.inner_radius, func(val): 
			if is_instance_valid(selected_node): selected_node.inner_radius = val; selected_node.queue_redraw())
		_add_prop_control("Out Radius", 20, 400, selected_node.outer_radius, func(val): 
			if is_instance_valid(selected_node): selected_node.outer_radius = val; selected_node.queue_redraw())
	elif selected_node.is_in_group("goals"):
		_add_prop_control("Radius", 20, 300, selected_node.zone_radius, func(val): 
			if is_instance_valid(selected_node): selected_node.zone_radius = val; selected_node.queue_redraw())

func _add_prop_control(label_text: String, min_v: float, max_v: float, current_v: float, callback: Callable):
	var hbox = HBoxContainer.new()
	
	var label = Label.new()
	label.text = label_text + ": "
	label.custom_minimum_size.x = 80
	
	var slider = HSlider.new()
	slider.min_value = min_v
	slider.max_value = max_v
	slider.value = current_v
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var spin = SpinBox.new()
	spin.min_value = min_v
	spin.max_value = max_v
	spin.value = current_v
	spin.step = 0.1
	spin.allow_greater = true
	spin.allow_lesser = true
	
	# 同步逻辑
	slider.value_changed.connect(func(val):
		spin.set_value_no_signal(val)
		callback.call(val)
	)
	spin.value_changed.connect(func(val):
		slider.set_value_no_signal(val)
		callback.call(val)
	)
	
	hbox.add_child(label)
	hbox.add_child(slider)
	hbox.add_child(spin)
	props_panel.add_child(hbox)

# === 工具栏按钮回调 ===

func _set_active_type(type: int):
	if active_place_type == type:
		active_place_type = -1 # 再次点击取消选中
	else:
		active_place_type = type
	
	_update_button_styles()

func _update_button_styles():
	var buttons = {
		PlaceType.ROBOT: $EditorUI/ToolbarPanel/Toolbar/RobotBtn,
		PlaceType.BEACON: $EditorUI/ToolbarPanel/Toolbar/BeaconBtn,
		PlaceType.ABYSS: $EditorUI/ToolbarPanel/Toolbar/AbyssBtn,
		PlaceType.GOAL: $EditorUI/ToolbarPanel/Toolbar/GoalBtn
	}
	
	for type in buttons:
		var btn = buttons[type]
		var style = btn.get_theme_stylebox("normal").duplicate()
		if type == active_place_type:
			style.border_color = Color(0, 1, 0.8) # 激活时的青色
			style.set_border_width_all(2)
			btn.add_theme_color_override("font_color", Color(0, 1, 0.8))
		else:
			style.border_color = Color(0.3, 0.3, 0.3)
			style.set_border_width_all(1)
			btn.add_theme_color_override("font_color", Color.WHITE)
		btn.add_theme_stylebox_override("normal", style)

func _on_robot_btn_pressed():
	_set_active_type(PlaceType.ROBOT)

func _on_beacon_btn_pressed():
	_set_active_type(PlaceType.BEACON)

func _on_abyss_btn_pressed():
	_set_active_type(PlaceType.ABYSS)

func _on_goal_btn_pressed():
	_set_active_type(PlaceType.GOAL)

func _on_save_btn_pressed():
	var req = int(required_input.value) if required_input else 5
	var data = LevelData.serialize_scene(main_node, req)
	
	# 优先保存到当前关卡路径
	var path = GameState.current_level_path
	if path == "":
		path = "res://levels/custom_level.json"
	
	LevelData.save_level(path, data)
	print("关卡已保存至: ", path)

func _on_load_btn_pressed():
	# 优先从当前关卡路径重新加载，或加载自定义关卡
	var path = GameState.current_level_path
	if path == "":
		path = "res://levels/custom_level.json"
		
	var data = LevelData.load_level(path)
	if data.size() > 0:
		LevelData.instantiate_level(main_node, data)
		var lm = main_node.get_node_or_null("LevelManager")
		if lm:
			lm.required_robots = data.get("required_robots", 5)
			lm.reset_state()
		print("关卡已加载: ", path)

func _on_required_input_value_changed(value: float):
	var lm = main_node.get_node_or_null("LevelManager")
	if lm:
		lm.required_robots = int(value)
