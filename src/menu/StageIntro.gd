extends Control

@onready var music_player = $AudioStreamPlayer

func _ready():
	if music_player:
		music_player.play()
		
	# Wait for 3.5 seconds then load Stage 1
	get_tree().create_timer(3.5).timeout.connect(load_stage_1)

func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		load_stage_1()

func load_stage_1():
	set_process(false)
	Globals.change_scene("res://src/level/Stage1.tscn")
