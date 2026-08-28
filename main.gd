extends Node2D

const TOTAL_LAPS := 3
const ROAD_HALF_WIDTH := 72.0
const WALL_OFFSET := 142.0
const CHECKPOINT_RADIUS := 92.0
const WORLD_RECT := Rect2(40, 35, 1320, 750)

enum RaceState { COUNTDOWN, RACING, FINISHED }

var track_points := PackedVector2Array([
	Vector2(210, 345), Vector2(250, 215), Vector2(370, 130),
	Vector2(565, 105), Vector2(735, 130), Vector2(850, 220),
	Vector2(1035, 175), Vector2(1210, 240), Vector2(1260, 365),
	Vector2(1185, 475), Vector2(1120, 650), Vector2(930, 700),
	Vector2(770, 625), Vector2(610, 705), Vector2(405, 675),
	Vector2(240, 565)
])

var karts: Array[Kart] = []
var item_boxes: Array[ItemBox] = []
var bananas: Array[Banana] = []
var player: Kart
var race_state := RaceState.COUNTDOWN
var countdown := 3.99
var race_time := 0.0
var message_label: Label
var lap_label: Label
var position_label: Label
var item_label: Label
var timer_label: Label
var help_label: Label
var result_panel: ColorRect
var result_label: Label
var flash_text := ""
var flash_timer := 0.0


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#58a33b"))
	var camera := Camera2D.new()
	camera.position = Vector2(700, 410)
	camera.zoom = Vector2(0.84, 0.84)
	add_child(camera)
	build_walls()
	build_ui()
	start_race()
	queue_redraw()


func start_race() -> void:
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

	var start_heading := (track_points[1] - track_points[0]).angle()
	var tangent := Vector2.from_angle(start_heading)
	var normal := tangent.orthogonal()
	player = create_kart("PLAYER", track_points[0] - tangent * 18.0 - normal * 24.0, start_heading, Color("#ef3f47"), false)
	create_kart("RIVAL", track_points[0] - tangent * 58.0 + normal * 25.0, start_heading, Color("#3e70ff"), true)

	for index in [3, 6, 9, 12, 14]:
		var box := ItemBox.new()
		box.position = track_points[index]
		box.track_index = index
		add_child(box)
		item_boxes.append(box)

	race_state = RaceState.COUNTDOWN
	countdown = 3.99
	race_time = 0.0
	result_panel.visible = false
	message_label.visible = true
	flash_text = ""
	flash_timer = 0.0


func create_kart(kart_name: String, spawn: Vector2, heading: float, color: Color, ai: bool) -> Kart:
	var kart := Kart.new()
	kart.kart_name = kart_name
	kart.position = spawn
	kart.rotation = heading
	kart.body_color = color
	kart.is_ai = ai
	kart.track = track_points
	kart.track_width = ROAD_HALF_WIDTH
	kart.next_checkpoint = 1
	kart.last_checkpoint = 0
	kart.ai_waypoint = 1
	add_child(kart)
	karts.append(kart)
	return kart


func build_walls() -> void:
	var wall_body := StaticBody2D.new()
	wall_body.collision_layer = 1
	wall_body.collision_mask = 0
	wall_body.name = "TrackWalls"
	add_child(wall_body)
	var inner := get_offset_loop(-WALL_OFFSET)
	var outer := get_offset_loop(WALL_OFFSET)
	for loop in [inner, outer]:
		for i in loop.size():
			var shape := CollisionShape2D.new()
			var segment := SegmentShape2D.new()
			segment.a = loop[i]
			segment.b = loop[(i + 1) % loop.size()]
			shape.shape = segment
			wall_body.add_child(shape)


