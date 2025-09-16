extends Button

# Index of this slot in the hotbar/inventory
@export var slot_index: int = 0

# Emitted when the slot is clicked
signal slot_selected(index: int)

# Reference to the player in the current scene
@onready var player: Node = get_tree().current_scene.find_child("Player")

# Item assigned to this slot
@export var stats: Item = null:
	set(value):
		stats = value
		# Show the item’s icon if available, else clear the icon
		icon = value.icon if value != null else null


func _ready() -> void:
	# Slots don’t need per-frame input, only pressed events
	set_process_input(false)


func _pressed() -> void:
	# When clicked, notify with this slot’s index
	emit_signal("slot_selected", slot_index)
