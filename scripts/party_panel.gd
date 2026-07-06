extends Panel

const PORTRAIT_SIZE := 64

@export var player_name := "David"
@export var player_health := 100
@export var player_max_health := 100
@export var generic_soldier_count := 0

var _named_characters: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_panel()


func get_party_data() -> Dictionary:
	return {
		"player_name": player_name,
		"player_health": player_health,
		"player_max_health": player_max_health,
		"named_characters": _named_characters.duplicate(true),
		"generic_soldier_count": generic_soldier_count
	}


func load_party_data(data: Dictionary) -> void:
	player_name = String(data.get("player_name", player_name))
	player_health = int(data.get("player_health", player_health))
	player_max_health = int(data.get("player_max_health", player_max_health))
	generic_soldier_count = int(data.get("generic_soldier_count", generic_soldier_count))
	_named_characters.clear()
	for character in Array(data.get("named_characters", [])):
		_named_characters.append(Dictionary(character).duplicate(true))
	_rebuild_panel()


func add_generic_soldiers(count: int) -> void:
	generic_soldier_count += maxi(0, count)
	_rebuild_panel()


func add_named_character(character: Dictionary) -> void:
	var character_name := String(character.get("name", "Companion"))
	for existing in _named_characters:
		if String(existing.get("name", "")) == character_name:
			return

	var max_character_health := int(character.get("max_health", 100))
	_named_characters.append({
		"name": character_name,
		"health": int(character.get("health", max_character_health)),
		"max_health": max_character_health
	})
	_rebuild_panel()


func heal_party() -> void:
	player_health = player_max_health
	for character in _named_characters:
		character["max_health"] = maxi(1, int(character.get("max_health", 100)))
		character["health"] = int(character["max_health"])
	_rebuild_panel()


func _rebuild_panel() -> void:
	for child in get_children():
		child.free()
	_build_panel()


func _build_panel() -> void:
	add_theme_stylebox_override("panel", _make_panel_style())

	var title := Label.new()
	title.text = "Party"
	title.position = Vector2(22.0, 18.0)
	title.size = Vector2(250.0, 34.0)
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#f0dda5"))
	add_child(title)

	var close_hint := Label.new()
	close_hint.text = "P"
	close_hint.position = Vector2(356.0, 24.0)
	close_hint.size = Vector2(36.0, 24.0)
	close_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	close_hint.add_theme_font_size_override("font_size", 17)
	close_hint.add_theme_color_override("font_color", Color("#d6c391"))
	add_child(close_hint)

	var list := VBoxContainer.new()
	list.position = Vector2(22.0, 68.0)
	list.size = Vector2(370.0, 250.0)
	list.add_theme_constant_override("separation", 12)
	add_child(list)

	list.add_child(_make_named_row(player_name, "You", player_health, player_max_health, _make_portrait_texture(Color("#1f596f"), Color("#f1d28a"))))

	for character in _named_characters:
		list.add_child(_make_named_row(
			String(character.get("name", "Companion")),
			"Companion",
			int(character.get("health", 1)),
			int(character.get("max_health", 1)),
			_make_portrait_texture(Color("#455f3f"), Color("#d1b06f"))
		))

	if _named_characters.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No named companions"
		empty_label.size = Vector2(370.0, 24.0)
		empty_label.add_theme_font_size_override("font_size", 16)
		empty_label.add_theme_color_override("font_color", Color("#a99772"))
		list.add_child(empty_label)

	list.add_child(_make_soldier_row("Soldiers", generic_soldier_count, _make_portrait_texture(Color("#6a4730"), Color("#c9ab75"))))


