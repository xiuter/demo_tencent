extends Node

@export var light_weight: float = 1.0
@export var align_weight: float = 0.5
@export var sep_weight: float = 0.2
@export var robot_radius: float = 20.0 # Control the visual size and collision body radius of the swarm
@export var panic_angular_threshold: float = 1.2
@export var panic_angular_gain: float = 0.2
@export var panic_decay: float = 0.1
@export var panic_spread_radius: float = 2.5 # multiplier for robot_radius (e.g. 2.5 * 10 = 25px, maybe 250?)
@export var panic_spread_intensity: float = 0.3
@export var panic_random_force: float = 4.0
@export var abyss_fear_gain: float = 0.05
@export var abyss_distance: float = 150.0

@export var normal_max_speed: float = 300.0 # Multiplied by 100 for pixel scale, originally 1.5
@export var panic_max_speed: float = 400.0  # Originally 3.0
@export var damping: float = 0.9
