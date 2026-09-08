extends Node

const RaceConfigScript = preload("res://RaceConfig.gd")
const CharacterSelectScript = preload("res://CharacterSelect.gd")
const VehicleSelectScript = preload("res://VehicleSelect.gd")
const MainSceneScript = preload("res://main.gd")


func _ready() -> void:
	var config = RaceConfigScript.new()
	assert(config.is_catalog_valid(), config.get_catalog_error())
	assert(config.characters.size() == 4, "The driver catalog must contain four entries")
	assert(config.vehicles.size() == 4, "The kart catalog must contain four entries")
	assert(_character_ids(config) == [&"bramble_knox", &"nova_reed", &"pip_spark", &"rook_ember"])
	assert(_vehicle_ids(config) == [&"comet", &"slidewinder", &"vortex_gt", &"zipbug"])

	var seen_character_ids: Dictionary = {}
	for character in config.characters:
		assert(character is CharacterStats)
		assert(character.character_id != &"")
		assert(not seen_character_ids.has(character.character_id))
		assert(character.portrait != null, "Every driver must have a portrait")
		seen_character_ids[character.character_id] = true
	var seen_vehicle_ids: Dictionary = {}
	for vehicle in config.vehicles:
		assert(vehicle is VehicleStats)
		assert(vehicle.vehicle_id != &"")
		assert(not seen_vehicle_ids.has(vehicle.vehicle_id))
		assert(vehicle.icon != null, "Every kart must have an icon")
		seen_vehicle_ids[vehicle.vehicle_id] = true

	assert(config.player_character.character_id == config.DEFAULT_CHARACTER_ID)
	assert(config.player_vehicle.vehicle_id == config.DEFAULT_VEHICLE_ID)
	config.player_character_index = 99
	config.player_vehicle_index = -99
	assert(config.player_character.character_id == config.DEFAULT_CHARACTER_ID, "Invalid driver selection must recover")
	assert(config.player_vehicle.vehicle_id == config.DEFAULT_VEHICLE_ID, "Invalid kart selection must recover")
	config.assign_ai_loadout()
	assert(config.ai_character_index >= 0 and config.ai_character_index < config.characters.size())
	assert(config.ai_vehicle_index >= 0 and config.ai_vehicle_index < config.vehicles.size())

	config.characters.clear()
	config.vehicles.clear()
	assert(not config.is_catalog_valid(), "An empty catalog must be invalid")
	assert(not config.get_catalog_error().is_empty(), "Invalid catalogs must explain the failure")
	assert(config.find_character(&"missing") == -1)
	assert(config.find_vehicle(&"missing") == -1)
	assert(config.player_character == null)
	assert(config.player_vehicle == null)
	config.select_player_character(0)
	config.select_player_vehicle(0)
	config.assign_ai_loadout()
	assert(config.ai_character_index == -1 and config.ai_vehicle_index == -1)

	config.free()
	await _test_invalid_catalog_screens()
	print("RaceConfig tests passed")
	get_tree().quit()


func _test_invalid_catalog_screens() -> void:
	RaceConfig.characters.clear()
	RaceConfig.vehicles.clear()

	var character_screen = CharacterSelectScript.new()
	add_child(character_screen)
	await get_tree().process_frame
	assert(character_screen.cards.is_empty())
	assert(character_screen.confirm_button.disabled)
	assert(character_screen.selection_label.text == "CONTENT ERROR")
	character_screen.confirm_selection()
	character_screen.free()

	var vehicle_screen = VehicleSelectScript.new()
	add_child(vehicle_screen)
	await get_tree().process_frame
	assert(vehicle_screen.cards.is_empty())
	assert(vehicle_screen.confirm_button.disabled)
	assert(vehicle_screen.selection_label.text == "CONTENT ERROR")
	vehicle_screen.confirm_selection()
	vehicle_screen.free()

	var race = MainSceneScript.new()
	add_child(race)
	await get_tree().process_frame
	assert(race.karts.is_empty(), "An invalid catalog must prevent race spawning")
	var has_error_layer := false
	for child in race.get_children():
		if child is CanvasLayer:
			has_error_layer = true
			break
	assert(has_error_layer, "A direct race launch must show a content error")
	race.free()

	RaceConfig.load_content_options()
	RaceConfig.player_character_index = RaceConfig.find_character(RaceConfig.DEFAULT_CHARACTER_ID)
	RaceConfig.player_vehicle_index = RaceConfig.find_vehicle(RaceConfig.DEFAULT_VEHICLE_ID)


func _character_ids(config: Node) -> Array[StringName]:
	var ids: Array[StringName] = []
	for character in config.characters:
		ids.append(character.character_id)
	return ids


func _vehicle_ids(config: Node) -> Array[StringName]:
	var ids: Array[StringName] = []
	for vehicle in config.vehicles:
		ids.append(vehicle.vehicle_id)
	return ids
