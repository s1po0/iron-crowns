class_name CombatAudio
extends Node

var effects: Dictionary = {}
var players: Array = []
var wind: AudioStreamPlayer
var cursor = 0
var enabled = true

func _ready() -> void:
	for name in ["step","swing","clang","impact"]:
		effects[name] = load("res://assets/audio/"+name+".wav")
	for i in range(8):
		var player = AudioStreamPlayer.new()
		player.volume_db = -12
		add_child(player)
		players.append(player)
	wind = AudioStreamPlayer.new()
	var stream = load("res://assets/audio/wind.wav").duplicate() as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(stream.get_length()*stream.mix_rate)
	wind.stream = stream
	wind.volume_db = -12
	add_child(wind)
	wind.play()

func play_effect(name: String, strength: float = 1.0) -> void:
	if not enabled or not effects.has(name) or players.is_empty():
		return
	var player = players[cursor%players.size()]
	cursor += 1
	player.stream = effects[name]
	player.pitch_scale = .94+float(cursor%7)*.02
	player.volume_db = linear_to_db(maxf(.01,strength)) - 12
	player.play()

func ambience(active: bool) -> void:
	if wind!=null:
		wind.stream_paused = not active or not enabled
	if not enabled:
		for player in players:
			player.stop()
