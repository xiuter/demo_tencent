extends Node2D

@export var is_on: bool = false
@export var intensity: float = 1.0



func _ready():
	add_to_group("beacons")

func _process(_delta):
	queue_redraw()

func _input(event):
	if get_tree().paused: return # 编辑器模式下不响应开关
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if global_position.distance_to(get_global_mouse_position()) < 30.0:
			is_on = !is_on

func _draw():
	# 未亮起：1个白色圆圈（带描边增强辨识度）
	draw_circle(Vector2.ZERO, 10.0, Color.WHITE)
	draw_arc(Vector2.ZERO, 10.0, 0, TAU, 32, Color(0.5, 0.5, 0.5), 1.0)
	
	if is_on:
		# 亮起：外层再加一层浅白色圆圈（光晕感）
		draw_circle(Vector2.ZERO, 40.0 * intensity, Color(1, 1, 1, 0.15))
		# 核心点高亮
		draw_circle(Vector2.ZERO, 4.0, Color(1, 1, 0.8))
