extends Node3D

const TOTAL_LAPS := 3
const ROAD_HALF_WIDTH := 100.0
const WALL_OFFSET := 142.0
const CHECKPOINT_RADIUS := 92.0
const WALL_HEIGHT := 20.0
const WALL_THICKNESS := 7.0
const CAMERA_DISTANCE := 164.0
const CAMERA_HEIGHT := 88.0
const CAMERA_LOOK_AHEAD := 74.0
const CAMERA_POSITION_SMOOTH := 7.0
const CAMERA_ROTATION_SMOOTH := 9.0
const CAMERA_COLLISION_MARGIN := 8.0
const ITEM_LANES := [-40.0, 0.0, 40.0]
# Stable station order controls item alternation independently of waypoint indices.
# Start straight, first exit, esses exit, back straight, second exit, chicane exit,
# outer straight (two), outer climb, final straight.
const ITEM_STATIONS := [3, 10, 14, 17, 23, 30, 36, 41, 49, 55]
const GRID_LANES := [-50.0, 0.0, 50.0]
const POSITION_LABEL_HOME := Vector2(18.0, 46.0)

# Clockwise start hairpin, linked esses, counterclockwise hairpin, chicane, outer return.
var track_points := PackedVector3Array([
	Vector3(0.0, 0, 0.0), # 0
	Vector3(133.69, 0, 0.0), # 1
	Vector3(267.38, 0, 0.0), # 2
	Vector3(401.07, 0, 0.0), # 3
	Vector3(534.759, 0, 0.0), # 4
	Vector3(668.449, 0, 0.0), # 5
	Vector3(801.13, 0, 9.076), # 6
	Vector3(897.657, 0, 96.31), # 7
	Vector3(901.635, 0, 226.353), # 8
	Vector3(810.62, 0, 319.324), # 9
	Vector3(679.322, 0, 340.517), # 10
	Vector3(550.202, 0, 373.264), # 11
	Vector3(419.946, 0, 347.548), # 12
	Vector3(289.076, 0, 340.237), # 13
	Vector3(180.405, 0, 417.246), # 14
	Vector3(49.15, 0, 431.6), # 15
	Vector3(-84.54, 0, 431.6), # 16
	Vector3(-218.23, 0, 431.6), # 17
	Vector3(-351.92, 0, 431.6), # 18
	Vector3(-477.28, 0, 468.041), # 19
	Vector3(-538.823, 0, 582.671), # 20
	Vector3(-498.808, 0, 706.468), # 21
	Vector3(-381.816, 0, 763.388), # 22
	Vector3(-248.13, 0, 763.6), # 23
	Vector3(-114.44, 0, 763.6), # 24
	Vector3(19.25, 0, 763.6), # 25
	Vector3(152.774, 0, 766.247), # 26
	Vector3(275.052, 0, 819.184), # 27
	Vector3(402.12, 0, 805.616), # 28
	Vector3(513.737, 0, 733.692), # 29
	Vector3(642.384, 0, 757.703), # 30
	Vector3(729.99, 0, 855.624), # 31
	Vector3(741.219, 0, 986.534), # 32
	Vector3(671.567, 0, 1097.943), # 33
	Vector3(548.964, 0, 1145.182), # 34
	Vector3(415.277, 0, 1145.4), # 35
	Vector3(281.587, 0, 1145.4), # 36
	Vector3(147.898, 0, 1145.4), # 37
	Vector3(14.208, 0, 1145.4), # 38
	Vector3(-119.482, 0, 1145.4), # 39
	Vector3(-253.172, 0, 1145.4), # 40
	Vector3(-386.862, 0, 1145.4), # 41
	Vector3(-520.552, 0, 1145.4), # 42
	Vector3(-654.241, 0, 1145.4), # 43
	Vector3(-785.78, 0, 1129.239), # 44
	Vector3(-884.61, 0, 1042.662), # 45
	Vector3(-913.0, 0, 914.028), # 46
	Vector3(-913.0, 0, 780.339), # 47
	Vector3(-913.0, 0, 646.649), # 48
	Vector3(-913.0, 0, 512.959), # 49
	Vector3(-913.0, 0, 379.269), # 50
	Vector3(-913.0, 0, 245.579), # 51
	Vector3(-891.358, 0, 115.237), # 52
	Vector3(-798.683, 0, 22.101), # 53
	Vector3(-668.449, 0, 0.0), # 54
	Vector3(-534.759, 0, 0.0), # 55
	Vector3(-401.07, 0, 0.0), # 56
	Vector3(-267.38, 0, 0.0), # 57
	Vector3(-133.69, 0, 0.0), # 58
])

var world_rect: Rect2
var karts: Array[Kart] = []
var item_boxes: Array[ItemBox] = []
var bananas: Array[Banana] = []
var player: Kart
var race_manager := RaceManager.new()
var message_label: Label
var hud_panel: Panel
var lap_label: Label
var position_label: Label
var character_label: Label
var character_portrait: TextureRect
var item_frame: Panel
var item_icon: Label
var item_name_label: Label
var item_frame_style: StyleBoxFlat
var speed_bar: ProgressBar
var speed_label: Label
var speed_fill_style: StyleBoxFlat
var rival_status_label: Label
var timer_label: Label
var help_label: Label
var result_panel: Panel
var result_label: Label
var flash_text := ""
var flash_timer := 0.0
var last_held_item := ""
var last_laps_completed := 0
var last_race_position := 1
var item_pulse_tween: Tween
var lap_pulse_tween: Tween
var position_change_tween: Tween
var chase_camera: Camera3D
var debug_camera: Camera3D
var debug_camera_enabled := false
var race_generation := 0
var camera_look_point := Vector3.ZERO
var camera_forward_cache := Vector3.FORWARD


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#78c6df"))
	if not RaceConfig.is_catalog_valid():
		set_process(false)
		set_physics_process(false)
		set_process_input(false)
		build_content_error_ui()
		RaceConfig.report_web_smoke("content_error", {
			"catalog_valid": false,
			"error": RaceConfig.get_catalog_error(),
		})
		return
	var geometry_errors := validate_track_geometry()
	if not geometry_errors.is_empty():
		push_error("Invalid circuit: " + "; ".join(geometry_errors))
		set_physics_process(false)
		return
	world_rect = compute_world_rect(80.0)
	race_manager.configure(track_points, TOTAL_LAPS, CHECKPOINT_RADIUS)
	race_manager.race_ended.connect(finish_race)
	build_world_geometry()
	build_walls()
	build_cameras()
	build_ui()
	start_race()


func build_content_error_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var background := ColorRect.new()
	background.color = Color("#111829")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(background)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-360, -130)
	panel.size = Vector2(720, 260)
	panel.add_theme_stylebox_override("panel", make_panel_style(Color("#321c29"), Color("#ff6b7a"), 16, 2))
	background.add_child(panel)
	var message := Label.new()
	message.text = "CONTENT COULD NOT BE LOADED\n\nDriver and kart data is unavailable. Reload the game.\n\n" + RaceConfig.get_catalog_error()
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size", 22)
	message.add_theme_color_override("font_color", Color("#ffd8dc"))
	panel.add_child(message)


func compute_world_rect(margin: float) -> Rect2:
	var min_x := INF
	var max_x := -INF
	var min_z := INF
	var max_z := -INF
	for point in get_offset_loop(-WALL_OFFSET - WALL_THICKNESS * 0.5) + get_offset_loop(WALL_OFFSET + WALL_THICKNESS * 0.5):
		min_x = minf(min_x, point.x)
		max_x = maxf(max_x, point.x)
		min_z = minf(min_z, point.z)
		max_z = maxf(max_z, point.z)
	return Rect2(min_x - margin, min_z - margin, (max_x - min_x) + 2.0 * margin, (max_z - min_z) + 2.0 * margin)


