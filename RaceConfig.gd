extends Node

var characters: Array[CharacterStats] = [
	preload("res://data/characters/pip_spark.tres"),
	preload("res://data/characters/nova_reed.tres"),
	preload("res://data/characters/rook_ember.tres"),
	preload("res://data/characters/bramble_knox.tres"),
]

var vehicles: Array[VehicleStats] = [
	preload("res://data/vehicles/comet.tres"),
	preload("res://data/vehicles/vortex_gt.tres"),
	preload("res://data/vehicles/zipbug.tres"),
	preload("res://data/vehicles/slidewinder.tres"),
]

var player_character_index := 0
var player_vehicle_index := 0
var ai_character_index := 2
var ai_vehicle_index := 1


var player_character: CharacterStats:
	get:
		return characters[player_character_index]

var player_vehicle: VehicleStats:
	get:
		return vehicles[player_vehicle_index]

var ai_character: CharacterStats:
	get:
		return characters[ai_character_index]

var ai_vehicle: VehicleStats:
	get:
		return vehicles[ai_vehicle_index]


func select_player_character(index: int) -> void:
	player_character_index = clampi(index, 0, characters.size() - 1)


func select_player_vehicle(index: int) -> void:
	player_vehicle_index = clampi(index, 0, vehicles.size() - 1)


func assign_ai_loadout() -> void:
	# Offset from the player's picks so every race demonstrates a different
	# stat profile while still varying between sessions.
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	ai_character_index = (player_character_index + rng.randi_range(1, characters.size() - 1)) % characters.size()
	ai_vehicle_index = (player_vehicle_index + rng.randi_range(1, vehicles.size() - 1)) % vehicles.size()

