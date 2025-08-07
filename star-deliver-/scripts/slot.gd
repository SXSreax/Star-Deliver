extends Button

@export var slot_index: int = 0
signal slot_selected(index: int)

@onready var player = get_tree().current_scene.find_child("Player")

@export var stats : Item = null:
	set(value):
		stats = value
		icon = value.icon if value != null else null

func _ready() -> void:
	set_process_input(false)

func _pressed() -> void:
	emit_signal("slot_selected", slot_index)
