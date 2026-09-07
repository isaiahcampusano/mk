extends Node

const DEFAULT_CHARACTER_ID := &"pip_spark"
const DEFAULT_VEHICLE_ID := &"comet"

var characters: Array[CharacterStats] = []
var vehicles: Array[VehicleStats] = []

var player_character_index := 0
var player_vehicle_index := 0
var ai_character_index := 2
var ai_vehicle_index := 1


func _init() -> void:
	load_content_options()
	player_character_index = find_character(DEFAULT_CHARACTER_ID)
	player_vehicle_index = find_vehicle(DEFAULT_VEHICLE_ID)
	ai_character_index = mini(2, characters.size() - 1)
	ai_vehicle_index = mini(1, vehicles.size() - 1)


func load_content_options() -> void:
	characters.clear()
	vehicles.clear()
	for file_name in DirAccess.get_files_at("res://data/characters"):
		if file_name.ends_with(".tres"):
			var character := load("res://data/characters/" + file_name)
			if character is CharacterStats:
				characters.append(character)
	for file_name in DirAccess.get_files_at("res://data/vehicles"):
		if file_name.ends_with(".tres"):
			var vehicle := load("res://data/vehicles/" + file_name)
			if vehicle is VehicleStats:
				vehicles.append(vehicle)
	assert(not characters.is_empty(), "At least one CharacterStats resource is required")
	assert(not vehicles.is_empty(), "At least one VehicleStats resource is required")


func find_character(character_id: StringName) -> int:
	for index in characters.size():
		if characters[index].character_id == character_id:
			return index
	push_warning("Unknown character '%s'; using the first configured option" % character_id)
	return 0


func find_vehicle(vehicle_id: StringName) -> int:
	for index in vehicles.size():
		if vehicles[index].vehicle_id == vehicle_id:
			return index
	push_warning("Unknown vehicle '%s'; using the first configured option" % vehicle_id)
	return 0


var player_character: CharacterStats:
	get:
		if player_character_index < 0 or player_character_index >= characters.size():
			push_warning("Player character selection is invalid; using the default")
			player_character_index = find_character(DEFAULT_CHARACTER_ID)
		return characters[player_character_index]

var player_vehicle: VehicleStats:
	get:
		if player_vehicle_index < 0 or player_vehicle_index >= vehicles.size():
			push_warning("Player vehicle selection is invalid; using the default")
			player_vehicle_index = find_vehicle(DEFAULT_VEHICLE_ID)
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
	ai_character_index = (player_character_index + rng.randi_range(1, characters.size() - 1)) % characters.size() if characters.size() > 1 else 0
	ai_vehicle_index = (player_vehicle_index + rng.randi_range(1, vehicles.size() - 1)) % vehicles.size() if vehicles.size() > 1 else 0

