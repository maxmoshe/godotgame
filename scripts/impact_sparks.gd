extends Node3D

const SPARK_LIFETIME := 0.95
const LIGHT_SPARK_LIFETIME := 0.42
const FULL_PARTICLE_AMOUNT := 90
const LIGHT_PARTICLE_AMOUNT := 22
const FULL_DEBRIS_COUNT := 34

var _age := 0.0
var _lifetime := SPARK_LIFETIME
var _spark_nodes: Array = []
var _spark_velocities: Array[Vector3] = []
var _spark_lifetimes: Array[float] = []
var _heat_mark: MeshInstance3D
var _heat_material: StandardMaterial3D
var _flash_light: OmniLight3D


func burst(position: Vector3, normal: Vector3 = Vector3.UP, full_detail := true) -> void:
	global_position = position
	_lifetime = SPARK_LIFETIME if full_detail else LIGHT_SPARK_LIFETIME
	var burst_direction := normal.normalized()
	if burst_direction.length() < 0.01:
		burst_direction = Vector3.UP

	_add_heat_mark(burst_direction, full_detail)
	if full_detail:
		_add_flash_light()
		_add_visible_debris(burst_direction)
	var particles := GPUParticles3D.new()
	particles.one_shot = true
	particles.amount = FULL_PARTICLE_AMOUNT if full_detail else LIGHT_PARTICLE_AMOUNT
	particles.lifetime = 0.62 if full_detail else 0.26
	particles.explosiveness = 0.96
	particles.randomness = 0.72 if full_detail else 0.48
	particles.emitting = true

	var material := ParticleProcessMaterial.new()
	material.direction = burst_direction
	material.spread = 72.0 if full_detail else 46.0
	material.initial_velocity_min = 4.5 if full_detail else 2.6
	material.initial_velocity_max = 11.0 if full_detail else 6.0
	material.gravity = Vector3(0.0, -9.8, 0.0)
	material.scale_min = 0.13 if full_detail else 0.08
	material.scale_max = 0.24 if full_detail else 0.15
	material.color = Color("#ffd16a")
	particles.process_material = material

	var mesh := SphereMesh.new()
	mesh.radius = 0.065 if full_detail else 0.04
	mesh.height = 0.13
	var spark_material := _spark_material()
	mesh.material = spark_material
	particles.draw_pass_1 = mesh
	add_child(particles)


func _process(delta: float) -> void:
	_age += delta
	_update_heat_mark()
	_update_visible_debris(delta)
	if _age >= _lifetime:
		queue_free()


func _add_heat_mark(surface_normal: Vector3, full_detail: bool) -> void:
	_heat_mark = MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.34 if full_detail else 0.22
	mesh.bottom_radius = mesh.top_radius
	mesh.height = 0.014
	mesh.radial_segments = 24 if full_detail else 10
	_heat_mark.mesh = mesh
	_heat_mark.transform.basis = _basis_from_y_axis(surface_normal)
	_heat_material = StandardMaterial3D.new()
	_heat_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_heat_material.albedo_color = Color(1.0, 0.45, 0.12, 0.72)
	_heat_material.emission_enabled = true
	_heat_material.emission = Color("#ff7a22")
	_heat_material.emission_energy_multiplier = 3.4
	_heat_mark.material_override = _heat_material
	add_child(_heat_mark)


func _add_flash_light() -> void:
	_flash_light = OmniLight3D.new()
	_flash_light.light_color = Color("#ffbf5a")
	_flash_light.light_energy = 4.6
	_flash_light.omni_range = 3.2
	add_child(_flash_light)


func _add_visible_debris(burst_direction: Vector3) -> void:
	var material := _spark_material()
	for i in range(FULL_DEBRIS_COUNT):
		var spark := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = randf_range(0.045, 0.085)
		mesh.height = mesh.radius * 2.0
		spark.mesh = mesh
		spark.material_override = material
		add_child(spark)

		var scatter := Vector3(
			randf_range(-1.0, 1.0),
			randf_range(0.0, 1.0),
			randf_range(-1.0, 1.0)
		).normalized()
		var velocity := (burst_direction * 0.68 + scatter * 0.72 + Vector3.UP * 0.24).normalized()
		velocity *= randf_range(3.8, 9.5)

		_spark_nodes.append(spark)
		_spark_velocities.append(velocity)
		_spark_lifetimes.append(randf_range(0.34, 0.82))


func _update_visible_debris(delta: float) -> void:
	for i in range(_spark_nodes.size() - 1, -1, -1):
		var spark := _spark_nodes[i] as MeshInstance3D
		var velocity := _spark_velocities[i]
		velocity.y -= 12.0 * delta
		spark.position += velocity * delta
		_spark_velocities[i] = velocity

		var life_left := _spark_lifetimes[i] - delta
		_spark_lifetimes[i] = life_left
		var scale_factor := clampf(life_left / 0.82, 0.12, 1.0)
		spark.scale = Vector3.ONE * scale_factor

		if life_left <= 0.0:
			spark.queue_free()
			_spark_nodes.remove_at(i)
			_spark_velocities.remove_at(i)
			_spark_lifetimes.remove_at(i)


func _update_heat_mark() -> void:
	var fade := clampf(1.0 - (_age / _lifetime), 0.0, 1.0)
	var eased_fade := fade * fade

	if _heat_mark != null:
		var mark_scale := lerpf(1.35, 0.55, 1.0 - fade)
		_heat_mark.scale = Vector3(mark_scale, 1.0, mark_scale)

	if _heat_material != null:
		_heat_material.albedo_color = Color(1.0, 0.45, 0.12, 0.72 * eased_fade)
		_heat_material.emission_energy_multiplier = 3.4 * eased_fade

	if _flash_light != null:
		_flash_light.light_energy = 4.6 * eased_fade


func _spark_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("#ffd16a")
	material.emission_enabled = true
	material.emission = Color("#ff9f32")
	material.emission_energy_multiplier = 2.4
	return material


func _basis_from_y_axis(y_axis: Vector3) -> Basis:
	var y := y_axis.normalized()
	var helper := Vector3.UP
	if absf(y.dot(helper)) > 0.92:
		helper = Vector3.RIGHT

	var x := helper.cross(y).normalized()
	var z := x.cross(y).normalized()
	return Basis(x, y, z)
