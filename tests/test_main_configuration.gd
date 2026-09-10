extends Node

const MainSceneScript = preload("res://main.gd")


func _ready() -> void:
	RaceConfig.select_player_character(RaceConfig.find_character(&"rook_ember"))
	RaceConfig.select_player_vehicle(RaceConfig.find_vehicle(&"slidewinder"))
	var race = MainSceneScript.new()
	assert(race.validate_track_geometry().is_empty(), "The technical circuit must have valid geometry")
	for index in race.track_points.size():
		var next: int = (index + 1) % race.track_points.size()
		var segment_length: float = race.track_points[index].distance_to(race.track_points[next])
		assert(
			segment_length > MainSceneScript.CHECKPOINT_RADIUS * RaceManager.CHECKPOINT_REARM_MULTIPLIER,
			"Track segment %d is too short for checkpoint re-arming" % index
		)

	var bounds: Rect2 = race.compute_world_rect(150.0)
	for point in race.track_points:
		assert(bounds.has_point(Vector2(point.x, point.z)), "World bounds must contain every track point")

	add_child(race)
	await get_tree().process_frame
	assert(race.karts.size() == 6, "A race must start with six karts")
	assert(is_instance_valid(race.player), "The player kart must be assigned")
	assert(not race.player.is_ai, "The player kart must use player controls")
	assert(race.player.character_stats.character_id == &"rook_ember", "The selected driver must reach the race")
	assert(race.player.vehicle_stats.vehicle_id == &"slidewinder", "The selected kart must reach the race")
	assert(race.player.body_color.is_equal_approx(race.player.vehicle_stats.primary_color), "The kart must use its configured primary color")
	assert(race.player.vehicle_stats.model_profile == 3, "Slidewinder must use the drift body profile")
	var body := race.player.visual_root.get_node("Body") as MeshInstance3D
	var driver := race.player.visual_root.get_node("Driver") as MeshInstance3D
	var body_mesh := body.mesh as BoxMesh
	var driver_mesh := driver.mesh as SphereMesh
	var body_material := body_mesh.material as StandardMaterial3D
	var driver_material := driver_mesh.material as StandardMaterial3D
	assert(body_mesh.size.is_equal_approx(Vector3(24.0, 6.0, 29.0)), "The model profile must change body geometry")
	assert(body_material.albedo_color.is_equal_approx(race.player.vehicle_stats.primary_color), "The body material must preserve the kart color")
	assert(driver_material.albedo_color.is_equal_approx(race.player.character_stats.driver_color), "The driver material must preserve the driver color")
	var expected_stats := KartStatsResolver.resolve(race.player.character_stats, race.player.vehicle_stats)
	assert(is_equal_approx(race.player.resolved_top_speed, expected_stats.top_speed))
	assert(is_equal_approx(race.player.resolved_acceleration, expected_stats.acceleration))
	assert(is_equal_approx(race.player.resolved_turn_rate, expected_stats.turn_rate))
	assert(is_equal_approx(race.player.resolved_drift_turn_rate, expected_stats.drift_turn_rate))
	assert(is_equal_approx(race.player.resolved_drift_min_speed, expected_stats.drift_min_speed))
	var ai_count := 0
	for kart in race.karts:
		if kart.is_ai:
			ai_count += 1
	assert(ai_count == 5, "A race must start with five AI karts")
	assert(race.item_boxes.size() == 30, "A race must start with thirty item boxes")

	race.free()
	print("Main configuration tests passed")
	get_tree().quit()
