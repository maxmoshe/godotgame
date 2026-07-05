extends Label3D

const LIFE_SECONDS := 0.9
const RISE_SPEED := 1.15

var _age := 0.0
var _base_color := Color.WHITE


func start(damage: int, origin: Vector3, color: Color) -> void:
	text = str(damage)
	global_position = origin + Vector3.UP * 0.42
	_base_color = color
	modulate = color
	outline_modulate = Color(0.0, 0.0, 0.0, 0.78)
	outline_size = 8
	font_size = 42
	pixel_size = 0.012
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true


func _process(delta: float) -> void:
	_age += delta
	global_position += Vector3.UP * RISE_SPEED * delta

	var fade := clampf(_age / LIFE_SECONDS, 0.0, 1.0)
	modulate = Color(_base_color.r, _base_color.g, _base_color.b, 1.0 - fade)
	outline_modulate = Color(0.0, 0.0, 0.0, 0.78 * (1.0 - fade))

	if _age >= LIFE_SECONDS:
		queue_free()
