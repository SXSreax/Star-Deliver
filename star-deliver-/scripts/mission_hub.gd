extends Node2D

var cd = true
var is_ = false

@onready var mission_label = $Label

func _physics_process(delta: float) -> void:
	if is_: 
		if cd:
			if Input.is_action_just_pressed("interact"):
				cd_()
				show_mission_message()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		is_ = true


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		is_ = false
		

func cd_():
	cd = false
	await get_tree().create_timer(3).timeout
	cd = true

func show_mission_message():
	mission_label.visible = true
	mission_label.modulate.a = 0.0
	fade_mission_label(3)

func fade_mission_label(times):
	var duration = 0.5
	var total = times * 2
	for count in total:
		var to_alpha = 1.0 if count % 2 == 0 else 0.0
		var tween = create_tween()
		tween.tween_property(mission_label, "modulate:a", to_alpha, duration)
		await tween.finished
	mission_label.visible = false
