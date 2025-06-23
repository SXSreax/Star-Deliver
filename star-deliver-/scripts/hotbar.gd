extends Control
@onready var slots = get_children()
@onready var player: AnimatedSprite2D = $"../../player"

var current_index : int:
	set(value):
		current_index = value
		reset_focus()
		set_focus()
		
func _ready() -> void:
	current_index = 0


		
func reset_focus():
	for slot in slots:
		slot.set_process_input(false)

func set_focus():
	get_child(current_index).grab_focus()
	get_child(current_index).set_process_input(true)
	
func _input(event):
	if event.is_action_pressed("scroll_down"):
		if current_index == get_child_count() - 1:
			current_index = 0		
		else:
			current_index += 1
	if event.is_action_pressed("1"):
		current_index = 0
	if event.is_action_pressed("2"):
		current_index = 1
	if event.is_action_pressed("3"):
		current_index = 2
	if event.is_action_pressed("4"):
		current_index = 3
	
