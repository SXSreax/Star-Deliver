extends Node2D

var start_position: Vector2
var max_distance := 500.0 # Adjust as needed
var pos:Vector2
var rota:float
var dir : float 
var speed = 700

func _ready() -> void:
	global_position = pos
	global_rotation = rota
	start_position = global_position # Set after position is set!
	add_to_group("bullets")
	
func _physics_process(delta: float) -> void:
	var velocity = Vector2(speed, 0).rotated(dir)
	global_position += velocity * delta
	if global_position.distance_to(start_position) > max_distance:
		queue_free()
