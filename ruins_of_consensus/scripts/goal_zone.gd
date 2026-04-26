extends Node2D

@export var zone_radius: float = 60.0

func _ready():
	add_to_group("goals")



func _process(_delta):
	queue_redraw()

func _draw():
	# Green glow circle
	draw_circle(Vector2.ZERO, zone_radius, Color(0.1, 0.8, 0.5, 0.1))
	draw_arc(Vector2.ZERO, zone_radius, 0, TAU, 64, Color(0.3, 1.0, 0.6, 0.4), 2.0)