func get_offset_loop(distance: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in track_points.size():
		var previous := track_points[(i - 1 + track_points.size()) % track_points.size()]
		var following := track_points[(i + 1) % track_points.size()]
		var tangent := (following - previous).normalized()
		result.append(track_points[i] + tangent.orthogonal() * distance)
	return result


func build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var hud_back := ColorRect.new()
	hud_back.position = Vector2(18, 16)
	hud_back.size = Vector2(285, 116)
	hud_back.color = Color(0.04, 0.05, 0.08, 0.78)
	layer.add_child(hud_back)

	lap_label = make_label(Vector2(34, 27), 28, Color.WHITE)
	position_label = make_label(Vector2(34, 62), 25, Color("#ffd548"))
	item_label = make_label(Vector2(34, 94), 20, Color("#cceaff"))
	timer_label = make_label(Vector2(1085, 22), 22, Color.WHITE)
	help_label = make_label(Vector2(20, 682), 16, Color(1, 1, 1, 0.86))
	help_label.text = "WASD / ARROWS drive   SHIFT drift   SPACE use item   R restart"
	for label in [lap_label, position_label, item_label, timer_label, help_label]:
		layer.add_child(label)

	message_label = make_label(Vector2.ZERO, 64, Color.WHITE)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	message_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	message_label.add_theme_constant_override("shadow_offset_x", 4)
	message_label.add_theme_constant_override("shadow_offset_y", 4)
	layer.add_child(message_label)

	result_panel = ColorRect.new()
	result_panel.position = Vector2(350, 175)
	result_panel.size = Vector2(580, 370)
	result_panel.color = Color(0.025, 0.03, 0.055, 0.94)
	layer.add_child(result_panel)
	result_label = make_label(Vector2(20, 25), 30, Color.WHITE)
	result_label.size = Vector2(540, 320)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_panel.add_child(result_label)


func make_label(pos: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = pos
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("restart"):
		start_race()
		return

	match race_state:
		RaceState.COUNTDOWN:
			countdown -= delta
			for kart in karts:
				kart.controls_locked = true
			if countdown <= 0.0:
				race_state = RaceState.RACING
				for kart in karts:
					kart.controls_locked = false
				flash("GO!", 1.0)
		RaceState.RACING:
			race_time += delta
			process_race(delta)
		RaceState.FINISHED:
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
				kart.held_item = "MUSHROOM" if (box.track_index + kart.laps_completed) % 2 == 0 else "BANANA"
				box.collect()
				if kart == player:
					flash("ITEM: " + kart.held_item, 0.8)
				break

	for kart in karts:
		kart.off_track = distance_to_track(kart.position) > ROAD_HALF_WIDTH
		check_checkpoint(kart)
		if not WORLD_RECT.has_point(kart.position) or distance_to_track(kart.position) > WALL_OFFSET + 70.0:
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

	sort_race_positions()


func check_checkpoint(kart: Kart) -> void:
	var index := kart.next_checkpoint
	var point := track_points[index]
	if kart.position.distance_to(point) > CHECKPOINT_RADIUS:
		return
	var tangent := (track_points[(index + 1) % track_points.size()] - track_points[(index - 1 + track_points.size()) % track_points.size()]).normalized()
	if kart.velocity.dot(tangent) <= 5.0:
		return
	if kart.checkpoint_cooldown > 0.0:
		return

	kart.last_checkpoint = index
	# Only suppress repeat frames inside this gate. A longer delay can skip the
	# next legitimate checkpoint at boost speed on shorter track segments.
	kart.checkpoint_cooldown = 0.18
	if index == 0:
		kart.laps_completed += 1
		kart.next_checkpoint = 1
		if kart == player:
			if kart.laps_completed >= TOTAL_LAPS:
				finish_race()
			else:
				flash("LAP %d / %d" % [kart.laps_completed + 1, TOTAL_LAPS], 1.2)
	else:
		kart.next_checkpoint = (index + 1) % track_points.size()


func use_item(kart: Kart) -> void:
	if kart.held_item == "MUSHROOM":
		kart.boost_timer = 1.55
		kart.current_speed = max(kart.current_speed, 330.0)
		if kart == player:
			flash("MUSHROOM BOOST!", 0.7)
	elif kart.held_item == "BANANA":
		var banana := Banana.new()
		banana.position = kart.position - Vector2.from_angle(kart.rotation) * 38.0
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
	get_tree().create_timer(1.0).timeout.connect(func(): recover_kart(kart))


func recover_kart(kart: Kart) -> void:
	if not is_instance_valid(kart):
		return
	var index := kart.last_checkpoint
	var tangent := (track_points[(index + 1) % track_points.size()] - track_points[index]).normalized()
	kart.position = track_points[index] + tangent * 28.0
	kart.rotation = tangent.angle()
	kart.velocity = Vector2.ZERO
	kart.current_speed = 0.0
	kart.recovery_timer = 0.0
	kart.visible = true
	kart.controls_locked = race_state != RaceState.RACING
	if kart == player:
		flash("RECOVERED", 0.8)


func sort_race_positions() -> void:
	var ordered := karts.duplicate()
	ordered.sort_custom(func(a: Kart, b: Kart): return race_score(a) > race_score(b))
	for i in ordered.size():
		ordered[i].race_position = i + 1


func race_score(kart: Kart) -> float:
	var checkpoint_progress := kart.next_checkpoint - 1
	if kart.next_checkpoint == 0:
		checkpoint_progress = track_points.size() - 1
	var next_point := track_points[kart.next_checkpoint]
	var closeness: float = clampf(1.0 - kart.position.distance_to(next_point) / 350.0, 0.0, 0.99)
	return kart.laps_completed * 1000.0 + checkpoint_progress * 10.0 + closeness


func finish_race() -> void:
	race_state = RaceState.FINISHED
	sort_race_positions()
	result_panel.visible = true
	message_label.visible = false
	result_label.text = "RACE COMPLETE\n\nYou finished %s\nTime  %s\n\nPress R or Enter to race again" % [ordinal(player.race_position), format_time(race_time)]


func update_hud(delta: float) -> void:
	if race_state == RaceState.COUNTDOWN:
		message_label.text = str(max(1, int(ceil(countdown))))
	elif flash_timer > 0.0:
		flash_timer -= delta
		message_label.visible = true
		message_label.text = flash_text
	else:
		message_label.visible = false

	if is_instance_valid(player):
		lap_label.text = "LAP  %d / %d" % [min(player.laps_completed + 1, TOTAL_LAPS), TOTAL_LAPS]
		position_label.text = "POSITION  " + ordinal(player.race_position)
		item_label.text = "ITEM  " + (player.held_item if player.held_item != "" else "—")
	timer_label.text = format_time(race_time)


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


func distance_to_track(point: Vector2) -> float:
	var best := INF
	for i in track_points.size():
		best = min(best, distance_to_segment(point, track_points[i], track_points[(i + 1) % track_points.size()]))
	return best


func distance_to_segment(point: Vector2, start: Vector2, finish: Vector2) -> float:
	var segment := finish - start
	var t: float = clampf((point - start).dot(segment) / segment.length_squared(), 0.0, 1.0)
	return point.distance_to(start + segment * t)


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1400, 820), Color("#4b9636"))
	# Broad dirt shoulders, asphalt, and lane markings share the same closed path.
	var closed := track_points.duplicate()
	closed.append(track_points[0])
	draw_polyline(closed, Color("#b48a55"), WALL_OFFSET * 2.0, true)
	draw_polyline(closed, Color("#2d3138"), ROAD_HALF_WIDTH * 2.0, true)
	draw_polyline(closed, Color("#e8dfb9"), 4.0, true)
	for i in track_points.size():
		var a := track_points[i]
		var b := track_points[(i + 1) % track_points.size()]
		var direction := (b - a).normalized()
		var length := a.distance_to(b)
		var cursor := 18.0
		while cursor < length:
			draw_line(a + direction * cursor, a + direction * min(cursor + 16.0, length), Color(1, 1, 1, 0.38), 2.0)
			cursor += 34.0

	# Finish-line checkerboard.
	var finish_tangent := (track_points[1] - track_points[-1]).normalized()
	var finish_normal := finish_tangent.orthogonal()
	for row in 6:
		for column in 2:
			var center := track_points[0] + finish_normal * (row - 2.5) * 20.0 + finish_tangent * (column - 0.5) * 15.0
			var color := Color.WHITE if (row + column) % 2 == 0 else Color("#15171c")
			draw_rect(Rect2(center - Vector2(8, 10), Vector2(16, 20)), color)

	# Ordered checkpoint gates are intentionally visible for MVP validation.
	for i in track_points.size():
		if i == 0:
			continue
		var point := track_points[i]
		draw_circle(point, 7.0, Color(0.2, 0.9, 1.0, 0.50))


