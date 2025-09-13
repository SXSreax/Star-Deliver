extends Node2D

@onready var particles: GPUParticles2D = $Particles

# Zero-out gravity & all velocity sources so the burst plays in place.
func _freeze_particles() -> void:
	var pm := particles.process_material as ParticleProcessMaterial
	if pm == null:
		pm = ParticleProcessMaterial.new()
		particles.process_material = pm

	# No falling
	pm.gravity = Vector3.ZERO

	# No travel of any kind
	pm.directional_velocity_min = 0.0
	pm.directional_velocity_max = 0.0
	pm.radial_velocity_min = 0.0
	pm.radial_velocity_max = 0.0
	pm.orbit_velocity_min = 0.0
	pm.orbit_velocity_max = 0.0

func burst(dir: Vector2 = Vector2.ZERO) -> void:
	if dir != Vector2.ZERO:
		rotation = dir.angle()

	# draw on top of most things
	particles.z_as_relative = false
	particles.z_index = 100

	# one-shot pop
	particles.one_shot = true
	particles.explosiveness = 1.0

	# stop drift/fall
	_freeze_particles()

	# (re)trigger the emission
	particles.emitting = false
	particles.emitting = true

	particles.finished.connect(queue_free, CONNECT_ONE_SHOT)
