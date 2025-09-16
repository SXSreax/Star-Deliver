extends Camera2D

# --- Configuration ---
@export var shake_fade: float = 1.0  # How quickly the shake fades (higher = faster).

# --- Runtime state ---
var _shake_strength: float = 0.0     # Current shake intensity.


# Trigger a shake with a given strength.
func trigger_shake(strength: float) -> void:
	_shake_strength = strength


func _process(delta: float) -> void:
	if _shake_strength > 0.0:
		# Smoothly reduce shake strength over time.
		_shake_strength = lerp(_shake_strength, 0.0, shake_fade * delta)

		# Apply a random offset within the current strength range.
		offset = Vector2(
			randf_range(-_shake_strength, _shake_strength),
			randf_range(-_shake_strength, _shake_strength)
		)
	else:
		# Reset offset once shake has fully decayed.
		offset = Vector2.ZERO
