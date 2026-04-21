extends Node2D

@export var is_on: bool = true
@export var intensity: float = 1.0

func _ready():
	add_to_group("beacons")

func _process(_delta):
	queue_redraw()

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if global_position.distance_to(get_global_mouse_position()) < 40.0:
			is_on = !is_on

func _draw():
	if is_on:
		draw_circle(Vector2.ZERO, 30.0, Color(1, 1, 1, 0.4 * intensity))
		draw_circle(Vector2.ZERO, 10.0, Color.WHITE)
	else:
		draw_circle(Vector2.ZERO, 10.0, Color.DARK_GRAY)
