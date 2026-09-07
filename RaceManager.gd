class_name RaceManager
extends RefCounted

signal race_started
signal race_ended

enum State { COUNTDOWN, RACING, FINISHED }
enum CheckpointResult { NONE, CHECKPOINT, LAP_COMPLETED, RACER_FINISHED }

const COUNTDOWN_SECONDS := 3.99
const CHECKPOINT_REARM_MULTIPLIER := 1.15
const FORWARD_PROGRESS_EPSILON := 0.25

var state := State.COUNTDOWN
var countdown := COUNTDOWN_SECONDS
var elapsed_time := 0.0
var total_laps := 3
var checkpoint_radius := 92.0
var track_points := PackedVector3Array()
var racers: Array = []
var cumulative_track_distance := PackedFloat32Array()
var track_length := 0.0
var next_finish_order := 1


func configure(points: PackedVector3Array, lap_count: int, radius: float) -> void:
	track_points = points
	total_laps = lap_count
	checkpoint_radius = radius
	build_distance_table()


func start_race(new_racers: Array) -> void:
	racers = new_racers
	state = State.COUNTDOWN
	countdown = COUNTDOWN_SECONDS
	elapsed_time = 0.0
	next_finish_order = 1
	for index in racers.size():
		var racer = racers[index]
		racer.laps_completed = 0
		racer.next_checkpoint = 1
		racer.last_checkpoint = 0
		racer.race_position = index + 1
		racer.checkpoint_armed = true
		racer.has_finished = false
		racer.finish_order = 0
		racer.debug_last_progress = 0.0
	update_positions()


func advance(delta: float) -> void:
	match state:
		State.COUNTDOWN:
			countdown -= delta
			if countdown <= 0.0:
				state = State.RACING
				race_started.emit()
		State.RACING:
			elapsed_time += delta


func register_checkpoint(racer) -> CheckpointResult:
	if state != State.RACING or racer.has_finished or track_points.is_empty():
		return CheckpointResult.NONE
	var index: int = racer.next_checkpoint
	var point := track_points[index]
	var distance: float = racer.position.distance_to(point)
	if not racer.checkpoint_armed:
		if distance > checkpoint_radius * CHECKPOINT_REARM_MULTIPLIER:
			racer.checkpoint_armed = true
		return CheckpointResult.NONE
	if distance > checkpoint_radius:
		return CheckpointResult.NONE
	var previous := (index - 1 + track_points.size()) % track_points.size()
	var following := (index + 1) % track_points.size()
	var tangent := (track_points[following] - track_points[previous]).normalized()
	if racer.velocity.dot(tangent) <= 5.0:
		return CheckpointResult.NONE

	racer.checkpoint_armed = false
	racer.last_checkpoint = index
	if index != 0:
		racer.next_checkpoint = (index + 1) % track_points.size()
		return CheckpointResult.CHECKPOINT

	racer.laps_completed = mini(racer.laps_completed + 1, total_laps)
	racer.next_checkpoint = 1
	if racer.laps_completed < total_laps:
		return CheckpointResult.LAP_COMPLETED
	racer.has_finished = true
	racer.finish_order = next_finish_order
	next_finish_order += 1
	return CheckpointResult.RACER_FINISHED


func finalize_race_state() -> bool:
	if state != State.RACING or racers.is_empty():
		return false
	for racer in racers:
		if not racer.has_finished:
			return false
	end_race()
	return true


func end_race() -> void:
	if state == State.FINISHED:
		return
	update_positions()
	state = State.FINISHED
	race_ended.emit()


func update_positions() -> void:
	var ordered := racers.duplicate()
	ordered.sort_custom(_is_ahead)
	for index in ordered.size():
		ordered[index].race_position = index + 1


func progress_tuple(racer) -> Array:
	var segment_index: int = clampi(racer.last_checkpoint, 0, track_points.size() - 1)
	var next_index := (segment_index + 1) % track_points.size()
	var start := track_points[segment_index]
	var segment := track_points[next_index] - start
	var fraction := 0.0
	if segment.length_squared() > 0.0:
		fraction = clampf((racer.position - start).dot(segment) / segment.length_squared(), 0.0, 1.0)
	return [racer.laps_completed, segment_index, fraction]


func progress_distance(racer) -> float:
	var progress := progress_tuple(racer)
	var segment_index: int = progress[1]
	var next_index := (segment_index + 1) % track_points.size()
	return progress[0] * track_length + cumulative_track_distance[segment_index] + track_points[segment_index].distance_to(track_points[next_index]) * progress[2]


func _is_ahead(a, b) -> bool:
	if a.has_finished and b.has_finished and a.finish_order != b.finish_order:
		return a.finish_order < b.finish_order
	if a.has_finished != b.has_finished:
		return a.has_finished
	var a_progress := progress_tuple(a)
	var b_progress := progress_tuple(b)
	for component in 3:
		if not is_equal_approx(a_progress[component], b_progress[component]):
			return a_progress[component] > b_progress[component]
	return racers.find(a) < racers.find(b)


func validate_monotonic_progress() -> void:
	if not OS.is_debug_build():
		return
	for racer in racers:
		var current := progress_distance(racer)
		var segment_index: int = clampi(racer.last_checkpoint, 0, track_points.size() - 1)
		var next_index := (segment_index + 1) % track_points.size()
		var forward := (track_points[next_index] - track_points[segment_index]).normalized()
		if racer.velocity.dot(forward) > 5.0 and racer.recovery_timer <= 0.0:
			assert(current + FORWARD_PROGRESS_EPSILON >= racer.debug_last_progress, "%s race progress moved backward while driving forward" % racer.kart_name)
		racer.debug_last_progress = current


func build_distance_table() -> void:
	cumulative_track_distance = PackedFloat32Array()
	track_length = 0.0
	for index in track_points.size():
		cumulative_track_distance.append(track_length)
		track_length += track_points[index].distance_to(track_points[(index + 1) % track_points.size()])
