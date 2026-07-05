extends Panel

const InventorySlotButton := preload("res://scripts/inventory_slot.gd")

@export var columns := 5
@export var rows := 4
@export var slot_size := 58
@export var weight_capacity := 45.0
@export var title_text := "Inventory"
@export var seed_profile := "player"

var _slot_buttons: Array = []
var _slots: Array = []
var _weight_label: Label

var _item_defs := {
	"barley_bread": {
		"name": "Barley Bread",
		"short": "Bread",
		"stackable": true,
		"max_stack": 12,
		"weight": 0.4,
		"color": Color("#9f7a3f")
	},
	"sling_stones": {
		"name": "Sling Stones",
		"short": "Stones",
		"stackable": true,
		"max_stack": 30,
		"weight": 0.08,
		"color": Color("#697078")
	},
	"bronze_dagger": {
		"name": "Bronze Dagger",
		"short": "Dagger",
		"stackable": false,
		"max_stack": 1,
		"weight": 1.2,
		"color": Color("#b5793d")
	},
	"olive_oil": {
		"name": "Olive Oil",
		"short": "Oil",
		"stackable": true,
		"max_stack": 8,
		"weight": 0.7,
		"color": Color("#7f8a42")
	},
	"wool_cloth": {
		"name": "Wool Cloth",
		"short": "Wool",
		"stackable": true,
		"max_stack": 10,
		"weight": 0.5,
		"color": Color("#8d8172")
	}
}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_slots()
	_seed_items()
	_refresh_slots()


func add_item(item_id: String, amount: int = 1) -> int:
	if not _item_defs.has(item_id):
		return amount

	var remaining := amount
	var item_def: Dictionary = _item_defs[item_id]

	if bool(item_def["stackable"]):
		for slot in _slots:
			if remaining <= 0:
				break
			if slot.is_empty() or String(slot.get("id", "")) != item_id:
				continue

			var max_stack := int(item_def["max_stack"])
			var space := max_stack - int(slot["amount"])
			var moved := mini(space, remaining)
			slot["amount"] = int(slot["amount"]) + moved
			remaining -= moved

	while remaining > 0:
		var empty_index := _first_empty_slot()
		if empty_index == -1:
			break

		var stack_amount := 1
		if bool(item_def["stackable"]):
			stack_amount = mini(int(item_def["max_stack"]), remaining)

		_slots[empty_index] = {
			"id": item_id,
			"amount": stack_amount
		}
		remaining -= stack_amount

	_refresh_slots()
	return remaining


func clear_inventory() -> void:
	for i in range(_slots.size()):
		_slots[i] = {}
	_refresh_slots()


func has_item(slot_index: int) -> bool:
	return _is_valid_slot(slot_index) and not Dictionary(_slots[slot_index]).is_empty()


func get_drag_data_for_slot(slot_index: int) -> Dictionary:
	if not has_item(slot_index):
		return {}

	var slot: Dictionary = _slots[slot_index]
	return {
		"source_inventory": self,
		"source_slot": slot_index,
		"item_id": String(slot["id"]),
		"amount": int(slot["amount"])
	}


func get_slot_copy(slot_index: int) -> Dictionary:
	if not has_item(slot_index):
		return {}
	return Dictionary(_slots[slot_index]).duplicate()


func set_slot(slot_index: int, slot_data: Dictionary) -> void:
	if not _is_valid_slot(slot_index):
		return
	_slots[slot_index] = slot_data.duplicate()
	_refresh_slots()


func clear_slot(slot_index: int) -> void:
	if not _is_valid_slot(slot_index):
		return
	_slots[slot_index] = {}
	_refresh_slots()


func can_drop_data_on_slot(target_index: int, data) -> bool:
	if not _is_valid_slot(target_index):
		return false
	if typeof(data) != TYPE_DICTIONARY:
		return false

	var drag_data: Dictionary = data
	if not drag_data.has("source_inventory") or not drag_data.has("source_slot"):
		return false

	var source_inventory = drag_data["source_inventory"]
	if source_inventory == null or not source_inventory.has_method("has_item"):
		return false

	return source_inventory.has_item(int(drag_data["source_slot"]))


