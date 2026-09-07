extends SceneTree

class FakeRacer extends RefCounted:
	var kart_name := "TEST"
	var position := Vector3.ZERO
	var velocity := Vector3.ZERO
	var laps_completed := 0
	var next_checkpoint := 1
	var last_checkpoint := 0
	var race_position := 1
	var checkpoint_armed := true
	var has_finished := false
	var finish_order := 0
	var debug_last_progress := 0.0
	var recovery_timer := 0.0


func _init() -> void:
	test_forward_projection_ranking()
	test_checkpoint_sequence_and_rearm()
	test_countdown_and_idempotent_finish()
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
