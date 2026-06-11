extends Control

var _skipped: bool = false

func _ready():
	# Play stage intro music via the global persistent player
	Globals.play_music("res://assets/music/stage-intro.ogg")
	
	# Wait for 3.5 seconds then load Stage 1
	get_tree().create_timer(3.5).timeout.connect(load_stage_1)

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		load_stage_1()
	elif event is InputEventScreenTouch and event.pressed:
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
