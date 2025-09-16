extends Node2D

# --- State ------------------------------------------------------------------
var cd: bool = true                # Cooldown flag for interaction
var is_: bool = false              # True when player is inside trigger

# --- Nodes ------------------------------------------------------------------
@onready var mission_label: Label = $Label


func _physics_process(delta: float) -> void:
	# Allow interaction only when player is inside area and not on cooldown
	if is_ and cd:
		if Input.is_action_just_pressed("interact"):
			AudioManager.play_sfx("interact")
			cd_()
			show_mission_message()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		is_ = true


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		is_ = false


# --- Cooldown ---------------------------------------------------------------
func cd_() -> void:
	cd = false
	await get_tree().create_timer(3.0).timeout
	cd = true


# --- Mission Label ----------------------------------------------------------
func show_mission_message() -> void:
	mission_label.visible = true
	mission_label.modulate.a = 0.0
	fade_mission_label(3)


func fade_mission_label(times: int) -> void:
	var duration: float = 0.5
	var total: int = times * 2

	# Blink label in/out using tweens
	for count in range(total):
		var to_alpha: float = 1.0 if count % 2 == 0 else 0.0
		var tween: Tween = create_tween()
		tween.tween_property(mission_label, "modulate:a", to_alpha, duration)
		await tween.finished

	mission_label.visible = false
