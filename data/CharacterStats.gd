class_name CharacterStats
extends Resource

@export var character_name: String
@export var portrait: Texture2D
@export_range(0.0, 1.0, 0.01) var weight: float = 0.5
@export var base_speed_mod: float = 1.0
@export var base_accel_mod: float = 1.0
@export var base_handling_mod: float = 1.0

