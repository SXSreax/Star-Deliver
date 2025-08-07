extends Control

# Cache all direct child nodes (assumed to be hotbar item slots)
@onready var slots = get_children()

# Reference to the player sprite (could be used for interaction or context)
@onready var player: AnimatedSprite2D = $"../../player"

# Tracks the currently selected hotbar index
var current_index : int:
	set(value):
		current_index = value  # Update to new index
		reset_focus()  # Clear focus from all other slots
		set_focus()    # Set focus on the newly selected slot

# Called when the node is added to the scene
func _ready() -> void:
	for i in range(slots.size()):
		# Assign slot index and connect click signal
		slots[i].slot_index = i
		slots[i].connect("slot_selected", Callable(self, "_on_slot_clicked"))
	current_index = 0  # Default to the first slot

# Disable input processing for all hotbar slots
func reset_focus():
	for slot in slots:
		slot.set_process_input(false)

# Enable input for the current slot
func set_focus():
	get_child(current_index).grab_focus()  # Visually highlight
	get_child(current_index).set_process_input(true)

# Handle mouse-click selection from slot.gd
func _on_slot_clicked(index: int) -> void:
	current_index = index

# Handle user input to control hotbar navigation
func _input(event):

	# Scroll down: move to next slot or wrap to first
	if event.is_action_pressed("scroll_down"):
		if current_index == get_child_count() - 1:
			current_index = 0
		else:
			current_index += 1

	# Scroll up: move to previous slot or wrap to last
	elif event.is_action_pressed("scroll_up"):
		if current_index == 0:
			current_index = get_child_count() - 1
		else:
			current_index -= 1

	# Quick-select slots directly using number keys (1–4)
	elif event.is_action_pressed("1"):
		current_index = 0
	elif event.is_action_pressed("2"):
		current_index = 1
	elif event.is_action_pressed("3"):
		current_index = 2
	elif event.is_action_pressed("4"):
		current_index = 3
