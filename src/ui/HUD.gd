extends Control

@onready var name_label = $CanvasLayer/TopBar/NameLabel
@onready var hp_bar = $CanvasLayer/TopBar/HPBar
@onready var mp_bar = $CanvasLayer/TopBar/MPBar
@onready var lives_label = $CanvasLayer/TopBar/LivesLabel
@onready var score_label = $CanvasLayer/TopBar/ScoreLabel

@onready var boss_panel = $CanvasLayer/BossPanel
@onready var boss_name_label = $CanvasLayer/BossPanel/BossNameLabel
@onready var boss_hp_bar = $CanvasLayer/BossPanel/BossHPBar

func _ready():
	# Connect to Globals signals
	Globals.player_health_changed.connect(_on_player_health_changed)
	Globals.player_mp_changed.connect(_on_player_mp_changed)
	Globals.player_lives_changed.connect(_on_player_lives_changed)
	Globals.player_score_changed.connect(_on_player_score_changed)
	Globals.boss_health_changed.connect(_on_boss_health_changed)
	Globals.boss_state_changed.connect(_on_boss_state_changed)
	
	# Initial update
	name_label.text = Globals.selected_character.to_upper()
	hp_bar.max_value = Globals.player_max_health
	hp_bar.value = Globals.player_health
	mp_bar.max_value = Globals.player_max_mp
	mp_bar.value = Globals.player_mp
	lives_label.text = "LIVES: " + str(Globals.player_lives)
	score_label.text = "SCORE: " + str(Globals.player_score).lpad(6, "0")
	
	boss_panel.visible = Globals.boss_active
	boss_name_label.text = Globals.boss_name
	boss_hp_bar.max_value = Globals.boss_max_health
	boss_hp_bar.value = Globals.boss_health

func _on_player_health_changed(new_health: float):
	hp_bar.value = new_health

func _on_player_mp_changed(new_mp: float):
	mp_bar.value = new_mp

func _on_player_lives_changed(new_lives: int):
	lives_label.text = "LIVES: " + str(new_lives)

func _on_player_score_changed(new_score: int):
	score_label.text = "SCORE: " + str(new_score).lpad(6, "0")

func _on_boss_health_changed(new_health: float):
	boss_hp_bar.value = new_health

func _on_boss_state_changed(active: bool):
	boss_panel.visible = active
	boss_name_label.text = Globals.boss_name
	boss_hp_bar.max_value = Globals.boss_max_health
	boss_hp_bar.value = Globals.boss_health
