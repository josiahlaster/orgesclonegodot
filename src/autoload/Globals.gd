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

# ─── Music Preloads ───────────────────────────────────────────────────────────
# Preloaded so the Godot exporter GUARANTEES these files are bundled in the PCK.
# Using preload() forces the export scanner to include the files.
const MUSIC_MENU        = preload("res://assets/music/menu.ogg")
const MUSIC_SELECT      = preload("res://assets/music/select.ogg")
const MUSIC_STAGE_INTRO = preload("res://assets/music/stage-intro.ogg")
const MUSIC_STAGE1      = preload("res://assets/music/stage1.ogg")
const MUSIC_STAGE1_BOSS = preload("res://assets/music/stage1-boss.ogg")
const MUSIC_COMPLETE    = preload("res://assets/music/complete.ogg")
const MUSIC_GAMEOVER    = preload("res://assets/music/gameover.ogg")

# Map path → preloaded resource so play_music() never calls load() at runtime
var _music_library: Dictionary = {}

# ─── Global Music Player ──────────────────────────────────────────────────────
var _music_player: AudioStreamPlayer = null
var _current_music_path: String = ""
var _audio_unlocked: bool = false
var _pending_path: String = ""

func _ready():
	# Build lookup table of path → preloaded stream
	_music_library = {
		"res://assets/music/menu.ogg":        MUSIC_MENU,
		"res://assets/music/select.ogg":      MUSIC_SELECT,
		"res://assets/music/stage-intro.ogg": MUSIC_STAGE_INTRO,
		"res://assets/music/stage1.ogg":      MUSIC_STAGE1,
		"res://assets/music/stage1-boss.ogg": MUSIC_STAGE1_BOSS,
		"res://assets/music/complete.ogg":    MUSIC_COMPLETE,
		"res://assets/music/gameover.ogg":    MUSIC_GAMEOVER,
	}

	# Enable looping on every stream in code — this is the reliable way.
	# Setting loop=true in .import files only works if the editor reimports,
	# which may not happen on CI since .godot/ is gitignored.
	for stream in _music_library.values():
		if stream is AudioStreamOggVorbis:
			stream.loop = true

	_music_player = AudioStreamPlayer.new()
	_music_player.volume_db = -5.0
	_music_player.bus = "Master"
	add_child(_music_player)

func _input(event):
	# iOS and Android block audio until after the first user gesture.
	# Globals receives _input before any scene node, so this fires first.
	if not _audio_unlocked:
		var is_touch = (event is InputEventScreenTouch and event.pressed)
		var is_click = (event is InputEventMouseButton and event.pressed)
		if is_touch or is_click:
			_audio_unlocked = true
			if _music_player and not _music_player.playing and _current_music_path != "":
				_do_play(_current_music_path)

func play_music(path: String, force_restart: bool = false):
	if not _music_player:
		return
	# Already playing this track and not forced — do nothing
	if _current_music_path == path and _music_player.playing and not force_restart:
		return
	_current_music_path = path
	_do_play(path)

func _do_play(path: String):
	var stream = _music_library.get(path)
	if stream == null:
		push_error("Globals.play_music: No preloaded stream for path: " + path)
		return
	# Stop any currently playing track first
	if _music_player.playing:
		_music_player.stop()
	_music_player.stream = stream
	# call_deferred so the audio driver frame is fully ready before play()
	_music_player.call_deferred("play")
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