func _make_named_row(character_name: String, role_text: String, health: int, max_health: int, portrait: Texture2D) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(370.0, 72.0)
	row.add_theme_constant_override("separation", 14)

	var image := TextureRect.new()
	image.texture = portrait
	image.custom_minimum_size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(image)

	var details := VBoxContainer.new()
	details.custom_minimum_size = Vector2(285.0, 68.0)
	details.add_theme_constant_override("separation", 4)
	row.add_child(details)

	var name_label := Label.new()
	name_label.text = character_name
	name_label.size = Vector2(285.0, 24.0)
	name_label.add_theme_font_size_override("font_size", 21)
	name_label.add_theme_color_override("font_color", Color("#f0dda5"))
	details.add_child(name_label)

	var role_label := Label.new()
	role_label.text = role_text
	role_label.size = Vector2(285.0, 20.0)
	role_label.add_theme_font_size_override("font_size", 14)
	role_label.add_theme_color_override("font_color", Color("#bca979"))
	details.add_child(role_label)

	var health_bar := ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(270.0, 18.0)
	health_bar.min_value = 0.0
	health_bar.max_value = maxf(1.0, float(max_health))
	health_bar.value = clampf(float(health), 0.0, health_bar.max_value)
	health_bar.show_percentage = false
	health_bar.add_theme_font_size_override("font_size", 12)
	health_bar.add_theme_color_override("font_color", Color("#f9edcf"))
	health_bar.add_theme_stylebox_override("background", _make_bar_background_style())
	health_bar.add_theme_stylebox_override("fill", _make_bar_fill_style())
	health_bar.tooltip_text = "%d/%d health" % [health, max_health]
	details.add_child(health_bar)

	var health_label := Label.new()
	health_label.text = "%d/%d health" % [health, max_health]
	health_label.size = Vector2(270.0, 18.0)
	health_label.add_theme_font_size_override("font_size", 14)
	health_label.add_theme_color_override("font_color", Color("#d6c391"))
	details.add_child(health_label)

	return row


func _make_soldier_row(group_name: String, count: int, portrait: Texture2D) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(370.0, 68.0)
	row.add_theme_constant_override("separation", 14)

	var image := TextureRect.new()
	image.texture = portrait
	image.custom_minimum_size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(image)

	var details := VBoxContainer.new()
	details.custom_minimum_size = Vector2(285.0, 64.0)
	details.add_theme_constant_override("separation", 6)
	row.add_child(details)

	var name_label := Label.new()
	name_label.text = group_name
	name_label.size = Vector2(285.0, 24.0)
	name_label.add_theme_font_size_override("font_size", 21)
	name_label.add_theme_color_override("font_color", Color("#f0dda5"))
	details.add_child(name_label)

	var count_label := Label.new()
	count_label.text = "Count: %d" % count
	count_label.size = Vector2(285.0, 24.0)
	count_label.add_theme_font_size_override("font_size", 18)
	count_label.add_theme_color_override("font_color", Color("#d6c391"))
	details.add_child(count_label)

	return row


func _make_portrait_texture(tunic_color: Color, skin_color: Color) -> ImageTexture:
	var image := Image.create(PORTRAIT_SIZE, PORTRAIT_SIZE, false, Image.FORMAT_RGBA8)
	image.fill(Color("#261d15"))

	for y in range(PORTRAIT_SIZE):
		for x in range(PORTRAIT_SIZE):
			var pos := Vector2(float(x), float(y))
			var center := Vector2(32.0, 23.0)
			if pos.distance_to(center) <= 13.0:
				image.set_pixel(x, y, skin_color)
			elif absf(pos.x - 32.0) <= 17.0 and pos.y >= 36.0 and pos.y <= 58.0:
				image.set_pixel(x, y, tunic_color)
			elif absf(pos.x - 32.0) <= 8.0 and pos.y >= 31.0 and pos.y <= 43.0:
				image.set_pixel(x, y, skin_color.darkened(0.08))
			elif pos.distance_to(center + Vector2(0.0, -4.0)) <= 15.0 and pos.y < 20.0:
				image.set_pixel(x, y, Color("#4a2f1d"))

	for x in range(PORTRAIT_SIZE):
		image.set_pixel(x, 0, Color("#b79a5e"))
		image.set_pixel(x, PORTRAIT_SIZE - 1, Color("#6f5b37"))
	for y in range(PORTRAIT_SIZE):
		image.set_pixel(0, y, Color("#b79a5e"))
		image.set_pixel(PORTRAIT_SIZE - 1, y, Color("#6f5b37"))

	return ImageTexture.create_from_image(image)


func _make_panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.09, 0.065, 0.95)
	style.border_color = Color("#b79a5e")
	style.set_border_width_all(3)
	style.set_corner_radius_all(6)
	style.content_margin_left = 18.0
	style.content_margin_top = 18.0
	style.content_margin_right = 18.0
	style.content_margin_bottom = 18.0
	return style


func _make_bar_background_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#2b241b")
	style.border_color = Color("#6f5b37")
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	return style


func _make_bar_fill_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#7c3f32")
	style.set_corner_radius_all(3)
	return style
