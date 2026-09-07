extends Node

const MainSceneScript = preload("res://main.gd")


func _ready() -> void:
	var race = MainSceneScript.new()
	assert(race.track_points.size() == 24, "The expanded track must contain 24 points")
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
	var ai_count := 0
	for kart in race.karts:
		if kart.is_ai:
			ai_count += 1
	assert(ai_count == 5, "A race must start with five AI karts")
	assert(race.item_boxes.size() == 10, "A race must start with ten item boxes")

	race.free()
	print("Main configuration tests passed")
	get_tree().quit()
