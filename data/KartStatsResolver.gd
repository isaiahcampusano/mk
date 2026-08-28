class_name KartStatsResolver
extends RefCounted

const BASE_TOP_SPEED := 355.0
const BASE_ACCELERATION := 245.0
const BASE_TURN_RATE := 2.35
const BASE_DRIFT_TURN_RATE := 3.05
const BASE_DRIFT_MIN_SPEED := 120.0


static func resolve(character: CharacterStats, vehicle: VehicleStats) -> Dictionary:
	return {
		"top_speed": BASE_TOP_SPEED * character.base_speed_mod * vehicle.speed_mod,
		"acceleration": BASE_ACCELERATION * character.base_accel_mod * vehicle.accel_mod,
		"turn_rate": BASE_TURN_RATE * character.base_handling_mod * vehicle.handling_mod,
		"drift_turn_rate": BASE_DRIFT_TURN_RATE * character.base_handling_mod * vehicle.handling_mod * vehicle.drift_mod,
		"drift_min_speed": BASE_DRIFT_MIN_SPEED / vehicle.drift_mod,
		"weight": character.weight,
	}