class Kart extends CharacterBody2D:
	var kart_name := "KART"
	var body_color := Color.RED
	var is_ai := false
	var track := PackedVector2Array()
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
	var ai_waypoint := 1
	var boost_timer := 0.0
	var spin_timer := 0.0
	var recovery_timer := 0.0
	var checkpoint_cooldown := 0.0
	var drift_charge := 0.0
	var was_drifting := false

	func _ready() -> void:
		collision_layer = 2
		collision_mask = 1
		var collision := CollisionShape2D.new()
		var shape := CapsuleShape2D.new()
		shape.radius = 12.0
		shape.height = 30.0
		collision.shape = shape
		collision.rotation = PI * 0.5
		add_child(collision)
		queue_redraw()

	func _physics_process(delta: float) -> void:
		checkpoint_cooldown = max(0.0, checkpoint_cooldown - delta)
		boost_timer = max(0.0, boost_timer - delta)
		if recovery_timer > 0.0:
			return
		if spin_timer > 0.0:
			spin_timer -= delta
			rotation += delta * 10.0
			current_speed = move_toward(current_speed, 0.0, 180.0 * delta)
			velocity = Vector2.from_angle(rotation) * current_speed
			move_and_slide()
			return
		if controls_locked:
			current_speed = move_toward(current_speed, 0.0, 320.0 * delta)
			velocity = Vector2.from_angle(rotation) * current_speed
			move_and_slide()
			return

		var throttle := 0.0
		var steering := 0.0
		var drifting := false
		if is_ai:
			var target := track[ai_waypoint]
			if position.distance_to(target) < 70.0:
				ai_waypoint = (ai_waypoint + 1) % track.size()
				target = track[ai_waypoint]
			var desired := (target - position).angle()
			var difference := wrapf(desired - rotation, -PI, PI)
			steering = clamp(difference * 2.2, -1.0, 1.0)
			throttle = 0.72 if abs(difference) > 0.65 else 1.0
			if held_item != "" and (held_item == "MUSHROOM" or randf() < 0.006):
				wants_to_use_item = true
		else:
			throttle = Input.get_axis("brake", "accelerate")
			steering = Input.get_axis("steer_left", "steer_right")
			drifting = Input.is_action_pressed("drift") and abs(steering) > 0.2 and abs(current_speed) > 120.0
			if Input.is_action_just_pressed("use_item"):
				wants_to_use_item = true

		var max_speed := 355.0
		if off_track:
			max_speed *= 0.48
		if boost_timer > 0.0:
			max_speed = 480.0
		var acceleration := 245.0
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
		var turn_rate := 2.35 if not drifting else 3.05
		rotation += steering * turn_rate * speed_factor * direction_sign * delta

		if drifting:
			drift_charge = min(drift_charge + delta, 1.4)
		else:
			if was_drifting and drift_charge > 0.35:
				boost_timer = max(boost_timer, 0.45 + drift_charge * 0.35)
				current_speed += 55.0 + drift_charge * 34.0
			drift_charge = 0.0
		was_drifting = drifting

		var forward := Vector2.from_angle(rotation)
		if drifting:
			velocity = velocity.lerp(forward * current_speed, 2.3 * delta)
		else:
			velocity = forward * current_speed
		move_and_slide()
		current_speed = velocity.dot(Vector2.from_angle(rotation))

	func _draw() -> void:
		draw_circle(Vector2(-8, -13), 5.0, Color("#111318"))
		draw_circle(Vector2(8, -13), 5.0, Color("#111318"))
		draw_circle(Vector2(-8, 13), 5.0, Color("#111318"))
		draw_circle(Vector2(8, 13), 5.0, Color("#111318"))
		draw_rect(Rect2(-10, -15, 20, 30), body_color, true)
		draw_polygon(PackedVector2Array([Vector2(-10, -15), Vector2(10, -15), Vector2(6, -23), Vector2(-6, -23)]), PackedColorArray([body_color]))
		draw_circle(Vector2.ZERO, 6.0, body_color.lightened(0.35))
		if boost_timer > 0.0:
			draw_polygon(PackedVector2Array([Vector2(-5, 17), Vector2(5, 17), Vector2(0, 31)]), PackedColorArray([Color("#ffd23f")]))


