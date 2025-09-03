extends Node

var map_progress: int = 1
signal score_changed(new_score: int)

var score: int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func add_score(points: int) -> void:
	score += points
	score_changed.emit(score)


func reset_score() -> void:
	score = 0
	score_changed.emit(score)
