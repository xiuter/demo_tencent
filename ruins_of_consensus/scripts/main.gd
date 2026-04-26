extends Node2D

## Main 场景的根脚本，负责从 JSON 加载关卡数据

func _ready():
	var level_path = GameState.current_level_path
	if level_path == "":
		level_path = "res://levels/level_01.json"
		GameState.current_level_path = level_path
	
	var data = LevelData.load_level(level_path)
	if data.size() > 0:
		var lm = $LevelManager
		lm.required_robots = data.get("required_robots", 5)
		
		var hud = $HUD
		hud.current_level_path = level_path
		
		# 连接通关信号以记录存档
		lm.level_complete.connect(func(): GameState.mark_complete(level_path))
		
		# 实例化所有实体
		await LevelData.instantiate_level(self, data)
