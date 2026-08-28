extends Control

var selected_index := 0
var cards: Array[PanelContainer] = []
var selection_label: Label


func _ready() -> void:
	selected_index = RaceConfig.player_character_index
	build_screen()
	update_selection()


func build_screen() -> void:
	var background := ColorRect.new()
	background.color = Color("#111829")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var content := VBoxContainer.new()
	content.position = Vector2(50, 26)
	content.size = Vector2(1180, 665)
	content.add_theme_constant_override("separation", 12)
	add_child(content)

	var eyebrow := make_label("MK CIRCUIT  /  DRIVER GARAGE", 16, Color("#65e5ff"))
	content.add_child(eyebrow)
	var title := make_label("Choose your driver", 42, Color.WHITE)
	content.add_child(title)
	var subtitle := make_label("Every driver changes top speed, acceleration, and handling.", 18, Color("#aebbd1"))
	content.add_child(subtitle)

	var grid := GridContainer.new()
	grid.columns = 4
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	content.add_child(grid)

	for index in RaceConfig.characters.size():
		var character := RaceConfig.characters[index]
		var card := make_card(character, index)
		grid.add_child(card)
		cards.append(card)

	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 18)
	content.add_child(footer)
	selection_label = make_label("", 20, Color("#ffd65a"))
	selection_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(selection_label)
	var hint := make_label("ARROWS choose   ENTER confirm", 17, Color("#aebbd1"))
	footer.add_child(hint)
	var confirm := Button.new()
	confirm.text = "CONTINUE TO KARTS  ›"
	confirm.custom_minimum_size = Vector2(230, 46)
	confirm.focus_mode = Control.FOCUS_NONE
	confirm.pressed.connect(confirm_selection)
	footer.add_child(confirm)


func make_card(character: CharacterStats, index: int) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(280, 430)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 8)
	card.add_child(stack)

	var portrait_back := PanelContainer.new()
	portrait_back.custom_minimum_size = Vector2(0, 152)
	var portrait_style := StyleBoxFlat.new()
	portrait_style.bg_color = Color("#1b263c")
	portrait_style.corner_radius_top_left = 10
	portrait_style.corner_radius_top_right = 10
	portrait_style.corner_radius_bottom_left = 10
	portrait_style.corner_radius_bottom_right = 10
	portrait_back.add_theme_stylebox_override("panel", portrait_style)
	stack.add_child(portrait_back)
	var portrait := TextureRect.new()
	portrait.texture = character.portrait
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_back.add_child(portrait)

	var name_label := make_label(character.character_name, 25, Color.WHITE)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(name_label)
	var class_names := ["LIGHT / NIMBLE", "MEDIUM-LIGHT", "MEDIUM-HEAVY", "HEAVY / POWER"]
	var class_label := make_label(class_names[index], 14, Color("#65e5ff"))
	class_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack.add_child(class_label)

	make_stat_row(stack, "SPEED", character.base_speed_mod)
	make_stat_row(stack, "ACCEL", character.base_accel_mod)
	make_stat_row(stack, "HANDLING", character.base_handling_mod)

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
	var label := make_label(stat_name, 13, Color("#d8e0ee"))
	label.custom_minimum_size.x = 76
	row.add_child(label)
	var bar := ProgressBar.new()
	bar.max_value = 120.0
	bar.value = modifier * 100.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(150, 13)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var background_style := StyleBoxFlat.new()
	background_style.bg_color = Color("#26334a")
	background_style.corner_radius_top_left = 5
	background_style.corner_radius_top_right = 5
	background_style.corner_radius_bottom_left = 5
	background_style.corner_radius_bottom_right = 5
	var fill_style := background_style.duplicate()
	fill_style.bg_color = Color("#65e5ff")
	bar.add_theme_stylebox_override("background", background_style)
	bar.add_theme_stylebox_override("fill", fill_style)
	row.add_child(bar)


func select_index(index: int) -> void:
	selected_index = wrapi(index, 0, RaceConfig.characters.size())
	update_selection()


func update_selection() -> void:
	for index in cards.size():
		cards[index].add_theme_stylebox_override("panel", card_style(index == selected_index))
	if selection_label:
		selection_label.text = "SELECTED  •  " + RaceConfig.characters[selected_index].character_name


func card_style(selected: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#202b42") if not selected else Color("#293956")
	style.border_color = Color("#ffd65a") if selected else Color("#394761")
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
	RaceConfig.select_player_character(selected_index)
	get_tree().change_scene_to_file("res://VehicleSelect.tscn")


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

