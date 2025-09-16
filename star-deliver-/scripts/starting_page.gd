extends Node2D

# --- node refs --------------------------------------------------------------
@onready var start_btn: AnimatedSprite2D   = $Start
@onready var exit_btn: AnimatedSprite2D    = $Exit
@onready var setting_btn: AnimatedSprite2D = $Setting
@onready var fade_rect: ColorRect          = $ColorRect
@onready var anim_player: AnimationPlayer  = $AnimationPlayer

# --- lifecycle --------------------------------------------------------------
func _ready() -> void:
	# Start menu should fade in fully visible, so begin transparent
	fade_rect.color.a = 0.0
	
	# Play background music for the start menu
	AudioManager.play("Start menu")
	
	# Use finger cursor for button-style navigation
	Global._set_custom_cursor("res://assets/cursor/finger_cursor.png", 0.1)

# --- button actions ---------------------------------------------------------
func _on_start_pressed() -> void:
	# Play "start" button animation before transitioning
	start_btn.play("start")
	await get_tree().create_timer(0.5).timeout
	
	# Fade out screen and then load intro scene
	anim_player.play("Fade out")
	await anim_player.animation_finished
	get_tree().change_scene_to_file("res://prefabs/intro.tscn")

func _on_exit_pressed() -> void:
	# Play "exit" button animation before quitting game
	exit_btn.play("exit")
	await get_tree().create_timer(0.5).timeout
	get_tree().quit()

func _on_setting_pressed() -> void:
	# Play "setting" button animation (opens settings menu later?)
	setting_btn.play("Setting")
	await get_tree().create_timer(0.5).timeout
