extends Node2D

# --- Configuration ---
var max_distance: float = 500.0  # Maximum travel range before despawn.
var speed: float = 700.0         # Units per second.

# --- Runtime state ---
var start_position: Vector2      # Spawn origin, used for range check.
var pos: Vector2                 # Initial spawn position (to be set externally).
var rota: float                  # Initial rotation in radians (to be set externally).
var dir: float                   # Travel direction in radians (to be set externally).


func _ready() -> void:
	# Apply externally assigned spawn properties.
	global_position = pos
	global_rotation = rota
	start_position = global_position

	# Tag for easy group handling (collision checks, cleanup, etc.).
	add_to_group("bullets")


func _physics_process(delta: float) -> void:
	# Move straight in assigned direction at fixed speed.
	var velocity: Vector2 = Vector2(speed, 0).rotated(dir)
	global_position += velocity * delta

	# Despawn when exceeding max range.
	if global_position.distance_to(start_position) > max_distance:
		queue_free()
