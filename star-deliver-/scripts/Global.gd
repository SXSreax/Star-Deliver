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

func _set_custom_cursor(path: String, scale: float = 1.0) -> void:
	var tex: Texture2D = load(path)
	if tex:
		# Get image from texture
		var img: Image = tex.get_image()
		
		# Calculate new size
		var new_size = Vector2i(
			int(img.get_width() * scale),
			int(img.get_height() * scale)
		)
		
		# Resize IN PLACE (void return in Godot 4)
		img.resize(new_size.x, new_size.y, Image.INTERPOLATE_NEAREST)
		
		# Create texture from resized image
		var resized_tex: ImageTexture = ImageTexture.create_from_image(img)

		# Apply as custom cursor
		Input.set_custom_mouse_cursor(
			resized_tex,
			Input.CURSOR_ARROW,
			Vector2(resized_tex.get_width() / 2, resized_tex.get_height() / 2) # hotspot in center
		)
