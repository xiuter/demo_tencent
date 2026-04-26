extends Node2D

@export var inner_radius: float = 50.0  # 黑色吞噬圈 - 小球中心进入即死
@export var outer_radius: float = 100.0 # 暗红恐慌圈 - 小球边缘碰到即恐慌



func _ready():
	add_to_group("abysses")

func _process(_delta):
	queue_redraw()

func _draw():
	# 外圈：恐慌预警区
	draw_circle(Vector2.ZERO, outer_radius, Color(0.3, 0.0, 0.0, 0.2))
	draw_arc(Vector2.ZERO, outer_radius, 0, TAU, 64, Color(0.6, 0.1, 0.0, 0.4), 2.0)
	
	# 内圈：黑色吞噬核心
	draw_circle(Vector2.ZERO, inner_radius, Color(0.05, 0.05, 0.05, 1.0))
	draw_arc(Vector2.ZERO, inner_radius, 0, TAU, 64, Color(0.4, 0.1, 0.0, 0.8), 4.0)
