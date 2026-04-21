extends Node2D

@export var radius: float = 100.0

func _draw():
	# 绘制深坑视觉效果 (黑红色)
	draw_circle(Vector2.ZERO, radius, Color(0.3, 0.0, 0.0, 0.5))
	draw_circle(Vector2.ZERO, radius * 0.5, Color(0.05, 0.0, 0.0, 1.0))
