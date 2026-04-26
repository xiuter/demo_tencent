extends Node

## 全局游戏状态，用于跨场景传递数据

var current_level_path: String = ""
var completed_levels: Array[String] = []

func mark_complete(level_path: String):
	if level_path not in completed_levels:
		completed_levels.append(level_path)
	# 持久化存档
	_save()

func is_completed(level_path: String) -> bool:
	return level_path in completed_levels

func _ready():
	_load()

func _save():
	var file = FileAccess.open("user://save.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"completed": completed_levels}))
		file.close()

func _load():
	if not FileAccess.file_exists("user://save.json"):
		return
	var file = FileAccess.open("user://save.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			var data = json.data
			completed_levels.assign(data.get("completed", []))
		file.close()
