extends Node3D

const QuaterniusSoldierVisualScene := preload("res://scenes/actors/quaternius_soldier_visual.tscn")


func _ready() -> void:
	_add_light()
	_add_camera()
	_add_ground()
	_add_visual(Vector3(-1.7, 0.0, 0.0), "sword", true)
	var archer := _add_visual(Vector3(0.0, 0.0, 0.0), "bow", false)
	if archer != null and archer.has_method("play_attack"):
		archer.call("play_attack", "bow")
	var backing_archer := _add_visual(Vector3(1.7, 0.0, 0.0), "bow", false)
	if backing_archer != null and backing_archer.has_method("play_walk"):
		backing_archer.call("play_walk", 3.4, true)


func _add_visual(position: Vector3, weapon_type: String, has_shield: bool) -> Node3D:
	var visual := QuaterniusSoldierVisualScene.instantiate() as Node3D
	if visual == null:
		push_error("Could not instantiate Quaternius soldier visual scene.")
		return null
	visual.position = position
	if visual.has_method("setup_visual"):
		var loaded := bool(visual.call("setup_visual", "friendly", weapon_type, has_shield))
		if not loaded:
			push_error("Could not load Quaternius visual for %s." % weapon_type)
			visual.free()
			return null
	add_child(visual)
	return visual


func _add_light() -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-48.0, -34.0, 0.0)
	sun.light_energy = 2.4
	add_child(sun)


func _add_camera() -> void:
	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.position = Vector3(0.0, 1.35, 4.4)
	camera.rotation_degrees = Vector3(-8.0, 0.0, 0.0)
	camera.current = true
	add_child(camera)


func _add_ground() -> void:
	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(5.0, 3.0)
	ground.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#50604a")
	material.roughness = 0.9
	ground.material_override = material
	add_child(ground)