func start_race() -> void:
	if not RaceConfig.is_catalog_valid():
		push_error("Race cannot start: " + RaceConfig.get_catalog_error())
		return
	race_generation += 1
	for kart in karts:
		kart.queue_free()
	for box in item_boxes:
		box.queue_free()
	for banana in bananas:
		if is_instance_valid(banana):
			banana.queue_free()
	karts.clear()
	item_boxes.clear()
	bananas.clear()

	var start_tangent := track_tangent(0)
	var start_heading := heading_from_direction(start_tangent)
	var fallback_colors := [
		Color("#ef3f47"), Color("#3e70ff"), Color("#52e84a"),
		Color("#f7cf3c"), Color("#ff7a3d"), Color("#c46cff"),
	]
	for index in 6:
		var is_player := index == 0
		var character: CharacterStats
		var vehicle: VehicleStats
		if is_player:
			character = RaceConfig.player_character
			vehicle = RaceConfig.player_vehicle
		else:
			var ai_offset := index - 1
			character = RaceConfig.characters[(RaceConfig.ai_character_index + ai_offset) % RaceConfig.characters.size()]
			vehicle = RaceConfig.vehicles[(RaceConfig.ai_vehicle_index + ai_offset) % RaceConfig.vehicles.size()]
		var spawn_pos := grid_position(index)
		var kart := create_kart(
			"PLAYER" if is_player else "COM %d" % index,
			spawn_pos,
			start_heading,
			fallback_colors[index],
			not is_player,
			character,
			vehicle
		)
		if is_player:
			player = kart

	for station_id in ITEM_STATIONS.size():
		var index: int = ITEM_STATIONS[station_id]
		for lane in ITEM_LANES:
			var box := ItemBox.new()
			box.position = track_position(index, lane)
			box.track_index = index
			box.station_id = station_id
			add_child(box)
			item_boxes.append(box)

	race_manager.start_race(karts)
	result_panel.visible = false
	message_label.visible = true
	flash_text = ""
	flash_timer = 0.0
	last_held_item = ""
	last_laps_completed = 0
	last_race_position = player.race_position
	reset_hud_feedback()
	update_item_slot("")
	reset_chase_camera()
	report_web_smoke()


func report_web_smoke() -> void:
	if not RaceConfig.is_web_smoke_enabled():
		return
	if not is_instance_valid(player):
		RaceConfig.report_web_smoke("race_error", {"error": "Player kart was not created"})
		return
	var body := player.visual_root.get_node_or_null("Body") as MeshInstance3D
	var driver := player.visual_root.get_node_or_null("Driver") as MeshInstance3D
	var body_mesh := body.mesh as BoxMesh if body != null else null
	var driver_mesh := driver.mesh as SphereMesh if driver != null else null
	var body_material := body_mesh.material as StandardMaterial3D if body_mesh != null else null
	var driver_material := driver_mesh.material as StandardMaterial3D if driver_mesh != null else null
	RaceConfig.report_web_smoke("race", {
		"catalog_valid": RaceConfig.is_catalog_valid(),
		"kart_count": karts.size(),
		"item_count": item_boxes.size(),
		"grid_rows": 2,
		"grid_columns": 3,
		"track_length": race_manager.track_length,
		"race_state": race_manager.state,
		"race_generation": race_generation,
		"player_position": [player.position.x, player.position.y, player.position.z],
		"character_id": String(player.character_stats.character_id),
		"vehicle_id": String(player.vehicle_stats.vehicle_id),
		"model_profile": player.vehicle_stats.model_profile,
		"body_size": [body_mesh.size.x, body_mesh.size.y, body_mesh.size.z] if body_mesh != null else [],
		"body_color": body_material.albedo_color.to_html(true) if body_material != null else "",
		"driver_color": driver_material.albedo_color.to_html(true) if driver_material != null else "",
		"top_speed": player.resolved_top_speed,
		"acceleration": player.resolved_acceleration,
		"turn_rate": player.resolved_turn_rate,
		"drift_turn_rate": player.resolved_drift_turn_rate,
		"drift_min_speed": player.resolved_drift_min_speed,
	})


func create_kart(kart_name: String, spawn: Vector3, heading: float, color: Color, ai: bool, character: CharacterStats, vehicle: VehicleStats) -> Kart:
	var kart := Kart.new()
	kart.kart_name = kart_name
	kart.position = spawn
	kart.rotation.y = heading
	kart.body_color = vehicle.primary_color if vehicle != null else color
	kart.is_ai = ai
	kart.configure_loadout(character, vehicle)
	kart.track = track_points
	kart.track_width = ROAD_HALF_WIDTH
	kart.next_checkpoint = 1
	kart.last_checkpoint = 0
	kart.ai_waypoint = 1
	add_child(kart)
	karts.append(kart)
	return kart


func build_world_geometry() -> void:
	build_ground()
	build_track_ribbons()
	build_lane_markings()
	build_finish_line()
	build_grid_markings()
	build_checkpoint_markers()


func build_ground() -> void:
	var ground_material := make_unshaded_material(Color("#4b9636"))
	var ground_mesh := BoxMesh.new()
	ground_mesh.size = Vector3(world_rect.size.x, 1.0, world_rect.size.y)
	ground_mesh.material = ground_material
	var ground_visual := MeshInstance3D.new()
	ground_visual.name = "GrassGround"
	ground_visual.mesh = ground_mesh
	ground_visual.position = Vector3(world_rect.get_center().x, -0.55, world_rect.get_center().y)
	add_child(ground_visual)

	var floor_body := StaticBody3D.new()
	floor_body.name = "GroundCollider"
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	var floor_collision := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = ground_mesh.size
	floor_collision.shape = floor_shape
	floor_collision.position = Vector3(world_rect.get_center().x, -0.55, world_rect.get_center().y)
	floor_body.add_child(floor_collision)
	add_child(floor_body)


func build_track_ribbons() -> void:
	var shoulder_surface := SurfaceTool.new()
	shoulder_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	shoulder_surface.set_material(make_unshaded_material(Color("#b48a55")))
	var road_surface := SurfaceTool.new()
	road_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	road_surface.set_material(make_unshaded_material(Color("#2d3138")))

	var inner_wall := get_offset_loop(-WALL_OFFSET)
	var inner_road := get_offset_loop(-ROAD_HALF_WIDTH)
	var outer_road := get_offset_loop(ROAD_HALF_WIDTH)
	var outer_wall := get_offset_loop(WALL_OFFSET)
	for i in track_points.size():
		var next := (i + 1) % track_points.size()
		append_quad(shoulder_surface, inner_wall[i], inner_wall[next], inner_road[next], inner_road[i], 0.01)
		append_quad(road_surface, inner_road[i], inner_road[next], outer_road[next], outer_road[i], 0.03)
		append_quad(shoulder_surface, outer_road[i], outer_road[next], outer_wall[next], outer_wall[i], 0.01)

	var shoulder := MeshInstance3D.new()
	shoulder.name = "DirtShoulders"
	shoulder.mesh = shoulder_surface.commit()
	add_child(shoulder)
	var road := MeshInstance3D.new()
	road.name = "AsphaltRoad"
	road.mesh = road_surface.commit()
	add_child(road)


func build_lane_markings() -> void:
	var edge_material := make_unshaded_material(Color("#e8dfb9"))
	var dash_material := make_unshaded_material(Color(1.0, 1.0, 1.0, 0.42))
	for i in track_points.size():
		var a := track_points[i]
		var b := track_points[(i + 1) % track_points.size()]
		var direction := (b - a).normalized()
		var length := a.distance_to(b)
		var heading := heading_from_direction(direction)
		add_box_visual("LaneEdge", Vector3(4.0, 0.12, length), edge_material, (a + b) * 0.5 + Vector3.UP * 0.10, heading)
		var cursor := 18.0
		while cursor < length:
			var dash_length: float = minf(16.0, length - cursor)
			var center: Vector3 = a + direction * (cursor + dash_length * 0.5) + Vector3.UP * 0.18
			add_box_visual("LaneDash", Vector3(2.0, 0.10, dash_length), dash_material, center, heading)
			cursor += 34.0


