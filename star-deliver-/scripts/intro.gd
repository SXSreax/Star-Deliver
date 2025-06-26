extends Node2D

#@onready var sprite = $Sprite2D
var image_paths = [
	"res://assets/Intro Slides/01.png",
	"res://assets/Intro Slides/02.png",
	"res://assets/Intro Slides/03.png",
	"res://assets/Intro Slides/04.png",
	"res://assets/Intro Slides/05.png",
	"res://assets/Intro Slides/06.png",
	"res://assets/Intro Slides/07.png"
]

var current_index = 0
var end_scene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimationPlayer.play("fade in ")
	_start_slideshow()

func _start_slideshow():
	await get_tree().create_timer(1.5).timeout  # ⏳ One-time delay before loop starts
	_update_sprite()
	_start_timer()
	
func _update_sprite():
	$Slide.texture = load(image_paths[current_index])

func _start_timer():
	await get_tree().create_timer(8.5).timeout
	current_index = (current_index + 1) % image_paths.size()
	_update_sprite()
	_start_timer()  # repeat loop

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if current_index == 6: 
		await get_tree().create_timer(8.5).timeout
		get_tree().change_scene_to_file("res://prefabs/Maps/home.tscn")
		
	if Input.is_action_just_pressed("ESC"): 
		_on_skip_pressed()


func _on_skip_pressed() -> void:
	get_tree().change_scene_to_file("res://prefabs/Maps/home.tscn")
