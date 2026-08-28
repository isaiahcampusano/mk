extends Control

var selected_index := 0
var cards: Array[PanelContainer] = []
var selection_label: Label


func _ready() -> void:
	selected_index = RaceConfig.player_vehicle_index
	build_screen()
	update_selection()


func build_screen() -> void:
	var background := ColorRect.new()
	background.color = Color("#171324")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var content := VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 28
	content.offset_top = 24
	content.offset_right = -28
	content.offset_bottom = -24
	content.add_theme_constant_override("separation", 12)
	add_child(content)

	content.add_child(make_label("MK CIRCUIT  /  KART WORKSHOP", 16, Color("#ff72c6")))
	content.add_child(make_label("Choose your kart body", 42, Color.WHITE))
	content.add_child(make_label("Kart bodies multiply your driver's strengths and tradeoffs.", 18, Color("#c2b7d3")))

	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	content.add_child(grid)

	for index in RaceConfig.vehicles.size():
		var vehicle := RaceConfig.vehicles[index]
		var card := make_card(vehicle, index)
		grid.add_child(card)
		cards.append(card)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 14)
	content.add_child(footer)
	var back := Button.new()
	back.text = "‹  BACK"
	back.custom_minimum_size = Vector2(120, 46)
	back.focus_mode = Control.FOCUS_NONE
	back.pressed.connect(go_back)
	footer.add_child(back)
	selection_label = make_label("", 20, Color("#ff91d3"))
	selection_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(selection_label)
	footer.add_child(make_label("ARROWS choose   ENTER race   ESC back", 17, Color("#c2b7d3")))
	var confirm := Button.new()
	confirm.text = "START RACE  ›"
	confirm.custom_minimum_size = Vector2(180, 46)
	confirm.focus_mode = Control.FOCUS_NONE
	confirm.pressed.connect(confirm_selection)
	footer.add_child(confirm)


func make_card(vehicle: VehicleStats, index: int) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 430)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	card.add_child(stack)

	var icon_back := PanelContainer.new()
	icon_back.custom_minimum_size = Vector2(0, 152)
	var icon_style := StyleBoxFlat.new()
	icon_style.bg_color = Color("#2b203c")
	icon_style.set_corner_radius_all(10)
	icon_back.add_theme_stylebox_override("panel", icon_style)
	stack.add_child(icon_back)
	var icon := TextureRect.new()
	icon.texture = vehicle.icon
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_back.add_child(icon)

	var name_label := make_label(vehicle.vehicle_name, 25, Color.WHITE)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(name_label)
	var roles := ["ALL-ROUNDER", "TOP SPEED", "QUICK LAUNCH", "DRIFT CONTROL"]
	var role_label := make_label(roles[index], 14, Color("#ff72c6"))
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(role_label)

	make_stat_row(stack, "SPEED", vehicle.speed_mod)
	make_stat_row(stack, "ACCEL", vehicle.accel_mod)
	make_stat_row(stack, "HANDLING", vehicle.handling_mod)
	make_stat_row(stack, "DRIFT", vehicle.drift_mod)

	var choose := Button.new()
	choose.text = "SELECT"
	choose.custom_minimum_size = Vector2(0, 40)
	choose.focus_mode = Control.FOCUS_NONE
	choose.pressed.connect(func(): select_index(index))
	stack.add_child(choose)
	return card


func make_stat_row(parent: VBoxContainer, stat_name: String, modifier: float) -> void:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := make_label(stat_name, 13, Color("#e5dced"))
	label.custom_minimum_size.x = 58
	row.add_child(label)
	var bar := ProgressBar.new()
	bar.max_value = 120.0
	bar.value = modifier * 100.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(72, 12)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var background_style := StyleBoxFlat.new()
	background_style.bg_color = Color("#3a2d4d")
	background_style.set_corner_radius_all(5)
	var fill_style := background_style.duplicate()
	fill_style.bg_color = Color("#ff72c6")
	bar.add_theme_stylebox_override("background", background_style)
	bar.add_theme_stylebox_override("fill", fill_style)
	row.add_child(bar)


func select_index(index: int) -> void:
	selected_index = wrapi(index, 0, RaceConfig.vehicles.size())
	update_selection()


func update_selection() -> void:
	for index in cards.size():
		cards[index].add_theme_stylebox_override("panel", card_style(index == selected_index))
	if selection_label:
		selection_label.text = "SELECTED  •  " + RaceConfig.vehicles[selected_index].vehicle_name


func card_style(selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#292037") if not selected else Color("#3b2a4e")
	style.border_color = Color("#ff91d3") if selected else Color("#4e3a60")
	style.set_border_width_all(3 if selected else 1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


func make_label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func confirm_selection() -> void:
	RaceConfig.select_player_vehicle(selected_index)
	RaceConfig.assign_ai_loadout()
	get_tree().change_scene_to_file("res://main.tscn")


func go_back() -> void:
	RaceConfig.select_player_vehicle(selected_index)
	get_tree().change_scene_to_file("res://CharacterSelect.tscn")


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_left"):
		select_index(selected_index - 1)
	elif event.is_action_pressed("ui_right"):
		select_index(selected_index + 1)
	elif event.is_action_pressed("ui_up"):
		select_index(selected_index - 2)
	elif event.is_action_pressed("ui_down"):
		select_index(selected_index + 2)
	elif event.is_action_pressed("ui_accept"):
		confirm_selection()
	elif event.is_action_pressed("ui_cancel"):
		go_back()