func build_finish_line() -> void:
	var white := make_unshaded_material(Color.WHITE)
	var black := make_unshaded_material(Color("#15171c"))
	var tangent := track_tangent(0)
	var heading := heading_from_direction(tangent)
	for lane in 10:
		for row in 2:
			var center := track_position(0, (lane - 4.5) * 20.0) + tangent * (row - 0.5) * 15.0 + Vector3.UP * 0.24
			add_box_visual("FinishTile", Vector3(20.0, 0.14, 15.0), white if (lane + row) % 2 == 0 else black, center, heading)


func build_grid_markings() -> void:
	var paint := make_unshaded_material(Color("#fff0bf"))
	var tangent := track_tangent(0)
	var normal := planar_normal(tangent)
	var heading := heading_from_direction(tangent)
	for index in 6:
		var center := grid_position(index) + Vector3.UP * 0.22
		for side in [-1.0, 1.0]:
			add_box_visual("GridSide", Vector3(2, 0.12, 44), paint, center + normal * side * 19.0, heading)
		add_box_visual("GridFront", Vector3(40, 0.12, 2), paint, center + tangent * 22.0, heading)


func build_checkpoint_markers() -> void:
	var marker_material := make_unshaded_material(Color(0.2, 0.9, 1.0, 0.52))
	for i in track_points.size():
		if i == 0:
			continue
		var mesh := CylinderMesh.new()
		mesh.top_radius = 7.0
		mesh.bottom_radius = 7.0
		mesh.height = 0.35
		mesh.radial_segments = 12
		mesh.material = marker_material
		var marker := MeshInstance3D.new()
		marker.name = "Checkpoint%02d" % i
		marker.mesh = mesh
		marker.position = track_points[i] + Vector3.UP * 0.25
		add_child(marker)


func build_walls() -> void:
	var wall_body := StaticBody3D.new()
	wall_body.collision_layer = 1
	wall_body.collision_mask = 0
	wall_body.name = "TrackWalls"
	add_child(wall_body)
	var inner := get_offset_loop(-WALL_OFFSET)
	var outer := get_offset_loop(WALL_OFFSET)
	var wall_blue := make_unshaded_material(Color("#2f6573"))
	var wall_cream := make_unshaded_material(Color("#e9d79b"))
	for loop_index in 2:
		var loop := inner if loop_index == 0 else outer
		for i in loop.size():
			var a := loop[i]
			var b := loop[(i + 1) % loop.size()]
			var direction := (b - a).normalized()
			var length := a.distance_to(b)
			var midpoint := (a + b) * 0.5 + Vector3.UP * (WALL_HEIGHT * 0.5)
			var heading := heading_from_direction(direction)

			var shape_node := CollisionShape3D.new()
			var shape := BoxShape3D.new()
			shape.size = Vector3(WALL_THICKNESS, WALL_HEIGHT, length)
			shape_node.shape = shape
			shape_node.position = midpoint
			shape_node.rotation.y = heading
			wall_body.add_child(shape_node)

			var wall_mesh := BoxMesh.new()
			wall_mesh.size = Vector3(WALL_THICKNESS, 12.0, length)
			wall_mesh.material = wall_blue if (i + loop_index) % 2 == 0 else wall_cream
			var wall_visual := MeshInstance3D.new()
			wall_visual.name = "WallVisual"
			wall_visual.mesh = wall_mesh
			wall_visual.position = Vector3(midpoint.x, 6.0, midpoint.z)
			wall_visual.rotation.y = heading
			wall_body.add_child(wall_visual)


func track_tangent(index: int) -> Vector3:
	var count := track_points.size()
	var current := track_points[posmod(index, count)]
	var incoming := (current - track_points[posmod(index - 1, count)]).normalized()
	var outgoing := (track_points[posmod(index + 1, count)] - current).normalized()
	return (incoming + outgoing).normalized()


func track_position(index: int, lateral: float = 0.0) -> Vector3:
	return track_points[posmod(index, track_points.size())] + planar_normal(track_tangent(index)) * lateral


func grid_position(index: int) -> Vector3:
	var behind := 115.0 if index < 3 else 55.0
	return track_position(0, GRID_LANES[index % 3]) - track_tangent(0) * behind


func get_offset_loop(distance: float) -> PackedVector3Array:
	var result := PackedVector3Array()
	for i in track_points.size():
		var outgoing := (track_points[(i + 1) % track_points.size()] - track_points[i]).normalized()
		var normal := planar_normal(track_tangent(i))
		# Miter intersections preserve the full road width along each segment.
		var denominator := maxf(0.01, normal.dot(planar_normal(outgoing)))
		result.append(track_points[i] + normal * distance / denominator)
	return result


func validate_track_geometry() -> PackedStringArray:
	var errors := PackedStringArray()
	var count := track_points.size()
	if count < 3:
		errors.append("At least three distinct track points are required")
		return errors
	var length := 0.0
	for i in count:
		var segment := track_points[i].distance_to(track_points[(i + 1) % count])
		length += segment
		if segment < 120.0 or not is_zero_approx(track_points[i].y):
			errors.append("Invalid flat checkpoint segment %d" % i)
	if length < 7000.0 or length > 8000.0:
		errors.append("Circuit length must be 7000–8000 units")
	var loops: Array[PackedVector3Array] = []
	for offset in [-WALL_OFFSET - WALL_THICKNESS * 0.5, -ROAD_HALF_WIDTH, ROAD_HALF_WIDTH, WALL_OFFSET + WALL_THICKNESS * 0.5]:
		loops.append(get_offset_loop(offset))
	for a in loops.size():
		for b in range(a, loops.size()):
			for i in count:
				for j in count:
					if a == b and (j <= i or j == (i + 1) % count or i == (j + 1) % count):
						continue
					var p := loops[a][i]
					var q := loops[a][(i + 1) % count]
					var r := loops[b][j]
					var t := loops[b][(j + 1) % count]
					if Geometry2D.segment_intersects_segment(Vector2(p.x, p.z), Vector2(q.x, q.z), Vector2(r.x, r.z), Vector2(t.x, t.z)) != null:
						errors.append("Intersecting boundaries %d/%d at %d/%d" % [a, b, i, j])
	for band in range(loops.size() - 1):
		for i in count:
			var next := (i + 1) % count
			var a := loops[band][i]
			var b := loops[band][next]
			var c := loops[band + 1][next]
			var d := loops[band + 1][i]
			if (b - a).cross(c - a).y >= -0.01 or (c - a).cross(d - a).y >= -0.01:
				errors.append("Folded track ribbon at %d" % i)
	return errors


func planar_normal(tangent: Vector3) -> Vector3:
	return Vector3(-tangent.z, 0.0, tangent.x)


func heading_from_direction(direction: Vector3) -> float:
	return atan2(direction.x, direction.z)


func append_quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, y_offset: float) -> void:
	for vertex in [a, b, c, a, c, d]:
		surface.set_normal(Vector3.UP)
		surface.add_vertex(vertex + Vector3.UP * y_offset)


func make_unshaded_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return material


func add_box_visual(node_name: String, size: Vector3, material: Material, position_3d: Vector3, heading: float) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material
	var instance := MeshInstance3D.new()
	instance.name = node_name
	instance.mesh = mesh
	instance.position = position_3d
	instance.rotation.y = heading
	add_child(instance)
	return instance


func build_cameras() -> void:
	chase_camera = Camera3D.new()
	chase_camera.name = "ChaseCamera"
	chase_camera.fov = 58.0
	chase_camera.near = 0.5
	chase_camera.far = 3000.0
	chase_camera.current = true
	add_child(chase_camera)

	debug_camera = Camera3D.new()
	debug_camera.name = "DebugTopDownCamera"
	debug_camera.position = Vector3.ZERO
	debug_camera.rotation.x = -PI * 0.5
	debug_camera.fov = 68.0
	debug_camera.near = 1.0
	debug_camera.far = 3000.0
	debug_camera.current = false
	add_child(debug_camera)
	fit_debug_camera()
	get_viewport().size_changed.connect(fit_debug_camera)


func fit_debug_camera() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var aspect := viewport_size.x / maxf(1.0, viewport_size.y)
	var half_height := maxf(world_rect.size.y * 0.5, world_rect.size.x * 0.5 / aspect)
	var altitude := half_height * 1.08 / tan(deg_to_rad(debug_camera.fov * 0.5))
	var center := world_rect.get_center()
	debug_camera.position = Vector3(center.x, altitude, center.y)
	debug_camera.far = altitude + world_rect.size.length()


