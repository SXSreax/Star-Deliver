extends Node2D

@onready var particles: GPUParticles2D = $Particles

func burst(dir: Vector2 = Vector2.ZERO) -> void:
	if dir != Vector2.ZERO:
		rotation = dir.angle()
	# draw on top of most things
	particles.z_as_relative = false
	particles.z_index = 100
	particles.emitting = true
	particles.finished.connect(queue_free, CONNECT_ONE_SHOT)
