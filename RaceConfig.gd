extends Node

const DEFAULT_CHARACTER_ID := &"pip_spark"
const DEFAULT_VEHICLE_ID := &"comet"
const EXPECTED_CHARACTER_COUNT := 4
const EXPECTED_VEHICLE_COUNT := 4

const CHARACTER_CATALOG: Array[CharacterStats] = [
	preload("res://data/characters/bramble_knox.tres"),
	preload("res://data/characters/nova_reed.tres"),
	preload("res://data/characters/pip_spark.tres"),
	preload("res://data/characters/rook_ember.tres"),
]
const VEHICLE_CATALOG: Array[VehicleStats] = [
	preload("res://data/vehicles/comet.tres"),
	preload("res://data/vehicles/slidewinder.tres"),
	preload("res://data/vehicles/vortex_gt.tres"),
	preload("res://data/vehicles/zipbug.tres"),
]

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
	ai_character_index = mini(2, characters.size() - 1) if not characters.is_empty() else -1
	ai_vehicle_index = mini(1, vehicles.size() - 1) if not vehicles.is_empty() else -1
	var error := get_catalog_error()
	if not error.is_empty():
		push_error(error)


func load_content_options() -> void:
	characters.clear()
	vehicles.clear()
	characters.assign(CHARACTER_CATALOG)
	vehicles.assign(VEHICLE_CATALOG)


func is_catalog_valid() -> bool:
	return _catalog_errors().is_empty()


func get_catalog_error() -> String:
	var errors := _catalog_errors()
	if errors.is_empty():
		return ""
	return "Content failed to load: " + "; ".join(errors)


func _catalog_errors() -> Array[String]:
	var errors: Array[String] = []
	if characters.size() != EXPECTED_CHARACTER_COUNT:
		errors.append("expected %d drivers, found %d" % [EXPECTED_CHARACTER_COUNT, characters.size()])
	if vehicles.size() != EXPECTED_VEHICLE_COUNT:
		errors.append("expected %d karts, found %d" % [EXPECTED_VEHICLE_COUNT, vehicles.size()])

	var character_ids: Dictionary = {}
	for index in characters.size():
		var character := characters[index]
		if character == null:
			errors.append("driver %d is unavailable" % index)
			continue
		if character.character_id == &"":
			errors.append("driver %d has no ID" % index)
		elif character_ids.has(character.character_id):
			errors.append("duplicate driver ID '%s'" % character.character_id)
		else:
			character_ids[character.character_id] = true
		if character.character_name.strip_edges().is_empty():
			errors.append("driver '%s' has no name" % character.character_id)
		if character.portrait == null:
			errors.append("driver '%s' has no portrait" % character.character_id)

	var vehicle_ids: Dictionary = {}
	for index in vehicles.size():
		var vehicle := vehicles[index]
		if vehicle == null:
			errors.append("kart %d is unavailable" % index)
			continue
		if vehicle.vehicle_id == &"":
			errors.append("kart %d has no ID" % index)
		elif vehicle_ids.has(vehicle.vehicle_id):
			errors.append("duplicate kart ID '%s'" % vehicle.vehicle_id)
		else:
			vehicle_ids[vehicle.vehicle_id] = true
		if vehicle.vehicle_name.strip_edges().is_empty():
			errors.append("kart '%s' has no name" % vehicle.vehicle_id)
		if vehicle.icon == null:
			errors.append("kart '%s' has no icon" % vehicle.vehicle_id)

	if not character_ids.has(DEFAULT_CHARACTER_ID):
		errors.append("default driver '%s' is unavailable" % DEFAULT_CHARACTER_ID)
	if not vehicle_ids.has(DEFAULT_VEHICLE_ID):
		errors.append("default kart '%s' is unavailable" % DEFAULT_VEHICLE_ID)
	return errors


func find_character(character_id: StringName) -> int:
	for index in characters.size():
		if characters[index] != null and characters[index].character_id == character_id:
			return index
	if characters.is_empty():
		push_warning("Unknown driver '%s'; no fallback is available" % character_id)
		return -1
	push_warning("Unknown driver '%s'; using the first configured option" % character_id)
	return 0


func find_vehicle(vehicle_id: StringName) -> int:
	for index in vehicles.size():
		if vehicles[index] != null and vehicles[index].vehicle_id == vehicle_id:
			return index
	if vehicles.is_empty():
		push_warning("Unknown kart '%s'; no fallback is available" % vehicle_id)
		return -1
	push_warning("Unknown kart '%s'; using the first configured option" % vehicle_id)
	return 0


var player_character: CharacterStats:
	get:
		if characters.is_empty():
			push_warning("Player driver is unavailable because the catalog is empty")
			return null
		if player_character_index < 0 or player_character_index >= characters.size():
			push_warning("Player driver selection is invalid; using the default")
			player_character_index = find_character(DEFAULT_CHARACTER_ID)
		return characters[player_character_index] if player_character_index >= 0 else null

var player_vehicle: VehicleStats:
	get:
		if vehicles.is_empty():
			push_warning("Player kart is unavailable because the catalog is empty")
			return null
		if player_vehicle_index < 0 or player_vehicle_index >= vehicles.size():
			push_warning("Player kart selection is invalid; using the default")
			player_vehicle_index = find_vehicle(DEFAULT_VEHICLE_ID)
		return vehicles[player_vehicle_index] if player_vehicle_index >= 0 else null

var ai_character: CharacterStats:
	get:
		return characters[ai_character_index] if ai_character_index >= 0 and ai_character_index < characters.size() else null

var ai_vehicle: VehicleStats:
	get:
		return vehicles[ai_vehicle_index] if ai_vehicle_index >= 0 and ai_vehicle_index < vehicles.size() else null


func select_player_character(index: int) -> void:
	if not is_catalog_valid():
		return
	player_character_index = clampi(index, 0, characters.size() - 1)


func select_player_vehicle(index: int) -> void:
	if not is_catalog_valid():
		return
	player_vehicle_index = clampi(index, 0, vehicles.size() - 1)


func assign_ai_loadout() -> void:
	if not is_catalog_valid():
		ai_character_index = -1
		ai_vehicle_index = -1
		return
	# Offset from the player's picks so every race demonstrates a different
	# stat profile while still varying between sessions.
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	ai_character_index = (player_character_index + rng.randi_range(1, characters.size() - 1)) % characters.size() if characters.size() > 1 else 0
	ai_vehicle_index = (player_vehicle_index + rng.randi_range(1, vehicles.size() - 1)) % vehicles.size() if vehicles.size() > 1 else 0


func is_web_smoke_enabled() -> bool:
	if not OS.has_feature("web"):
		return false
	return bool(JavaScriptBridge.eval("new URLSearchParams(window.location.search).has('smoke_test')"))


func report_web_smoke(stage: String, details: Dictionary = {}) -> void:
	if not is_web_smoke_enabled():
		return
	var report := details.duplicate(true)
	report["stage"] = stage
	JavaScriptBridge.eval("window.__mkSmoke = %s;" % JSON.stringify(report), true)
