extends Node

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
