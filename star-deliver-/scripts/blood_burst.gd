extends Node2D

# Cached reference to the particles node in this scene.
@onready var particles: GPUParticles2D = $Particles


# Freeze all motion so the burst stays exactly where it's spawned.
# WHAT: Zeroes gravity and every velocity channel.
# WHY: We want a visual pop, not drifting or falling particles.
# HOW: Ensure a ParticleProcessMaterial exists, then set motion props to 0.
func _freeze_particles() -> void:
	var pm: ParticleProcessMaterial = particles.process_material as ParticleProcessMaterial
	if pm == null:
		pm = ParticleProcessMaterial.new()
		particles.process_material = pm

	# No falling.
	pm.gravity = Vector3.ZERO

	# No translational travel of any kind.
	pm.directional_velocity_min = 0.0
	pm.directional_velocity_max = 0.0
	pm.radial_velocity_min = 0.0
	pm.radial_velocity_max = 0.0
	pm.orbit_velocity_min = 0.0
	pm.orbit_velocity_max = 0.0


# Play a single burst. If 'dir' is provided, rotate the node so the effect
# faces that direction (purely visual—particles still don't move).
func burst(dir: Vector2 = Vector2.ZERO) -> void:
	if dir != Vector2.ZERO:
		rotation = dir.angle()

	# Draw above most things.
	particles.z_as_relative = false
	particles.z_index = 100

	# One-shot pop.
	particles.one_shot = true
	particles.explosiveness = 1.0

	# Stop any drift/fall before triggering.
	_freeze_particles()

	# Retrigger emission (toggle off → on).
	particles.emitting = false
	particles.emitting = true

	# Auto-cleanup when the burst finishes.
	particles.finished.connect(queue_free, CONNECT_ONE_SHOT)
