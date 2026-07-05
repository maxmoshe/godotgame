extends StaticBody3D

@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var label: Label3D = $Label3D

var _hits := 0
var _flash_time := 0.0
var _base_material: StandardMaterial3D
var _hit_material: StandardMaterial3D


func _ready() -> void:
	_base_material = StandardMaterial3D.new()
	_base_material.albedo_color = Color("#6c3f2d")
	_hit_material = StandardMaterial3D.new()
	_hit_material.albedo_color = Color("#c98943")
	mesh.material_override = _base_material
	_update_label()


func _process(delta: float) -> void:
	if _flash_time <= 0.0:
		return

	_flash_time -= delta
	if _flash_time <= 0.0:
		mesh.material_override = _base_material


func take_hit(_impact_speed: float) -> void:
	_hits += 1
	_flash_time = 0.18
	_update_label()
	mesh.material_override = _hit_material


func _update_label() -> void:
	label.text = "Target\nHits: %d" % _hits