class ItemBox extends Node2D:
	var available := true
	var cooldown := 0.0
	var track_index := 0
	var spin := 0.0

	func _process(delta: float) -> void:
		spin += delta
		queue_redraw()

	func tick(delta: float) -> void:
		if not available:
			cooldown -= delta
			if cooldown <= 0.0:
				available = true
				queue_redraw()

	func collect() -> void:
		available = false
		cooldown = 6.0
		queue_redraw()

	func _draw() -> void:
		if not available:
			draw_circle(Vector2.ZERO, 10.0, Color(0.3, 0.5, 0.6, 0.2))
			return
		var points := PackedVector2Array()
		for i in 4:
			points.append(Vector2.from_angle(spin + PI * 0.5 * i) * 19.0)
		draw_polygon(points, PackedColorArray([Color("#43e6ff")]))
		draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), Color.WHITE, 3.0)
		draw_string(ThemeDB.fallback_font, Vector2(-6, 7), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("#172335"))


class Banana extends Node2D:
	var owner_kart: Kart
	var life := 12.0
	var grace := 0.65

	func _process(delta: float) -> void:
		grace = max(0.0, grace - delta)
		rotation += delta * 1.5

	func _draw() -> void:
		draw_arc(Vector2.ZERO, 14.0, 0.1, PI * 1.15, 18, Color("#ffe54d"), 8.0, true)
		draw_circle(Vector2(13, 2), 3.0, Color("#6a4b1f"))
