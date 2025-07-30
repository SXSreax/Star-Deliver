extends Control

# Cache all direct child nodes (assumed to be hotbar item slots)
@onready var slots = get_children()

# Reference to the player sprite (could be used for interaction or context)
@onready var player: AnimatedSprite2D = $"../../player"

# Tracks the currently selected hotbar index
var current_index : int:
	set(value):
		current_index = value # Update to new index
		reset_focus() # Clear focus from all other slots
		set_focus() # Set focus on the newly selected slot


# Called when the node is added to the scene
func _ready() -> void:
	current_index = 0  # Default to the first slot


# Disable input processing for all hotbar slots (removes active behavior)
func reset_focus():
	for slot in slots:
		slot.set_process_input(false)


# Enable input for the current slot and give it keyboard/gamepad focus
func set_focus():
	get_child(current_index).grab_focus() # Visually highlight 
	get_child(current_index).set_process_input(true) # Reactivate input handling


# Handle user input to control hotbar navigation
func _input(event):

	# Scroll down: move to next slot or wrap to the first if at the end
	if event.is_action_pressed("scroll_down"):
		if current_index == get_child_count() - 1:
			current_index = 0  # Wrap around to first slot
		else:
			current_index += 1  # Go to next slot

	# Scroll up: move to previous slot or wrap to the last if at the beginning
	if event.is_action_pressed("scroll_up"):
		if current_index == 0:
			current_index = get_child_count() - 1  # Wrap to last slot
		else:
			current_index -= 1  # Go to previous slot

	# Quick-select slots directly using number keys (1 to 4)
	if event.is_action_pressed("1"):
		current_index = 0
	if event.is_action_pressed("2"):
		current_index = 1
	if event.is_action_pressed("3"):
		current_index = 2
	if event.is_action_pressed("4"):
		current_index = 3
