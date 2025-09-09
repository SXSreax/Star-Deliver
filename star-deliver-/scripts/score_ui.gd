extends Control

@onready var label: Label = $HBoxContainer/Label

func _ready() -> void:
	# Update immediately with current score
	label.text = str(Global.score)
	
	# Connect to global signal for live updates
	Global.score_changed.connect(_on_score_changed)

func _on_score_changed(new_score: int) -> void:
	label.text = str(new_score)
