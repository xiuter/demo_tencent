extends Control

## 关卡选择界面

@onready var grid = $VBox/ScrollContainer/GridContainer
@onready var title_label = $VBox/TitleLabel

var level_btn_style_normal: StyleBoxFlat
var level_btn_style_completed: StyleBoxFlat

func _ready():
	_setup_styles()
	_populate_levels()

func _setup_styles():
	# 极简背景
	var bg = ColorRect.new()
	bg.color = Color(0.12, 0.12, 0.14)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	move_child(bg, 0)
	
	# 普通按钮样式
	level_btn_style_normal = StyleBoxFlat.new()
	level_btn_style_normal.bg_color = Color(0.1, 0.1, 0.1)
	level_btn_style_normal.border_color = Color(0.3, 0.3, 0.3)
	level_btn_style_normal.set_border_width_all(1)
	
	# 已通关样式 (带发光边框)
	level_btn_style_completed = StyleBoxFlat.new()
	level_btn_style_completed.bg_color = Color(0.05, 0.15, 0.1)
	level_btn_style_completed.border_color = Color(0.0, 1.0, 0.8)
	level_btn_style_completed.set_border_width_all(2)
	level_btn_style_completed.shadow_color = Color(0.0, 1.0, 0.8, 0.2)
	level_btn_style_completed.shadow_size = 5


func _populate_levels():
	# 扫描 levels 目录
	var dir = DirAccess.open("res://levels/")
	if not dir:
		# 没有关卡目录，创建默认关卡
		return
	
	var level_files: Array[String] = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".json"):
			level_files.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	
	level_files.sort()
	
	for file in level_files:
		var path = "res://levels/" + file
		var btn = Button.new()
		var level_num = file.get_basename().split("_")[-1]
		
		if GameState.is_completed(path):
			btn.text = "[OK] " + level_num
			btn.add_theme_stylebox_override("normal", level_btn_style_completed)
		else:
			btn.text = level_num
			btn.add_theme_stylebox_override("normal", level_btn_style_normal)
		
		btn.custom_minimum_size = Vector2(100, 100)
		btn.add_theme_font_size_override("font_size", 28)
		btn.pressed.connect(_on_level_pressed.bind(path))
		grid.add_child(btn)

func _on_level_pressed(level_path: String):
	GameState.current_level_path = level_path
	get_tree().change_scene_to_file("res://scenes/main.tscn")
