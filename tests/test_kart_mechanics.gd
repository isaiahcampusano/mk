extends Node

const MainSceneScript = preload("res://main.gd")


func _ready() -> void:
	var kart = MainSceneScript.Kart.new()
	kart.visual_root = Node3D.new()

	kart.start_drift(-0.8)
	assert(kart.is_drifting and kart.drift_direction == -1.0)
	kart.drift_charge = 0.2
	kart.finish_drift()
	assert(kart.mini_turbo_timer == 0.0, "A short drift must not grant a boost")

	kart.start_drift(0.8)
	kart.drift_charge = 1.0
	kart.finish_drift()
	assert(kart.mini_turbo_timer > 0.0, "A charged drift must grant a boost")
	var speed_before: float = kart.current_speed
	kart.apply_mini_turbo(0.016)
	assert(kart.current_speed > speed_before)

	kart.start_drift(1.0)
	kart.start_hop()
	assert(kart.is_hopping and not kart.is_drifting, "Hop must cancel drift")
	for frame in 120:
		kart.update_hop(1.0 / 60.0)
	assert(not kart.is_hopping and kart.hop_height == 0.0, "Hop must land and restore its visual transform")

	kart.visual_root.free()
	kart.free()
	test_item_box_visual_isolation()
	print("Kart mechanics tests passed")
	get_tree().quit()


func test_item_box_visual_isolation() -> void:
	var first = MainSceneScript.ItemBox.new()
	first.position = Vector3(100, 0, 20)
	first.track_index = 1
	first.visual_root = Node3D.new()
	first.initialize_animation()
	var second = MainSceneScript.ItemBox.new()
	second.position = Vector3(200, 0, 40)
	second.track_index = 2
	second.visual_root = Node3D.new()
	second.initialize_animation()
	assert(not is_equal_approx(first.animation_phase, second.animation_phase), "Item boxes need independent animation phases")
	var gameplay_position: Vector3 = first.position
	first._process(0.5)
	assert(first.position == gameplay_position, "Item animation must not move the gameplay root")
	first.visual_root.free()
	second.visual_root.free()
	first.free()
	second.free()
