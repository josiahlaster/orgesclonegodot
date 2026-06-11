extends Node

# ─── Character / Game State ───────────────────────────────────────────────────
var selected_character: String = "Deku"

var player_lives: int = 3:
	set(val):
		player_lives = val
		player_lives_changed.emit(player_lives)

var player_score: int = 0:
	set(val):
		player_score = val
		player_score_changed.emit(player_score)

var player_health: float = 100.0:
	set(val):
		player_health = clamp(val, 0.0, player_max_health)
		player_health_changed.emit(player_health)

var player_max_health: float = 100.0

var player_mp: float = 0.0:
	set(val):
		player_mp = clamp(val, 0.0, player_max_mp)
		player_mp_changed.emit(player_mp)

var player_max_mp: float = 100.0

var boss_active: bool = false:
	set(val):
		boss_active = val
		boss_state_changed.emit(boss_active)

var boss_health: float = 100.0:
	set(val):
		boss_health = clamp(val, 0.0, boss_max_health)
		boss_health_changed.emit(boss_health)

var boss_max_health: float = 100.0
var boss_name: String = "Sasuke"

signal player_health_changed(new_health)
signal player_mp_changed(new_mp)
signal player_lives_changed(new_lives)
signal player_score_changed(new_score)
signal boss_health_changed(new_health)
signal boss_state_changed(active)

# ─── Global Music Player ──────────────────────────────────────────────────────
# One persistent AudioStreamPlayer lives here, survives all scene changes.
# All scenes call Globals.play_music("res://...") instead of managing their own.
var _music_player: AudioStreamPlayer = null
var _current_music_path: String = ""
var _audio_unlocked: bool = false

func _ready():
	_music_player = AudioStreamPlayer.new()
	_music_player.volume_db = -5.0
	_music_player.bus = "Master"
	add_child(_music_player)
	# Re-loop when track finishes
	_music_player.finished.connect(_on_music_finished)

func _on_music_finished():
	# Loop the current track
	if _current_music_path != "" and _audio_unlocked:
		_music_player.play()

func _input(event):
	# On mobile, audio cannot play until after a user gesture.
	# This catches the very first touch/click anywhere in the app.
	if not _audio_unlocked:
		if event is InputEventMouseButton and event.pressed:
			_audio_unlocked = true
			if _music_player and not _music_player.playing and _current_music_path != "":
				_music_player.play()
		elif event is InputEventScreenTouch and event.pressed:
			_audio_unlocked = true
			if _music_player and not _music_player.playing and _current_music_path != "":
				_music_player.play()

func play_music(path: String, force_restart: bool = false):
	if not _music_player:
		return
	# Don't restart the same track unless forced
	if _current_music_path == path and _music_player.playing and not force_restart:
		return
	_current_music_path = path
	var stream = load(path)
	if stream == null:
		push_error("Globals.play_music: Could not load audio file: " + path)
		return
	_music_player.stream = stream
	# On desktop the audio context is already unlocked; on mobile we try and
	# the _input callback will retry on first touch if it silently fails.
	_music_player.play()
	if _music_player.playing:
		_audio_unlocked = true

func stop_music():
	_current_music_path = ""
	if _music_player:
		_music_player.stop()

# ─── Game Functions ───────────────────────────────────────────────────────────
func reset_game():
	player_lives = 3
	player_score = 0
	player_health = 100.0
	player_max_health = 100.0
	player_mp = 0.0
	player_max_mp = 100.0
	boss_active = false

func add_score(amount: int):
	player_score += amount

func set_player_health(amount: float):
	player_health = amount

func set_player_mp(amount: float):
	player_mp = amount

func change_scene(scene_path: String):
	get_tree().change_scene_to_file(scene_path)
