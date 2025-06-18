extends Control
@onready var animated_sprite: AnimatedSprite2D = $"../../AnimatedSprite2D"
@onready var slots = get_children()

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
	if event.is_action_pressed("inventory"):
		if current_index == get_child_count() - 1:
			current_index = 0
			
		else:
			current_index += 1
		if current_index == 1:
			animated_sprite.play("sword")
		if current_index == 2:
			animated_sprite.play("package")
		if current_index == 3:
			animated_sprite.play("gun")
		if current_index == 0:
			animated_sprite.play("default")
