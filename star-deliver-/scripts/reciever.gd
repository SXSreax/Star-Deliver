extends CharacterBody2D

var did_player_enter = false
var counter = 0
@onready var mission_label = $Label

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		did_player_enter = true
		print("you entered")

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		did_player_enter = false
		print("you exit")

func _physics_process(delta: float) -> void:
	if did_player_enter and Input.is_action_just_pressed("interact"):
		show_mission_complete_message()

func show_mission_complete_message():
	mission_label.visible = true
	mission_label.modulate.a = 0.0
	await fade_mission_label(3)
	mission_label.visible = false
	counter += 1
	if counter == 1: 
		await get_tree().create_timer(1).timeout
		get_tree().change_scene_to_file("res://prefabs/Maps/home.tscn")

func fade_mission_label(times):
	var duration = 0.5
	var total = times * 2
	for count in total:
		var to_alpha = 1.0 if count % 2 == 0 else 0.0
		var tween = create_tween()
		tween.tween_property(mission_label, "modulate:a", to_alpha, duration)
		await tween.finished
