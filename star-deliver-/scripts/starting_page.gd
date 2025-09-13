extends Node2D

@onready var Start = $Start
@onready var Exit = $Exit
@onready var Setting = $Setting


func _ready():
	$ColorRect.color.a = 0.0
	AudioManager.play("Start menu")
	Global._set_custom_cursor("res://assets/cursor/finger_cursor.png", 0.1)

func _on_start_pressed() -> void:
	Start.play("start")
	await get_tree().create_timer(0.5).timeout
	$AnimationPlayer.play("Fade out")
	await $AnimationPlayer.animation_finished
	get_tree().change_scene_to_file("res://prefabs/intro.tscn")

func _on_exit_pressed() -> void:
	Exit.play("exit")
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()

func _on_setting_pressed() -> void:
	Setting.play("Setting")
	await get_tree().create_timer(0.5).timeout
