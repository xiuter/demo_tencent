extends CanvasLayer

## 关卡 HUD - 顶部状态栏 + 重置/退出按钮 + 通关/失败面板

var status_label: Label
var result_panel: PanelContainer
var result_label: Label
var next_btn: Button
var retry_btn: Button

var current_level_path: String = ""

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_top_bar()
	_build_result_panel()

func _build_top_bar():
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.offset_bottom = 60
	
	# 科技感深色背景 + 底部白线
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.05, 0.85)
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.3, 0.3)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	
	# 左侧状态区
	var status_vbox = VBoxContainer.new()
	var title = Label.new()
	title.text = "SYSTEM MONITOR"
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	
	status_label = Label.new()
	status_label.text = "ALIVE: 0  |  GOAL: 0 / 0"
	status_label.add_theme_font_size_override("font_size", 18)
	status_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.8)) # 青色
	
	status_vbox.add_child(title)
	status_vbox.add_child(status_label)
	
	hbox.add_child(status_vbox)
	
	# 中间留空
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)
	
	# 右侧按钮区
	var btn_hbox = HBoxContainer.new()
	btn_hbox.add_theme_constant_override("separation", 10)
	
	var reset_btn = _create_styled_button("RESET")
	reset_btn.pressed.connect(_on_reset_pressed)
	
	var exit_btn = _create_styled_button("EXIT")
	exit_btn.pressed.connect(_on_exit_pressed)
	
	btn_hbox.add_child(reset_btn)
	btn_hbox.add_child(exit_btn)
	hbox.add_child(btn_hbox)
	
	panel.add_child(hbox)
	add_child(panel)

func _create_styled_button(txt: String) -> Button:
	var btn = Button.new()
	btn.text = txt
	btn.custom_minimum_size = Vector2(100, 40)
	
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.1, 0.1, 0.1)
	style_normal.set_border_width_all(1)
	style_normal.border_color = Color(0.4, 0.4, 0.4)
	
	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.2, 0.2, 0.2)
	style_hover.set_border_width_all(1)
	style_hover.border_color = Color(0.0, 1.0, 0.8)
	
	btn.add_theme_stylebox_override("normal", style_normal)
	btn.add_theme_stylebox_override("hover", style_hover)
	btn.add_theme_stylebox_override("pressed", style_hover)
	return btn

func _build_result_panel():
	result_panel = PanelContainer.new()
	result_panel.set_anchors_preset(Control.PRESET_CENTER)
	result_panel.offset_left = -180
	result_panel.offset_top = -100
	result_panel.offset_right = 180
	result_panel.offset_bottom = 100
	result_panel.visible = false
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.9)
	style.border_color = Color.WHITE
	style.set_border_width_all(1)
	style.set_content_margin_all(15)
	result_panel.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	result_label = Label.new()
	result_label.text = ""
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.add_theme_font_size_override("font_size", 28)
	result_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	
	var sep = HSeparator.new()
	
	var btn_box = HBoxContainer.new()
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	
	retry_btn = Button.new()
	retry_btn.text = "[ RETRY ]"
	retry_btn.pressed.connect(_on_reset_pressed)
	
	next_btn = Button.new()
	next_btn.text = "[ NEXT ]"
	next_btn.pressed.connect(_on_next_pressed)
	
	var exit_btn2 = Button.new()
	exit_btn2.text = "[ EXIT ]"
	exit_btn2.pressed.connect(_on_exit_pressed)
	
	btn_box.add_child(retry_btn)
	btn_box.add_child(next_btn)
	btn_box.add_child(exit_btn2)
	
	vbox.add_child(result_label)
	vbox.add_child(sep)
	vbox.add_child(btn_box)
	result_panel.add_child(vbox)
	add_child(result_panel)

func update_status(alive: int, arrived: int, required: int):
	status_label.text = "ALIVE: %d  |  GOAL: %d / %d" % [alive, arrived, required]

func show_result(text: String, is_win: bool):
	result_label.text = text
	result_panel.visible = true
	next_btn.visible = is_win
	get_tree().paused = true

func _on_reset_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_exit_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/level_select.tscn")

func _on_next_pressed():
	get_tree().paused = false
	var current_num = _get_level_num(current_level_path)
	var next_path = "res://levels/level_%02d.json" % (current_num + 1)
	if FileAccess.file_exists(next_path):
		GameState.current_level_path = next_path
		get_tree().reload_current_scene()
	else:
		get_tree().change_scene_to_file("res://scenes/level_select.tscn")

func _get_level_num(path: String) -> int:
	var filename = path.get_file().get_basename()
	var parts = filename.split("_")
	if parts.size() >= 2:
		return int(parts[-1])
	return 0
