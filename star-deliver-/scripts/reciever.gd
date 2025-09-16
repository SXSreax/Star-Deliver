extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var mission_label: Label = $Label

var did_player_enter: bool = false
var counter: int = 0
var map_progress: int = 1  # Start at 1, or load from save

func _ready() -> void:
	# Pick receiver sprite by scene name.
	var current_scene: String = get_tree().current_scene.name
	if current_scene == "DesertPlanet":
		sprite.play("desert_receiver")
	elif current_scene == "IcePlanet":
		sprite.play("ice_receiver")
	elif current_scene == "PlainPlanet":
		sprite.play("plain_receiver")
	elif current_scene == "LavaPlanet":
		sprite.play("lave_receiver")
	else:
		sprite.play("jungle_reciever")


func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		did_player_enter = true
		print("you entered")


func _on_area_2d_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		did_player_enter = false
		print("you exit")


func _physics_process(delta: float) -> void:
	# Interact once when player is in range.
	if did_player_enter and Input.is_action_just_pressed("interact"):
		show_mission_complete_message()


func show_mission_complete_message() -> void:
	# Show + fade the mission message, then progress map once.
	mission_label.visible = true
	mission_label.modulate.a = 0.0
	await fade_mission_label(3)
	mission_label.visible = false

	counter += 1
	if counter == 1:
		Global.map_progress += 1
		await get_tree().create_timer(1.0).timeout
		get_tree().change_scene_to_file("res://prefabs/Maps/home.tscn")


func fade_mission_label(times: int) -> void:
	# Blink alpha in/out `times` times (on+off per cycle).
	var duration: float = 0.5
	var total: int = times * 2
	for count in range(total):
		var to_alpha: float = 1.0
		if count % 2 != 0:
			to_alpha = 0.0
		var tween: Tween = create_tween()
		tween.tween_property(mission_label, "modulate:a", to_alpha, duration)
		await tween.finished
