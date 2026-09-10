extends Node

const Main = preload("res://main.gd")


func _ready() -> void:
	for run in 5:
		seed(4200 + run)
		var race := Main.new()
		add_child(race)
		for index in race.karts.size():
			var kart = race.karts[index]
			var combination := (run * 6 + index) % 16
			kart.configure_loadout(RaceConfig.characters[combination / 4], RaceConfig.vehicles[combination % 4])
			kart.is_ai = true
		if run >= 3:
			configure_player_extreme(race.player, run == 3)
			race.player.is_ai = false
		var previous_checkpoints := [0, 0, 0, 0, 0, 0]
		var stalled_frames := [0, 0, 0, 0, 0, 0]
		var completed := false
		for frame in 18000:
			if run >= 3 and race.race_manager.state == RaceManager.State.RACING:
				drive_player(race.player)
			await get_tree().physics_frame
			for index in race.karts.size():
				var kart = race.karts[index]
				assert(kart.recovery_timer <= 0.0, "AI recovered: run %d kart %d checkpoint %d" % [run, index, kart.next_checkpoint])
				if kart.has_finished:
					continue
				if previous_checkpoints[index] == kart.last_checkpoint:
					stalled_frames[index] += 1
				else:
					previous_checkpoints[index] = kart.last_checkpoint
					stalled_frames[index] = 0
				assert(stalled_frames[index] < 1200, "AI stalled: run %d kart %d checkpoint %d pos %s speed %s" % [run, index, kart.next_checkpoint, kart.position, kart.current_speed])
			if race.race_manager.state == RaceManager.State.FINISHED:
				completed = true
				print("Race run %d: six racers finished three laps in %.2fs (player input: %s)" % [run, race.race_manager.elapsed_time, run >= 3])
				break
		assert(completed, "AI race exceeded five minutes")
		for kart in race.karts:
			assert(kart.laps_completed == 3 and kart.has_finished)
		for action in ["accelerate", "brake", "steer_left", "steer_right", "use_item"]:
			Input.action_release(action)
		race.queue_free()
		await get_tree().process_frame
	print("Circuit integration tests passed (all 16 loadouts; three AI races and two scripted player-input races)")
	get_tree().quit()


func configure_player_extreme(player, fastest: bool) -> void:
	var best := -INF if fastest else INF
	for character in RaceConfig.characters:
		for vehicle in RaceConfig.vehicles:
			var stats := KartStatsResolver.resolve(character, vehicle)
			var value: float = stats.top_speed if fastest else stats.turn_rate
			if (fastest and value > best) or (not fastest and value < best):
				best = value
				player.configure_loadout(character, vehicle)
	print("Player input loadout: %s / %s (speed %.2f, turn %.2f)" % [player.character_stats.character_id, player.vehicle_stats.vehicle_id, player.resolved_top_speed, player.resolved_turn_rate])


func drive_player(player) -> void:
	# Exercise the real Input branch (acceleration, steering, braking, item use).
	# The test supplies a driving line; it does not teleport the racer or grant progress.
	if player.has_finished:
		return
	var direction: Vector3 = player.track[player.next_checkpoint] - player.position
	var difference := wrapf(atan2(direction.x, direction.z) - player.rotation.y, -PI, PI)
	var steering := clampf(-difference * 2.2, -1.0, 1.0)
	Input.action_press("steer_left", maxf(0.0, -steering))
	Input.action_press("steer_right", maxf(0.0, steering))
	var speed: float = player.ai_corner_speed()
	if absf(difference) > 0.65:
		speed = minf(speed, player.resolved_top_speed * 0.45)
	if player.current_speed > speed + 8.0:
		Input.action_release("accelerate")
		Input.action_press("brake")
	else:
		Input.action_release("brake")
		Input.action_press("accelerate", speed / player.resolved_top_speed)
	if player.held_item != "" and not Input.is_action_pressed("use_item"):
		Input.action_press("use_item")
	else:
		Input.action_release("use_item")
