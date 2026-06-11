extends Control

@onready var music_player = $AudioStreamPlayer

var _audio_unlocked: bool = false
var _skipped: bool = false

func _ready():
	# Try to play immediately (works on desktop; mobile may need user gesture)
	if music_player:
		music_player.play()
		_audio_unlocked = true
		
	# Wait for 3.5 seconds then load Stage 1
	get_tree().create_timer(3.5).timeout.connect(load_stage_1)

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		# Unlock audio on first touch (mobile audio policy)
		if not _audio_unlocked:
			_audio_unlocked = true
			if music_player and not music_player.playing:
				music_player.play()
		# Tap anywhere to skip
		load_stage_1()

func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		load_stage_1()

func load_stage_1():
	if _skipped:
		return
	_skipped = true
	set_process(false)
	Globals.change_scene("res://src/level/Stage1.tscn")