func drop_data_on_slot(target_index: int, data) -> void:
	if not can_drop_data_on_slot(target_index, data):
		return

	var drag_data: Dictionary = data
	var source_inventory = drag_data["source_inventory"]
	var source_index := int(drag_data["source_slot"])

	if source_inventory == self:
		_move_stack(source_index, target_index)
	else:
		_receive_external_stack(source_inventory, source_index, target_index)


func make_drag_preview(data: Dictionary) -> Control:
	var preview := Panel.new()
	preview.custom_minimum_size = Vector2(slot_size, slot_size)
	preview.add_theme_stylebox_override("panel", _make_slot_style(_item_color(String(data.get("item_id", "")))))

	var label := Label.new()
	label.position = Vector2(5.0, 7.0)
	label.size = Vector2(slot_size - 10.0, slot_size - 10.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color("#f9edcf"))
	label.text = _drag_preview_text(data)
	preview.add_child(label)

	return preview


func _build_slots() -> void:
	add_theme_stylebox_override("panel", _make_panel_style())

	var title := Label.new()
	title.text = title_text
	title.position = Vector2(22.0, 18.0)
	title.size = Vector2(250.0, 34.0)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color("#f0dda5"))
	add_child(title)

	_weight_label = Label.new()
	_weight_label.position = Vector2(214.0, 24.0)
	_weight_label.size = Vector2(168.0, 24.0)
	_weight_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_weight_label.add_theme_font_size_override("font_size", 16)
	_weight_label.add_theme_color_override("font_color", Color("#d6c391"))
	add_child(_weight_label)

	var grid := GridContainer.new()
	grid.columns = columns
	grid.position = Vector2(22.0, 68.0)
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	add_child(grid)

	for i in range(columns * rows):
		_slots.append({})

		var slot_button = InventorySlotButton.new()
		slot_button.inventory_panel = self
		slot_button.slot_index = i
		slot_button.custom_minimum_size = Vector2(slot_size, slot_size)
		slot_button.focus_mode = Control.FOCUS_NONE
		slot_button.mouse_filter = Control.MOUSE_FILTER_STOP
		slot_button.add_theme_font_size_override("font_size", 13)
		slot_button.add_theme_stylebox_override("normal", _make_slot_style(Color("#2b241b")))
		slot_button.add_theme_stylebox_override("hover", _make_slot_style(Color("#403522")))
		slot_button.add_theme_stylebox_override("pressed", _make_slot_style(Color("#1f1a14")))
		grid.add_child(slot_button)
		_slot_buttons.append(slot_button)


func _seed_items() -> void:
	match seed_profile:
		"player":
			add_item("barley_bread", 4)
			add_item("sling_stones", 18)
			add_item("bronze_dagger", 1)
		"market":
			add_item("barley_bread", 8)
			add_item("olive_oil", 4)
			add_item("wool_cloth", 6)
			add_item("sling_stones", 12)
		_:
			pass


func _refresh_slots() -> void:
	for i in range(_slot_buttons.size()):
		var button: Button = _slot_buttons[i]
		var slot: Dictionary = _slots[i]

		if slot.is_empty():
			button.text = ""
			button.tooltip_text = ""
			button.add_theme_stylebox_override("normal", _make_slot_style(Color("#2b241b")))
			continue

		var item_def: Dictionary = _item_defs[String(slot["id"])]
		var item_name := String(item_def["name"])
		var amount := int(slot["amount"])
		var stack_weight := float(item_def["weight"]) * float(amount)
		button.tooltip_text = "%s\nWeight: %.2f" % [item_name, stack_weight]
		button.text = String(item_def["short"])

		if amount > 1:
			button.text += "\nx%d" % amount

		button.add_theme_stylebox_override("normal", _make_slot_style(item_def["color"]))

	_update_weight_label()


