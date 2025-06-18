extends Button

@onready var plauer = get_tree().current_scene.find_child("Player")

@export var stats : Item = null:
	set(value):
		stats = value
		
		if value != null:
			icon = value.icon
		else:
			icon = null
			
func _ready() -> void:
	set_process_input(false)
