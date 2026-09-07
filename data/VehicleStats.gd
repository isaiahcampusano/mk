class_name VehicleStats
extends Resource

@export var vehicle_id: StringName
@export var vehicle_name: String
@export var icon: Texture2D
@export_enum("Standard", "Long", "Compact", "Drift") var model_profile: int = 0
@export var primary_color := Color("#ef3f47")
@export var speed_mod: float = 1.0
@export var accel_mod: float = 1.0
@export var handling_mod: float = 1.0
@export var drift_mod: float = 1.0

