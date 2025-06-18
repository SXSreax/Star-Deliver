extends CharacterBody2D
@onready var hotbar: HBoxContainer = $UI/Hotbar

@export var speed = 400

func get_input():
	var input_direction = Input.get_vector("left","right","up","down")
	velocity = input_direction * speed

func _physics_process(delta: float) -> void:
	get_input()
	move_and_slide()

func add_items(stats):
	hotbar.add_item(stats)
