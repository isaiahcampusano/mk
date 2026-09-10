extends Node

const Main = preload("res://main.gd")


func _ready() -> void:
	var race := Main.new()
	add_child(race)
	freeze(race)
	test_geometry(race)
	test_grid(race)
	test_items(race)
	test_recovery(race)
	await test_restart(race)
	race.free()
	print("Circuit geometry, grid, item, recovery, and restart tests passed")
	get_tree().quit()


func freeze(race) -> void:
	race.set_physics_process(false)
	for kart in race.karts:
		kart.set_physics_process(false)


func test_geometry(race) -> void:
	assert(race.validate_track_geometry().is_empty())
	assert(race.track_points[0] != race.track_points[-1])
	var ground := race.get_node("GrassGround") as MeshInstance3D
	var collider := race.get_node("GroundCollider").get_child(0) as CollisionShape3D
	assert(ground.mesh.size == collider.shape.size)
	assert(ground.position == collider.position)
	for offset in [-Main.WALL_OFFSET - Main.WALL_THICKNESS, Main.WALL_OFFSET + Main.WALL_THICKNESS]:
		for point in race.get_offset_loop(offset):
			assert(race.world_rect.has_point(Vector2(point.x, point.z)))
	var inner: PackedVector3Array = race.get_offset_loop(-Main.ROAD_HALF_WIDTH)
	var outer: PackedVector3Array = race.get_offset_loop(Main.ROAD_HALF_WIDTH)
	for i in race.track_points.size():
		var tangent: Vector3 = (race.track_points[(i + 1) % race.track_points.size()] - race.track_points[i]).normalized()
		assert(is_equal_approx((outer[i] - inner[i]).dot(race.planar_normal(tangent)), 200.0), "Every segment must preserve its 200-unit road width")
	# Test camera fitting at both normal and narrow viewport sizes using a real viewport.
	var viewport := SubViewport.new()
	add_child(viewport)
	var original_parent: Node = race.get_parent()
	race.reparent(viewport)
	for size in [Vector2i(1280, 720), Vector2i(720, 900)]:
		viewport.size = size
		race.fit_debug_camera()
		for point in inner + outer:
			assert(race.debug_camera.is_position_in_frustum(point), "Overview must show all road boundaries")
	race.reparent(original_parent)
	viewport.free()
	race.fit_debug_camera()
	var original: PackedVector3Array = race.track_points.duplicate()
	race.track_points[1] = race.track_points[0]
	assert(not race.validate_track_geometry().is_empty(), "Duplicate/short segments must fail validation")
	race.track_points = original
	race.race_manager.configure(original, Main.TOTAL_LAPS, Main.CHECKPOINT_RADIUS)
	assert(race.track_position(-1).is_equal_approx(race.track_points[-1]))
	assert(race.track_tangent(-1).is_equal_approx(race.track_tangent(race.track_points.size() - 1)))


func test_grid(race) -> void:
	var tangent: Vector3 = race.track_tangent(0)
	var normal: Vector3 = race.planar_normal(tangent)
	for i in 6:
		var kart = race.karts[i]
		assert(kart.position.is_equal_approx(race.grid_position(i)))
		assert(kart.forward_vector().is_equal_approx(tangent))
		var relative: Vector3 = kart.position - race.track_points[0]
		assert(is_equal_approx(relative.dot(tangent), -115.0 if i < 3 else -55.0))
		assert(is_equal_approx(relative.dot(normal), [-50.0, 0.0, 50.0][i % 3]))
		assert(relative.dot(tangent) + 25.0 < -15.0, "Full body must be behind the checkered line")
		assert(absf(relative.dot(normal)) + 20.0 < Main.ROAD_HALF_WIDTH)
		assert(kart.race_position == (i + 4 if i < 3 else i - 2))
		for j in range(i + 1, 6):
			var delta: Vector3 = race.karts[j].position - kart.position
			assert(absf(delta.dot(tangent)) >= 50.0 or absf(delta.dot(normal)) >= 40.0, "Kart footprints must not overlap")
	assert(race.track_points[-1].z == 0.0 and race.track_points[-2].z == 0.0)
	assert(race.track_points[0].distance_to(race.track_points[-2]) >= 150.0)


func test_items(race) -> void:
	assert(race.item_boxes.size() == 30)
	for station in 10:
		for lane in 3:
			var box = race.item_boxes[station * 3 + lane]
			assert(box.station_id == station)
			assert(box.position.is_equal_approx(race.track_position(Main.ITEM_STATIONS[station], Main.ITEM_LANES[lane])))
			assert(race.distance_to_track(box.position) <= Main.ROAD_HALF_WIDTH - 25.0)
			assert(box.position.distance_to(race.track_points[0]) > 250.0)
	var first = race.item_boxes[0]
	var center = race.item_boxes[1]
	var player = race.player
	player.position = first.position
	race.process_race(0.0)
	assert(not first.available and center.available)
	assert(player.held_item == "MUSHROOM")
	player.position = center.position
	race.process_race(0.0)
	assert(center.available, "A held item must prevent collecting a second box")
	first.tick(5.9)
	assert(not first.available and center.available)
	first.tick(0.11)
	assert(first.available and first.visual_root.visible and not first.respawn_marker.visible)
	player.held_item = ""
	player.position = race.item_boxes[3].position
	race.process_race(0.0)
	assert(player.held_item == "BANANA", "Station identity must alternate item types")
	player.held_item = ""
	player.laps_completed = 1
	player.position = center.position
	race.process_race(0.0)
	assert(player.held_item == "BANANA", "Lap number must preserve item alternation")


func test_recovery(race) -> void:
	var kart = race.karts[2]
	kart.last_checkpoint = 20
	kart.next_checkpoint = 21
	kart.ai_waypoint = 5
	kart.position = Vector3(10000, 0, 10000)
	kart.current_speed = 200.0
	kart.velocity = Vector3(100, 0, 0)
	race.recover_kart(kart)
	assert(kart.ai_waypoint == 21 and kart.next_checkpoint == 21)
	assert(race.world_contains(kart.position) and race.distance_to_track(kart.position) < Main.ROAD_HALF_WIDTH)
	var tangent: Vector3 = (race.track_points[21] - race.track_points[20]).normalized()
	assert(kart.forward_vector().is_equal_approx(tangent))
	assert(kart.velocity == Vector3.ZERO and kart.current_speed == 0.0)
	assert(kart.controls_locked and kart.visible)


func test_restart(race) -> void:
	var old_karts: Array = race.karts.duplicate()
	var old_boxes: Array = race.item_boxes.duplicate()
	race.player.held_item = "BANANA"
	race.use_item(race.player)
	assert(race.bananas.size() == 1)
	var old_banana = race.bananas[0]
	race.start_race()
	freeze(race)
	await get_tree().process_frame
	for node in old_karts + old_boxes:
		assert(not is_instance_valid(node))
	assert(not is_instance_valid(old_banana))
	assert(race.karts.size() == 6 and race.item_boxes.size() == 30 and race.bananas.is_empty())
	assert(race.race_generation == 2 and race.race_manager.state == RaceManager.State.COUNTDOWN)
	test_grid(race)
	for kart in race.karts:
		assert(kart.held_item == "" and kart.laps_completed == 0 and not kart.has_crossed_start)
	for box in race.item_boxes:
		assert(box.available and box.cooldown == 0.0)
