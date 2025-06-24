extends CharacterBody2D

var cd = true
var is_ = false
var tp = true

@onready var teleport_label = $TeleportLabel

func _physics_process(delta: float) -> void:
	if is_: 
		if tp:  
			if cd:
				if Input.is_action_just_pressed("interact"):
					tp = false
					show_teleport_message()
					await fade_teleport_label(3)
					get_tree().change_scene_to_file("res://prefabs/Maps/plain_planet_–_“selari_fields”.tscn")
					

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		is_ = true

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "player":
		is_ = false

func cd_():
	await get_tree().create_timer(0.1).timeout
	cd = true

func show_teleport_message():
	teleport_label.visible = true
	teleport_label.modulate.a = 0.0

func fade_teleport_label(times):
	var duration = 0.5
	var total = times * 2
	for count in total:
		var to_alpha = 1.0 if count % 2 == 0 else 0.0
		var tween = create_tween()
		tween.tween_property(teleport_label, "modulate:a", to_alpha, duration)
		await tween.finished
	teleport_label.visible = false