func reset_chase_camera() -> void:
	if not is_instance_valid(player) or not is_instance_valid(chase_camera):
		return
	var forward := player.forward_vector()
	camera_forward_cache = forward
	camera_look_point = player.global_position + Vector3.UP * 13.0 + forward * CAMERA_LOOK_AHEAD
	chase_camera.global_position = player.global_position - forward * CAMERA_DISTANCE + Vector3.UP * CAMERA_HEIGHT
	chase_camera.look_at(camera_look_point, Vector3.UP)


func update_chase_camera(delta: float) -> void:
	if not is_instance_valid(player) or not is_instance_valid(chase_camera):
		return
	if player.spin_timer <= 0.0:
		camera_forward_cache = player.forward_vector()
	var forward := camera_forward_cache
	var anchor := player.global_position + Vector3.UP * 15.0
	var desired_position := player.global_position - forward * CAMERA_DISTANCE + Vector3.UP * CAMERA_HEIGHT
	var ray_query := PhysicsRayQueryParameters3D.create(anchor, desired_position, 1, [player.get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(ray_query)
	if not hit.is_empty():
		desired_position = hit.position + (anchor - hit.position).normalized() * CAMERA_COLLISION_MARGIN

	var position_weight := 1.0 - exp(-CAMERA_POSITION_SMOOTH * delta)
	var rotation_weight := 1.0 - exp(-CAMERA_ROTATION_SMOOTH * delta)
	chase_camera.global_position = chase_camera.global_position.lerp(desired_position, position_weight)
	var desired_look := player.global_position + Vector3.UP * 13.0 + forward * CAMERA_LOOK_AHEAD
	camera_look_point = camera_look_point.lerp(desired_look, rotation_weight)
	var look_direction := (camera_look_point - chase_camera.global_position).normalized()
	if look_direction.length_squared() > 0.001:
		var desired_basis := Basis.looking_at(look_direction, Vector3.UP)
		var smooth_rotation := Quaternion(chase_camera.global_basis).slerp(Quaternion(desired_basis), rotation_weight)
		chase_camera.global_basis = Basis(smooth_rotation).orthonormalized()


func toggle_debug_camera() -> void:
	debug_camera_enabled = not debug_camera_enabled
	debug_camera.current = debug_camera_enabled
	chase_camera.current = not debug_camera_enabled
	if not debug_camera_enabled:
		reset_chase_camera()


func build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var hud_root := Control.new()
	hud_root.name = "HUDRoot"
	hud_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(hud_root)

	hud_panel = Panel.new()
	hud_panel.name = "RaceHUD"
	hud_panel.position = Vector2(18, 16)
	hud_panel.size = Vector2(430, 214)
	hud_panel.add_theme_stylebox_override("panel", make_panel_style(Color(0.025, 0.055, 0.09, 0.9), Color(0.45, 0.72, 0.92, 0.7), 16, 2))
	hud_root.add_child(hud_panel)

	var player_stripe := ColorRect.new()
	player_stripe.position = Vector2(0, 18)
	player_stripe.size = Vector2(6, 178)
	player_stripe.color = Color("#ef3f47")
	player_stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_panel.add_child(player_stripe)

	lap_label = make_label(Vector2(18, 10), 26, Color.WHITE)
	lap_label.size = Vector2(300, 36)
	lap_label.text = "🏁  LAP  1 / %d" % TOTAL_LAPS
	hud_panel.add_child(lap_label)

	position_label = make_label(POSITION_LABEL_HOME, 26, Color("#ffd548"))
	position_label.size = Vector2(300, 36)
	position_label.text = "🏆  1st"
	hud_panel.add_child(position_label)

	character_label = make_label(Vector2(18, 84), 16, Color("#75f0c8"))
	character_label.size = Vector2(305, 27)
	hud_panel.add_child(character_label)

	var portrait_frame := Panel.new()
	portrait_frame.position = Vector2(338, 17)
	portrait_frame.size = Vector2(74, 78)
	portrait_frame.add_theme_stylebox_override("panel", make_panel_style(Color(0.055, 0.08, 0.12, 0.96), Color("#ef3f47"), 12, 2))
	hud_panel.add_child(portrait_frame)
	character_portrait = TextureRect.new()
	character_portrait.position = Vector2(7, 7)
	character_portrait.size = Vector2(60, 64)
	character_portrait.texture = RaceConfig.player_character.portrait
	character_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	character_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_frame.add_child(character_portrait)

	item_frame = Panel.new()
	item_frame.name = "ItemSlot"
	item_frame.position = Vector2(18, 120)
	item_frame.size = Vector2(194, 70)
	item_frame.pivot_offset = item_frame.size * 0.5
	item_frame_style = make_panel_style(Color(0.12, 0.15, 0.19, 0.96), Color(0.5, 0.58, 0.67, 0.78), 12, 2)
	item_frame.add_theme_stylebox_override("panel", item_frame_style)
	hud_panel.add_child(item_frame)

	item_icon = make_label(Vector2(7, 7), 34, Color.WHITE)
	item_icon.size = Vector2(52, 56)
	item_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item_frame.add_child(item_icon)
	item_name_label = make_label(Vector2(66, 9), 16, Color("#dcecff"))
	item_name_label.size = Vector2(118, 52)
	item_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item_frame.add_child(item_name_label)

	speed_label = make_label(Vector2(230, 118), 15, Color("#b9d9f4"))
	speed_label.size = Vector2(182, 24)
	hud_panel.add_child(speed_label)
	speed_bar = ProgressBar.new()
	speed_bar.name = "SpeedBar"
	speed_bar.position = Vector2(230, 144)
	speed_bar.size = Vector2(182, 18)
	speed_bar.min_value = 0.0
	speed_bar.max_value = 100.0
	speed_bar.show_percentage = false
	speed_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	speed_bar.add_theme_stylebox_override("background", make_panel_style(Color(0.025, 0.04, 0.06, 0.9), Color(0.22, 0.34, 0.45, 0.8), 8, 1))
	speed_fill_style = make_panel_style(Color("#3f8cff"), Color.TRANSPARENT, 8, 0)
	speed_bar.add_theme_stylebox_override("fill", speed_fill_style)
	hud_panel.add_child(speed_bar)

	rival_status_label = make_label(Vector2(230, 170), 14, Color("#79a2ff"))
	rival_status_label.size = Vector2(190, 25)
	hud_panel.add_child(rival_status_label)

	var timer_panel := Panel.new()
	timer_panel.name = "TimerPanel"
	timer_panel.anchor_left = 1.0
	timer_panel.anchor_right = 1.0
	timer_panel.offset_left = -218.0
	timer_panel.offset_right = -18.0
	timer_panel.offset_top = 16.0
	timer_panel.offset_bottom = 78.0
	timer_panel.add_theme_stylebox_override("panel", make_panel_style(Color(0.025, 0.055, 0.09, 0.9), Color(0.45, 0.72, 0.92, 0.7), 14, 2))
	hud_root.add_child(timer_panel)
	timer_label = make_label(Vector2(12, 8), 22, Color.WHITE)
	timer_label.size = Vector2(176, 46)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	timer_panel.add_child(timer_label)

	help_label = make_label(Vector2.ZERO, 15, Color(1, 1, 1, 0.9))
	help_label.anchor_top = 1.0
	help_label.anchor_right = 1.0
	help_label.anchor_bottom = 1.0
	help_label.offset_left = 20.0
	help_label.offset_right = -20.0
	help_label.offset_top = -38.0
	help_label.offset_bottom = -10.0
	help_label.text = "WASD / ARROWS drive   X hop   SHIFT drift   SPACE item   F3 camera   R restart"
	help_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	help_label.add_theme_constant_override("shadow_offset_x", 2)
	help_label.add_theme_constant_override("shadow_offset_y", 2)
	hud_root.add_child(help_label)

	message_label = make_label(Vector2.ZERO, 64, Color.WHITE)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	message_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	message_label.add_theme_constant_override("shadow_offset_x", 4)
	message_label.add_theme_constant_override("shadow_offset_y", 4)
	hud_root.add_child(message_label)

	result_panel = Panel.new()
	result_panel.name = "ResultPanel"
	result_panel.anchor_left = 0.5
	result_panel.anchor_top = 0.5
	result_panel.anchor_right = 0.5
	result_panel.anchor_bottom = 0.5
	result_panel.offset_left = -350.0
	result_panel.offset_top = -210.0
	result_panel.offset_right = 350.0
	result_panel.offset_bottom = 210.0
	result_panel.add_theme_stylebox_override("panel", make_panel_style(Color(0.025, 0.03, 0.055, 0.96), Color(0.45, 0.72, 0.92, 0.8), 22, 2))
	hud_root.add_child(result_panel)
	result_label = make_label(Vector2(20, 25), 30, Color.WHITE)
	result_label.size = Vector2(660, 370)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_panel.add_child(result_label)
	update_item_slot("")


func make_label(pos: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = pos
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func make_panel_style(background: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0, 0, 0, 0.32)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 3)
	return style


func _process(delta: float) -> void:
	update_chase_camera(delta)


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("toggle_camera"):
		toggle_debug_camera()
	if race_manager.state == RaceManager.State.FINISHED and Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://CharacterSelect.tscn")
		return
	if Input.is_action_just_pressed("restart"):
		start_race()
		return

	match race_manager.state:
		RaceManager.State.COUNTDOWN:
			for kart in karts:
				kart.controls_locked = true
			race_manager.advance(delta)
			if race_manager.state == RaceManager.State.RACING:
				for kart in karts:
					kart.controls_locked = false
				flash("GO!", 1.0)
		RaceManager.State.RACING:
			race_manager.advance(delta)
			process_race(delta)
		RaceManager.State.FINISHED:
			for kart in karts:
				kart.controls_locked = true

	update_hud(delta)


func process_race(delta: float) -> void:
	for box in item_boxes:
		box.tick(delta)
		if not box.available:
			continue
		for kart in karts:
			if kart.held_item == "" and kart.position.distance_to(box.position) < 35.0:
				kart.held_item = "MUSHROOM" if (box.station_id + kart.laps_completed) % 2 == 0 else "BANANA"
				box.collect()
				if kart == player:
					flash("ITEM: " + kart.held_item, 0.8)
					pulse_item_frame()
				break

	for kart in karts:
		kart.off_track = distance_to_track(kart.position) > ROAD_HALF_WIDTH
		var checkpoint_result := race_manager.register_checkpoint(kart)
		if checkpoint_result == RaceManager.CheckpointResult.LAP_COMPLETED and kart == player:
			flash("LAP %d / %d" % [kart.laps_completed + 1, TOTAL_LAPS], 1.2)
		elif checkpoint_result == RaceManager.CheckpointResult.RACER_FINISHED:
			kart.controls_locked = true
		if not world_contains(kart.position) or distance_to_track(kart.position) > WALL_OFFSET + 70.0:
			start_recovery(kart)

		if kart.wants_to_use_item and kart.held_item != "":
			use_item(kart)
		kart.wants_to_use_item = false

	for banana in bananas.duplicate():
		if not is_instance_valid(banana):
			bananas.erase(banana)
			continue
		banana.life -= delta
		if banana.life <= 0.0:
			bananas.erase(banana)
			banana.queue_free()
			continue
		for kart in karts:
			if banana.owner_kart == kart and banana.grace > 0.0:
				continue
			if kart.position.distance_to(banana.position) < 26.0 and kart.spin_timer <= 0.0:
				kart.spin_timer = 1.15
				kart.current_speed *= 0.35
				if kart == player:
					flash("SPIN OUT!", 0.8)
				bananas.erase(banana)
				banana.queue_free()
				break

	race_manager.update_positions()
	race_manager.validate_monotonic_progress()
	race_manager.finalize_race_state()


func use_item(kart: Kart) -> void:
	if kart.held_item == "MUSHROOM":
		kart.boost_timer = 1.55
		kart.current_speed = max(kart.current_speed, 330.0)
		if kart == player:
			flash("MUSHROOM BOOST!", 0.7)
	elif kart.held_item == "BANANA":
		var banana := Banana.new()
		banana.position = kart.position - kart.forward_vector() * 38.0
		banana.owner_kart = kart
		add_child(banana)
		bananas.append(banana)
		if kart == player:
			flash("BANANA DROPPED", 0.7)
	kart.held_item = ""


func start_recovery(kart: Kart) -> void:
	if kart.recovery_timer > 0.0:
		return
	kart.recovery_timer = 1.0
	kart.visible = false
	kart.controls_locked = true
	get_tree().create_timer(1.0).timeout.connect(finish_recovery.bind(weakref(kart)))


func finish_recovery(kart_reference: WeakRef) -> void:
	var kart := kart_reference.get_ref() as Kart
	if is_instance_valid(kart) and kart.recovery_timer > 0.0:
		recover_kart(kart)


func recover_kart(kart: Kart) -> void:
	if not is_instance_valid(kart):
		return
	var index := kart.last_checkpoint
	var tangent := (track_points[(index + 1) % track_points.size()] - track_points[index]).normalized()
	kart.position = track_points[index] + tangent * 28.0
	kart.position.y = 0.0
	kart.ai_waypoint = kart.next_checkpoint
	kart.rotation.y = heading_from_direction(tangent)
	kart.velocity = Vector3.ZERO
	kart.current_speed = 0.0
	kart.recovery_timer = 0.0
	kart.visible = true
	kart.controls_locked = race_manager.state != RaceManager.State.RACING
	if kart == player:
		flash("RECOVERED", 0.8)
		reset_chase_camera()


func finish_race() -> void:
	race_manager.update_positions()
	result_panel.visible = true
	message_label.visible = false
	var ordered := karts.duplicate()
	ordered.sort_custom(func(a: Kart, b: Kart): return a.race_position < b.race_position)
	var standings := ""
	for kart in ordered:
		standings += "%s  %s — %s / %s\n" % [ordinal(kart.race_position), kart.kart_name, kart.character_stats.character_name, kart.vehicle_stats.vehicle_name]
	result_label.text = "RACE COMPLETE\n\n%s\nYour time  %s\n\nR / ENTER rematch    ESC customize" % [standings, format_time(race_manager.elapsed_time)]


func update_hud(delta: float) -> void:
	if race_manager.state == RaceManager.State.COUNTDOWN:
		message_label.text = str(max(1, int(ceil(race_manager.countdown))))
	elif flash_timer > 0.0:
		flash_timer -= delta
		message_label.visible = true
		message_label.text = flash_text
	else:
		message_label.visible = false

	if is_instance_valid(player):
		var current_lap := mini(player.laps_completed + 1, TOTAL_LAPS)
		lap_label.text = "🏁  LAP  %d / %d" % [current_lap, TOTAL_LAPS]
		if player.laps_completed > last_laps_completed:
			animate_lap_change()
		last_laps_completed = player.laps_completed

		var position_icon := "🏁"
		match player.race_position:
			1:
				position_icon = "🏆"
			2:
				position_icon = "🥈"
			3:
				position_icon = "🥉"
		position_label.text = "%s  %s" % [position_icon, ordinal(player.race_position)]
		position_label.add_theme_color_override("font_color", Color("#ffd548") if player.race_position == 1 else Color("#d9e5f1"))
		if player.race_position != last_race_position:
			animate_position_change(last_race_position, player.race_position)
		last_race_position = player.race_position

		if player.held_item != last_held_item:
			update_item_slot(player.held_item)
			last_held_item = player.held_item
		character_label.text = "DRIVER  %s  •  %s" % [player.character_stats.character_name, player.vehicle_stats.vehicle_name]

		var speed_percent := clampf(absf(player.current_speed) / maxf(player.resolved_top_speed, 1.0), 0.0, 1.0)
		speed_bar.value = speed_percent * 100.0
		speed_label.text = "SPEED  %3d%%" % roundi(speed_percent * 100.0)
		speed_fill_style.bg_color = speed_color(speed_percent)

		var rival: Kart
		for kart in karts:
			if kart != player:
				rival = kart
				break
		if is_instance_valid(rival):
			var rival_lap := mini(rival.laps_completed + 1, TOTAL_LAPS)
			rival_status_label.text = "● RIVAL  %s  •  LAP %d/%d" % [ordinal(rival.race_position), rival_lap, TOTAL_LAPS]
		timer_label.text = "⏱  " + format_time(race_manager.elapsed_time)


func update_item_slot(item: String) -> void:
	if not is_instance_valid(item_frame):
		return
	match item:
		"MUSHROOM":
			item_icon.text = "🍄"
			item_name_label.text = "MUSHROOM\nREADY"
			item_icon.add_theme_color_override("font_color", Color("#b8ffca"))
			item_name_label.add_theme_color_override("font_color", Color("#b8ffca"))
			item_frame_style.bg_color = Color(0.035, 0.22, 0.105, 0.96)
			item_frame_style.border_color = Color("#4ee883")
		"BANANA":
			item_icon.text = "🍌"
			item_name_label.text = "BANANA\nREADY"
			item_icon.add_theme_color_override("font_color", Color("#fff2a1"))
			item_name_label.add_theme_color_override("font_color", Color("#fff2a1"))
			item_frame_style.bg_color = Color(0.25, 0.195, 0.025, 0.96)
			item_frame_style.border_color = Color("#f7cf3c")
		_:
			item_icon.text = "—"
			item_name_label.text = "EMPTY\nITEM SLOT"
			item_icon.add_theme_color_override("font_color", Color("#8fa3b8"))
			item_name_label.add_theme_color_override("font_color", Color("#aebdca"))
			item_frame_style.bg_color = Color(0.08, 0.105, 0.135, 0.96)
			item_frame_style.border_color = Color(0.46, 0.56, 0.66, 0.8)


func speed_color(percent: float) -> Color:
	if percent < 0.4:
		return Color("#3f8cff").lerp(Color("#4ee883"), percent / 0.4)
	if percent < 0.75:
		return Color("#4ee883").lerp(Color("#ffad3d"), (percent - 0.4) / 0.35)
	return Color("#ffad3d").lerp(Color("#ef3f47"), (percent - 0.75) / 0.25)


func pulse_item_frame() -> void:
	if not is_instance_valid(item_frame):
		return
	if item_pulse_tween != null and item_pulse_tween.is_valid():
		item_pulse_tween.kill()
	item_frame.scale = Vector2.ONE
	item_frame.modulate = Color.WHITE
	item_pulse_tween = create_tween()
	item_pulse_tween.tween_property(item_frame, "scale", Vector2(1.13, 1.13), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	item_pulse_tween.parallel().tween_property(item_frame, "modulate", Color("#dcfff0"), 0.1)
	item_pulse_tween.tween_property(item_frame, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	item_pulse_tween.parallel().tween_property(item_frame, "modulate", Color.WHITE, 0.22)


func animate_lap_change() -> void:
	if lap_pulse_tween != null and lap_pulse_tween.is_valid():
		lap_pulse_tween.kill()
	lap_label.pivot_offset = lap_label.size * 0.5
	lap_label.scale = Vector2(1.16, 1.16)
	lap_label.modulate = Color("#ffe76c")
	lap_pulse_tween = create_tween()
	lap_pulse_tween.set_parallel(true)
	lap_pulse_tween.tween_property(lap_label, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	lap_pulse_tween.tween_property(lap_label, "modulate", Color.WHITE, 0.34)


func animate_position_change(previous_position: int, current_position: int) -> void:
	if position_change_tween != null and position_change_tween.is_valid():
		position_change_tween.kill()
	var entry_offset := -14.0 if current_position < previous_position else 14.0
	position_label.position = POSITION_LABEL_HOME + Vector2(0, entry_offset)
	position_label.modulate = Color(1, 1, 1, 0.25)
	position_change_tween = create_tween()
	position_change_tween.set_parallel(true)
	position_change_tween.tween_property(position_label, "position", POSITION_LABEL_HOME, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	position_change_tween.tween_property(position_label, "modulate", Color.WHITE, 0.24)


func reset_hud_feedback() -> void:
	for tween in [item_pulse_tween, lap_pulse_tween, position_change_tween]:
		if tween != null and tween.is_valid():
			tween.kill()
	item_pulse_tween = null
	lap_pulse_tween = null
	position_change_tween = null
	if is_instance_valid(item_frame):
		item_frame.scale = Vector2.ONE
		item_frame.modulate = Color.WHITE
	if is_instance_valid(lap_label):
		lap_label.scale = Vector2.ONE
		lap_label.modulate = Color.WHITE
	if is_instance_valid(position_label):
		position_label.position = POSITION_LABEL_HOME
		position_label.modulate = Color.WHITE


func flash(text: String, duration: float) -> void:
	flash_text = text
	flash_timer = duration
	message_label.visible = true


func ordinal(number: int) -> String:
	if number == 1:
		return "1st"
	if number == 2:
		return "2nd"
	if number == 3:
		return "3rd"
	return "%dth" % number


func format_time(value: float) -> String:
	var minutes := int(value) / 60
	var seconds := fmod(value, 60.0)
	return "%02d:%05.2f" % [minutes, seconds]


func world_contains(point: Vector3) -> bool:
	return world_rect.has_point(Vector2(point.x, point.z))


func distance_to_track(point: Vector3) -> float:
	var best := INF
	for i in track_points.size():
		best = min(best, distance_to_segment(point, track_points[i], track_points[(i + 1) % track_points.size()]))
	return best


func distance_to_segment(point: Vector3, start: Vector3, finish: Vector3) -> float:
	var segment := finish - start
	var t: float = clampf((point - start).dot(segment) / segment.length_squared(), 0.0, 1.0)
	return point.distance_to(start + segment * t)


class Kart extends CharacterBody3D:
	const HOP_IMPULSE := 105.0
	const HOP_GRAVITY := 310.0
	const MIN_DRIFT_TIME_FOR_BOOST := 0.35
	const MAX_DRIFT_TIME := 1.4
	const DRIFT_GRIP_MULTIPLIER := 0.42
	const MINI_TURBO_IMPULSE := 92.0
	const MINI_TURBO_MIN_DURATION := 0.45
	const MINI_TURBO_MAX_DURATION := 0.94

	var kart_name := "KART"
	var body_color := Color.RED
	var is_ai := false
	var character_stats: CharacterStats
	var vehicle_stats: VehicleStats
	var resolved_top_speed := KartStatsResolver.BASE_TOP_SPEED
	var resolved_acceleration := KartStatsResolver.BASE_ACCELERATION
	var resolved_turn_rate := KartStatsResolver.BASE_TURN_RATE
	var resolved_drift_turn_rate := KartStatsResolver.BASE_DRIFT_TURN_RATE
	var resolved_drift_min_speed := KartStatsResolver.BASE_DRIFT_MIN_SPEED
	var track := PackedVector3Array()
	var track_width := 72.0
	var controls_locked := true
	var current_speed := 0.0
	var off_track := false
	var held_item := ""
	var wants_to_use_item := false
	var laps_completed := 0
	var next_checkpoint := 1
	var last_checkpoint := 0
	var race_position := 1
	var has_crossed_start := false
	var checkpoint_armed := true
	var has_finished := false
	var finish_order := 0
	var debug_last_progress := 0.0
	var ai_waypoint := 1
	var boost_timer := 0.0
	var spin_timer := 0.0
	var recovery_timer := 0.0
	var drift_charge := 0.0
	var is_drifting := false
	var drift_direction := 0.0
	var is_hopping := false
	var hop_height := 0.0
	var hop_velocity := 0.0
	var mini_turbo_timer := 0.0
	var mini_turbo_duration := 0.0
	var mini_turbo_strength := 0.0
	var visual_root: Node3D
	var boost_flame: MeshInstance3D

	func configure_loadout(character: CharacterStats, vehicle: VehicleStats) -> void:
		character_stats = character
		vehicle_stats = vehicle
		var stats := KartStatsResolver.resolve(character, vehicle)
		resolved_top_speed = stats.top_speed
		resolved_acceleration = stats.acceleration
		resolved_turn_rate = stats.turn_rate
		resolved_drift_turn_rate = stats.drift_turn_rate
		resolved_drift_min_speed = stats.drift_min_speed

	func _ready() -> void:
		collision_layer = 2
		collision_mask = 1
		motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(22.0, 9.0, 31.0)
		collision.shape = shape
		collision.position.y = 4.5
		add_child(collision)
		build_visuals()

	func forward_vector() -> Vector3:
		return Vector3(sin(rotation.y), 0.0, cos(rotation.y)).normalized()

	func build_visuals() -> void:
		visual_root = Node3D.new()
		visual_root.name = "KartVisual"
		add_child(visual_root)
		var body_material := flat_material(body_color)
		var dark_material := flat_material(Color("#111318"))
		var glass_material := flat_material(body_color.lightened(0.38))
		var driver_material := flat_material(character_stats.driver_color)
		var tire_material := flat_material(Color("#17191e"))
		var body_size := Vector3(20.0, 7.0, 30.0)
		var nose_size := Vector3(14.0, 5.0, 11.0)
		var wheel_x := 12.0
		var wheel_z := 10.5
		match vehicle_stats.model_profile:
			1:
				body_size = Vector3(19.0, 6.0, 36.0)
				nose_size = Vector3(13.0, 4.0, 14.0)
				wheel_z = 13.0
			2:
				body_size = Vector3(18.0, 8.0, 25.0)
				nose_size = Vector3(12.0, 6.0, 9.0)
				wheel_x = 11.0
				wheel_z = 8.5
			3:
				body_size = Vector3(24.0, 6.0, 29.0)
				nose_size = Vector3(18.0, 4.0, 10.0)
				wheel_x = 14.0

		add_box_part("Body", body_size, body_material, Vector3(0.0, 5.0, 0.0))
		add_box_part("Nose", nose_size, body_material, Vector3(0.0, 6.0, body_size.z * 0.5 + nose_size.z * 0.25))
		add_box_part("Cockpit", Vector3(12.0, 5.0, 10.0), dark_material, Vector3(0.0, 10.0, 1.0))
		add_box_part("Windshield", Vector3(10.0, 3.0, 2.5), glass_material, Vector3(0.0, 12.0, 6.0))

		for x in [-wheel_x, wheel_x]:
			for z in [-wheel_z, wheel_z]:
				var wheel_mesh := CylinderMesh.new()
				wheel_mesh.top_radius = 4.5
				wheel_mesh.bottom_radius = 4.5
				wheel_mesh.height = 5.0
				wheel_mesh.radial_segments = 8
				wheel_mesh.material = tire_material
				var wheel := MeshInstance3D.new()
				wheel.name = "Wheel"
				wheel.mesh = wheel_mesh
				wheel.position = Vector3(x, 4.0, z)
				wheel.rotation.z = PI * 0.5
				visual_root.add_child(wheel)

		var driver_mesh := SphereMesh.new()
		driver_mesh.radius = 5.5
		driver_mesh.height = 11.0
		driver_mesh.radial_segments = 12
		driver_mesh.rings = 6
		driver_mesh.material = driver_material
		var driver := MeshInstance3D.new()
		driver.name = "Driver"
		driver.mesh = driver_mesh
		driver.position = Vector3(0.0, 16.0, -1.0)
		visual_root.add_child(driver)

		var flame_surface := SurfaceTool.new()
		flame_surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		flame_surface.set_material(flat_material(Color("#ffd23f")))
		for vertex in [Vector3(-5, 3, -17), Vector3(5, 3, -17), Vector3(0, 3, -34), Vector3(0, 3, -34), Vector3(5, 3, -17), Vector3(-5, 3, -17)]:
			flame_surface.set_normal(Vector3.UP)
			flame_surface.add_vertex(vertex)
		boost_flame = MeshInstance3D.new()
		boost_flame.name = "BoostFlame"
		boost_flame.mesh = flame_surface.commit()
		boost_flame.visible = false
		visual_root.add_child(boost_flame)

	func add_box_part(part_name: String, size: Vector3, material: Material, part_position: Vector3) -> void:
		var mesh := BoxMesh.new()
		mesh.size = size
		mesh.material = material
		var part := MeshInstance3D.new()
		part.name = part_name
		part.mesh = mesh
		part.position = part_position
		visual_root.add_child(part)

	func flat_material(color: Color) -> StandardMaterial3D:
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		return material

	func _physics_process(delta: float) -> void:
		boost_timer = max(0.0, boost_timer - delta)
		update_hop(delta)
		boost_flame.visible = boost_timer > 0.0
		if recovery_timer > 0.0:
			velocity = Vector3.ZERO
			return
		if spin_timer > 0.0:
			spin_timer -= delta
			rotation.y += delta * 10.0
			current_speed = move_toward(current_speed, 0.0, 180.0 * delta)
			velocity = forward_vector() * current_speed
			move_flat()
			return
		if controls_locked:
			cancel_drift()
			current_speed = move_toward(current_speed, 0.0, 320.0 * delta)
			velocity = forward_vector() * current_speed
			move_flat()
			return

		var throttle := 0.0
		var steering := 0.0
		if is_ai:
			# RaceManager owns advancement: never abandon an unregistered checkpoint.
			ai_waypoint = next_checkpoint
			var target := track[ai_waypoint]
			var direction := (target - position).normalized()
			var desired := atan2(direction.x, direction.z)
			var difference := wrapf(desired - rotation.y, -PI, PI)
			steering = clampf(-difference * 2.2, -1.0, 1.0)
			var target_speed := ai_corner_speed()
			if absf(difference) > 0.65:
				target_speed = minf(target_speed, resolved_top_speed * 0.45)
			throttle = -1.0 if current_speed > target_speed + 8.0 else target_speed / resolved_top_speed
			if held_item != "" and (held_item == "MUSHROOM" or randf() < 0.006):
				wants_to_use_item = true
		else:
			throttle = Input.get_axis("brake", "accelerate")
			steering = Input.get_axis("steer_left", "steer_right")
			if Input.is_action_just_pressed("hop") and not is_hopping:
				start_hop()
			var wants_drift: bool = Input.is_action_pressed("drift") and not is_hopping and abs(current_speed) > resolved_drift_min_speed
			if not is_drifting and wants_drift and abs(steering) > 0.2:
				start_drift(steering)
			elif is_drifting and not wants_drift:
				finish_drift()
			if is_drifting:
				steering = maxf(absf(steering), 0.35) * drift_direction
			if Input.is_action_just_pressed("use_item"):
				wants_to_use_item = true

		var max_speed: float = resolved_top_speed
		if off_track:
			max_speed *= 0.48
		if boost_timer > 0.0:
			max_speed = resolved_top_speed * 1.35
		var acceleration: float = resolved_acceleration
		if throttle > 0.0:
			current_speed = move_toward(current_speed, max_speed * throttle, acceleration * delta)
		elif throttle < 0.0:
			if current_speed > 5.0:
				current_speed = move_toward(current_speed, 0.0, 390.0 * delta)
			else:
				current_speed = move_toward(current_speed, -125.0, 175.0 * delta)
		else:
			current_speed = move_toward(current_speed, 0.0, 76.0 * delta)

		if off_track and boost_timer <= 0.0:
			current_speed = clamp(current_speed, -100.0, max_speed)
		var speed_factor: float = clampf(abs(current_speed) / 135.0, 0.25, 1.0)
		var direction_sign: float = signf(current_speed) if abs(current_speed) > 1.0 else 1.0
		var turn_rate: float = resolved_turn_rate if not is_drifting else resolved_drift_turn_rate
		rotation.y -= steering * turn_rate * speed_factor * direction_sign * delta

		if is_drifting:
			drift_charge = minf(drift_charge + delta, MAX_DRIFT_TIME)
		apply_mini_turbo(delta)

		var forward := forward_vector()
		if is_drifting:
			velocity = velocity.lerp(forward * current_speed, minf(1.0, DRIFT_GRIP_MULTIPLIER * 5.5 * delta))
		else:
			velocity = forward * current_speed
		move_flat()
		current_speed = velocity.dot(forward_vector())

	func ai_corner_speed() -> float:
		var target_speed := resolved_top_speed
		var distance_ahead := position.distance_to(track[next_checkpoint])
		for offset in 3:
			var i := (next_checkpoint + offset) % track.size()
			var incoming := track[i] - track[posmod(i - 1, track.size())]
			var outgoing := track[(i + 1) % track.size()] - track[i]
			var angle := incoming.angle_to(outgoing)
			if angle > 0.08:
				var radius := minf(incoming.length(), outgoing.length()) / (2.0 * sin(angle * 0.5))
				var corner_speed := clampf(radius * resolved_turn_rate * 0.62, 90.0, resolved_top_speed)
				# Brake before the checkpoint's acceptance radius, not after entering the turn.
				var braking_distance := maxf(0.0, distance_ahead - 110.0)
				target_speed = minf(target_speed, sqrt(corner_speed * corner_speed + 2.0 * 300.0 * braking_distance))
			distance_ahead += outgoing.length()
		return target_speed


	func start_hop() -> void:
		is_hopping = true
		hop_velocity = HOP_IMPULSE
		cancel_drift()

	func update_hop(delta: float) -> void:
		if not is_hopping:
			return
		hop_velocity -= HOP_GRAVITY * delta
		hop_height = maxf(0.0, hop_height + hop_velocity * delta)
		visual_root.position.y = hop_height
		var stretch := clampf(absf(hop_velocity) / HOP_IMPULSE, 0.0, 1.0) * 0.06
		visual_root.scale = Vector3(1.0 - stretch * 0.5, 1.0 + stretch, 1.0 - stretch * 0.5)
		# TODO: replace this squash-and-stretch with a authored hop animation when one exists.
		if hop_height <= 0.0 and hop_velocity < 0.0:
			is_hopping = false
			hop_velocity = 0.0
			visual_root.position.y = 0.0
			visual_root.scale = Vector3.ONE

	func start_drift(steering: float) -> void:
		is_drifting = true
		drift_direction = signf(steering)
		drift_charge = 0.0

	func finish_drift() -> void:
		if not is_drifting:
			return
		is_drifting = false
		drift_direction = 0.0
		if drift_charge >= MIN_DRIFT_TIME_FOR_BOOST:
			var charge_ratio := clampf((drift_charge - MIN_DRIFT_TIME_FOR_BOOST) / (MAX_DRIFT_TIME - MIN_DRIFT_TIME_FOR_BOOST), 0.0, 1.0)
			mini_turbo_strength = lerpf(0.55, 1.0, charge_ratio)
			mini_turbo_duration = lerpf(MINI_TURBO_MIN_DURATION, MINI_TURBO_MAX_DURATION, charge_ratio)
			mini_turbo_timer = mini_turbo_duration
			boost_timer = maxf(boost_timer, mini_turbo_duration)
		drift_charge = 0.0

	func cancel_drift() -> void:
		is_drifting = false
		drift_direction = 0.0
		drift_charge = 0.0

	func apply_mini_turbo(delta: float) -> void:
		if mini_turbo_timer <= 0.0:
			return
		var decay := mini_turbo_timer / mini_turbo_duration
		current_speed += MINI_TURBO_IMPULSE * mini_turbo_strength * decay * (2.0 * delta / mini_turbo_duration)
		current_speed = minf(current_speed, resolved_top_speed * 1.35)
		mini_turbo_timer = maxf(0.0, mini_turbo_timer - delta)

	func move_flat() -> void:
		velocity.y = 0.0
		move_and_slide()
		position.y = 0.0
		velocity.y = 0.0


class ItemBox extends Node3D:
	const ROTATE_SPEED_DEGREES := 90.0
	const PULSE_AMPLITUDE := 0.08
	const PULSE_SPEED := 2.4

	var available := true
	var cooldown := 0.0
	var station_id := 0
	var track_index := 0
	var animation_time := 0.0
	var animation_phase := 0.0
	var base_scale := Vector3.ONE
	var visual_root: Node3D
	var respawn_marker: MeshInstance3D
	var question_label: Label3D

	func _ready() -> void:
		initialize_animation()
		visual_root = Node3D.new()
		visual_root.name = "ItemVisual"
		visual_root.position.y = 16.0
		visual_root.rotation.z = PI * 0.25
		add_child(visual_root)
		base_scale = visual_root.scale

		var cube_mesh := BoxMesh.new()
		cube_mesh.size = Vector3(24.0, 24.0, 24.0)
		cube_mesh.material = flat_material(Color("#43e6ff"))
		var cube := MeshInstance3D.new()
		cube.mesh = cube_mesh
		visual_root.add_child(cube)

		question_label = Label3D.new()
		question_label.text = "?"
		question_label.font_size = 84
		question_label.pixel_size = 0.28
		question_label.outline_size = 11
		question_label.modulate = Color("#172335")
		question_label.outline_modulate = Color.WHITE
		question_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		question_label.no_depth_test = true
		question_label.position = Vector3(0.0, 16.0, 0.0)
		add_child(question_label)

		var marker_mesh := CylinderMesh.new()
		marker_mesh.top_radius = 10.0
		marker_mesh.bottom_radius = 10.0
		marker_mesh.height = 0.25
		marker_mesh.radial_segments = 12
		marker_mesh.material = flat_material(Color(0.3, 0.5, 0.6, 0.22))
		respawn_marker = MeshInstance3D.new()
		respawn_marker.mesh = marker_mesh
		respawn_marker.position.y = 0.2
		respawn_marker.visible = false
		add_child(respawn_marker)

	func _process(delta: float) -> void:
		animation_time += delta
		visual_root.rotation.y = fmod(animation_time * deg_to_rad(ROTATE_SPEED_DEGREES) + animation_phase, TAU)
		visual_root.scale = base_scale * (1.0 + PULSE_AMPLITUDE * sin(animation_time * PULSE_SPEED + animation_phase))

	func initialize_animation() -> void:
		animation_phase = fmod(absf(position.x * 0.017 + position.z * 0.031 + track_index * 0.73), TAU)

	func tick(delta: float) -> void:
		if not available:
			cooldown -= delta
			if cooldown <= 0.0:
				available = true
				visual_root.visible = true
				question_label.visible = true
				respawn_marker.visible = false

	func collect() -> void:
		available = false
		cooldown = 6.0
		visual_root.visible = false
		question_label.visible = false
		respawn_marker.visible = true

	func flat_material(color: Color) -> StandardMaterial3D:
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		if color.a < 1.0:
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		return material


class Banana extends Node3D:
	var owner_kart: Kart
	var life := 12.0
	var grace := 0.65

	func _ready() -> void:
		var torus := TorusMesh.new()
		torus.inner_radius = 3.5
		torus.outer_radius = 11.0
		torus.rings = 12
		torus.ring_segments = 8
		torus.material = flat_material(Color("#ffe54d"))
		var fruit := MeshInstance3D.new()
		fruit.mesh = torus
		fruit.position.y = 5.0
		fruit.scale.z = 0.72
		add_child(fruit)

		var stem_mesh := CylinderMesh.new()
		stem_mesh.top_radius = 2.0
		stem_mesh.bottom_radius = 2.5
		stem_mesh.height = 7.0
		stem_mesh.radial_segments = 6
		stem_mesh.material = flat_material(Color("#6a4b1f"))
		var stem := MeshInstance3D.new()
		stem.mesh = stem_mesh
		stem.position = Vector3(10.0, 7.0, 0.0)
		stem.rotation.z = PI * 0.5
		add_child(stem)

	func _process(delta: float) -> void:
		grace = max(0.0, grace - delta)
		rotation.y += delta * 1.5

	func flat_material(color: Color) -> StandardMaterial3D:
		var material := StandardMaterial3D.new()
		material.albedo_color = color
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		return material
