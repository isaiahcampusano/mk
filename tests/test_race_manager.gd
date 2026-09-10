extends SceneTree

class FakeRacer extends RefCounted:
	var kart_name := "TEST"
	var position := Vector3.ZERO
	var velocity := Vector3.ZERO
	var laps_completed := 0
	var next_checkpoint := 1
	var last_checkpoint := 0
	var race_position := 1
	var has_crossed_start := false
	var checkpoint_armed := true
	var has_finished := false
	var finish_order := 0
	var debug_last_progress := 0.0
	var recovery_timer := 0.0


func _init() -> void:
	test_forward_projection_ranking()
	test_checkpoint_sequence_and_rearm()
	test_countdown_and_idempotent_finish()
	test_start_grid_and_crossing()
	test_ordered_three_lap_race()
	print("RaceManager tests passed")
	quit()
func make_manager() -> RaceManager:
	var manager := RaceManager.new()
	manager.configure(PackedVector3Array([
		Vector3(0, 0, 0),
		Vector3(100, 0, 0),
		Vector3(100, 0, 100),
		Vector3(0, 0, 100),
	]), 1, 10.0)
	return manager


func test_forward_projection_ranking() -> void:
	var manager := make_manager()
	var leader := FakeRacer.new()
	leader.kart_name = "LEADER"
	leader.position = Vector3(80, 0, 60)
	var trailer := FakeRacer.new()
	trailer.kart_name = "TRAILER"
	trailer.position = Vector3(70, 0, 0)
	manager.start_race([leader, trailer])
	manager.update_positions()
	assert(leader.race_position == 1, "Forward segment projection must outrank Euclidean checkpoint distance")


func test_checkpoint_sequence_and_rearm() -> void:
	var manager := make_manager()
	var racer := FakeRacer.new()
	manager.start_race([racer])
	manager.state = RaceManager.State.RACING
	racer.position = Vector3(100, 0, 0)
	racer.velocity = Vector3(20, 0, 20)
	assert(manager.register_checkpoint(racer) == RaceManager.CheckpointResult.CHECKPOINT)
	assert(racer.next_checkpoint == 2)
	assert(manager.register_checkpoint(racer) == RaceManager.CheckpointResult.NONE, "A checkpoint must not double-trigger before rearming")
	racer.position = Vector3(100, 0, 50)
	manager.register_checkpoint(racer)
	assert(racer.checkpoint_armed)


func test_countdown_and_idempotent_finish() -> void:
	var manager := make_manager()
	var first := FakeRacer.new()
	var second := FakeRacer.new()
	var end_events := [0]
	manager.race_ended.connect(func(): end_events[0] += 1)
	manager.start_race([first, second])
	manager.advance(RaceManager.COUNTDOWN_SECONDS + 0.1)
	assert(manager.state == RaceManager.State.RACING)
	first.has_finished = true
	assert(not manager.finalize_race_state(), "Race must continue until every racer finishes")
	second.has_finished = true
	assert(manager.finalize_race_state())
	manager.end_race()
	assert(manager.state == RaceManager.State.FINISHED)
	assert(end_events[0] == 1, "EndRace must be idempotent")
	first.finish_order = 2
	second.finish_order = 1
	manager.update_positions()
	assert(second.race_position == 1, "Finish order must deterministically break equal-progress ties")


func test_start_grid_and_crossing() -> void:
	var manager := make_manager()
	var rear := FakeRacer.new()
	rear.position = Vector3(-115, 0, -5)
	var front := FakeRacer.new()
	front.position = Vector3(-55, 0, 5)
	var tied := FakeRacer.new()
	tied.position = Vector3(-55, 0, -5)
	manager.start_race([rear, front, tied])
	assert(front.race_position == 1 and tied.race_position == 2 and rear.race_position == 3)
	assert(is_equal_approx(manager.progress_distance(rear), -115.0))
	assert(not front.has_crossed_start)
	front.position.x = 1.0
	front.velocity = Vector3(20, 0, 0)
	manager.register_checkpoint(front)
	assert(not front.has_crossed_start, "Countdown cannot register the starting crossing")
	manager.state = RaceManager.State.RACING
	front.velocity = Vector3(-20, 0, 0)
	manager.register_checkpoint(front)
	assert(not front.has_crossed_start, "Backward movement cannot register the start")
	front.velocity = Vector3(20, 0, 0)
	assert(manager.register_checkpoint(front) == RaceManager.CheckpointResult.NONE)
	assert(front.has_crossed_start and front.laps_completed == 0 and front.next_checkpoint == 1)
	front.position.x = -60.0
	front.velocity.x = -20.0
	manager.register_checkpoint(front)
	assert(front.has_crossed_start, "Reversing must never restore pre-start ranking")
	assert(manager.progress_distance(front) == 0.0)
	manager.start_race([rear, front, tied])
	assert(not front.has_crossed_start, "Restart must clear the previous launch crossing")


func test_ordered_three_lap_race() -> void:
	var manager := make_manager()
	manager.total_laps = 3
	var racer := FakeRacer.new()
	manager.start_race([racer])
	manager.state = RaceManager.State.RACING
	racer.position = manager.track_points[2]
	racer.velocity = Vector3(-20, 0, 20)
	assert(manager.register_checkpoint(racer) == RaceManager.CheckpointResult.NONE, "Skipped checkpoint cannot count")
	racer.position = manager.track_points[1]
	racer.velocity = Vector3(-20, 0, -20)
	assert(manager.register_checkpoint(racer) == RaceManager.CheckpointResult.NONE, "Backward checkpoint cannot count")
	for lap in 3:
		for index in [1, 2, 3, 0]:
			var previous: int = posmod(index - 1, 4)
			racer.position = manager.track_points[previous].lerp(manager.track_points[index], 0.5)
			manager.register_checkpoint(racer)
			racer.position = manager.track_points[index]
			racer.velocity = (manager.track_points[(index + 1) % 4] - manager.track_points[previous]).normalized() * 20.0
			var result := manager.register_checkpoint(racer)
			if index == 0:
				assert(racer.laps_completed == lap + 1)
				assert(result == (RaceManager.CheckpointResult.RACER_FINISHED if lap == 2 else RaceManager.CheckpointResult.LAP_COMPLETED))
			else:
				assert(result == RaceManager.CheckpointResult.CHECKPOINT)
	assert(racer.has_finished and racer.finish_order == 1)
	assert(manager.register_checkpoint(racer) == RaceManager.CheckpointResult.NONE)
	assert(manager.finalize_race_state())
