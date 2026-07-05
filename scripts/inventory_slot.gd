extends Button

var inventory_panel
var slot_index := -1


func _get_drag_data(_at_position: Vector2):
	if inventory_panel == null:
		return null
	if not inventory_panel.has_item(slot_index):
		return null

	var drag_data: Dictionary = inventory_panel.get_drag_data_for_slot(slot_index)
	set_drag_preview(inventory_panel.make_drag_preview(drag_data))
	return drag_data


func _can_drop_data(_at_position: Vector2, data) -> bool:
	return inventory_panel != null and inventory_panel.can_drop_data_on_slot(slot_index, data)


func _drop_data(_at_position: Vector2, data) -> void:
	if inventory_panel != null:
		inventory_panel.drop_data_on_slot(slot_index, data)
