extends Node

var active_music_stream = AudioStreamPlayer

@export_group("Main")
@export var clips: Node


func play(audio_name: String, from_position: float = 0.0) -> void:
	active_music_stream = clips.get_node(audio_name)
	active_music_stream.play(from_position)
	
