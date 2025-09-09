extends Node

var active_music_stream: AudioStreamPlayer = null
var sfx_stream: AudioStreamPlayer = null

@export_group("Main")
@export var clips: Node

func play(audio_name: String, from_position: float = 0.0) -> void:
	if active_music_stream and active_music_stream.playing:
		active_music_stream.stop()
	active_music_stream = clips.get_node(audio_name)
	if active_music_stream.stream is AudioStreamOggVorbis or active_music_stream.stream is AudioStreamMP3:
		active_music_stream.stream.loop = true
	active_music_stream.play(from_position)

func play_sfx(sfx_name: String, from_position: float = 0.0) -> void:
	sfx_stream = clips.get_node(sfx_name)
	# Don't set loop for WAV files
	if sfx_stream.stream is AudioStreamOggVorbis or sfx_stream.stream is AudioStreamMP3:
		sfx_stream.stream.loop = false
	sfx_stream.play(from_position)