func _move_stack(source_index: int, target_index: int) -> void:
	if source_index == target_index:
		return
	if not has_item(source_index) or not _is_valid_slot(target_index):
		return

	var source_slot: Dictionary = _slots[source_index]
	var target_slot: Dictionary = _slots[target_index]

	if target_slot.is_empty():
		_slots[target_index] = source_slot.duplicate()
		_slots[source_index] = {}
		_refresh_slots()
		return

	var source_id := String(source_slot["id"])
	var target_id := String(target_slot["id"])
	var source_def: Dictionary = _item_defs[source_id]

	if source_id == target_id and bool(source_def["stackable"]):
		var max_stack := int(source_def["max_stack"])
		var space := max_stack - int(target_slot["amount"])
		var moved := mini(space, int(source_slot["amount"]))

		if moved > 0:
			target_slot["amount"] = int(target_slot["amount"]) + moved
			source_slot["amount"] = int(source_slot["amount"]) - moved
			if int(source_slot["amount"]) <= 0:
				_slots[source_index] = {}

			_refresh_slots()
			return

	_slots[source_index] = target_slot.duplicate()
	_slots[target_index] = source_slot.duplicate()
	_refresh_slots()


func _receive_external_stack(source_inventory, source_index: int, target_index: int) -> void:
	if not source_inventory.has_item(source_index) or not _is_valid_slot(target_index):
		return

	var source_slot: Dictionary = source_inventory.get_slot_copy(source_index)
	var target_slot: Dictionary = _slots[target_index]

	if target_slot.is_empty():
		_slots[target_index] = source_slot.duplicate()
		source_inventory.clear_slot(source_index)
		_refresh_slots()
		return

	var source_id := String(source_slot["id"])
	var target_id := String(target_slot["id"])
	var source_def: Dictionary = _item_defs[source_id]

	if source_id == target_id and bool(source_def["stackable"]):
		var max_stack := int(source_def["max_stack"])
		var space := max_stack - int(target_slot["amount"])
		var moved := mini(space, int(source_slot["amount"]))

		if moved > 0:
			target_slot["amount"] = int(target_slot["amount"]) + moved
			source_slot["amount"] = int(source_slot["amount"]) - moved
			source_inventory.set_slot(source_index, source_slot)
			if int(source_slot["amount"]) <= 0:
				source_inventory.clear_slot(source_index)

			_refresh_slots()
			return

	source_inventory.set_slot(source_index, target_slot)
	_slots[target_index] = source_slot.duplicate()
	_refresh_slots()


func _first_empty_slot() -> int:
	for i in range(_slots.size()):
		if Dictionary(_slots[i]).is_empty():
			return i
	return -1


func _is_valid_slot(slot_index: int) -> bool:
	return slot_index >= 0 and slot_index < _slots.size()


func _total_weight() -> float:
	var weight := 0.0
	for slot in _slots:
		if Dictionary(slot).is_empty():
			continue

		var item_def: Dictionary = _item_defs[String(slot["id"])]
		weight += float(item_def["weight"]) * float(slot["amount"])
	return weight


func _update_weight_label() -> void:
	if _weight_label == null:
		return

	var total := _total_weight()
	_weight_label.text = "%.1f / %.1f weight" % [total, weight_capacity]
	_weight_label.add_theme_color_override("font_color", Color("#d6c391") if total <= weight_capacity else Color("#d7835f"))


func _drag_preview_text(data: Dictionary) -> String:
	var item_id := String(data.get("item_id", ""))
	if not _item_defs.has(item_id):
		return ""

	var item_def: Dictionary = _item_defs[item_id]
	var text := String(item_def["short"])
	var amount := int(data.get("amount", 1))
	if amount > 1:
		text += "\nx%d" % amount
	return text


func _item_color(item_id: String) -> Color:
	if not _item_defs.has(item_id):
		return Color("#2b241b")
	return _item_defs[item_id]["color"]


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


func _make_slot_style(fill_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill_color
	style.border_color = Color("#6f5b37")
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	return style
