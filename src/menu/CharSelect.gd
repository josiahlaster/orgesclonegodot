extends Control

@onready var sprite_preview = $CanvasLayer/PreviewPanel/AnimatedSprite2D
@onready var name_label = $CanvasLayer/PreviewPanel/NameLabel
@onready var list_container = $CanvasLayer/ListPanel/GridContainer
@onready var music_player = $AudioStreamPlayer
@onready var select_sound = $SelectionSound
@onready var confirm_sound = $ConfirmSound

var characters = [
	{"id": "deku", "display_name": "Deku", "path": "res://characters/deku/"},
	{"id": "gon", "display_name": "Gon", "path": "res://characters/gon/"},
	{"id": "luffy", "display_name": "Luffy", "path": "res://characters/luffy/"},
	{"id": "naruto", "display_name": "Naruto", "path": "res://characters/naruto/"},
	{"id": "yusuke", "display_name": "Yusuke", "path": "res://characters/yusuke/"},
	{"id": "goku_normal", "display_name": "Goku", "path": "res://characters/goku_normal/"},
	{"id": "ichigo", "display_name": "Ichigo", "path": "res://characters/ichigo/"},
	{"id": "rock_lee", "display_name": "Lee", "path": "res://characters/rock_lee/"},
	{"id": "sonic", "display_name": "Sonic", "path": "res://characters/sonic/"},
	{"id": "sora", "display_name": "Sora", "path": "res://characters/sora/"}
]

var active_index: int = 0
var list_labels = []

func _ready():
	# Populate labels
	for i in range(characters.size()):
		var label = Label.new()
		label.text = characters[i]["display_name"]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 11)
		
		# Make clickable/tappable
		label.mouse_filter = Control.MOUSE_FILTER_STOP
		label.gui_input.connect(_on_label_gui_input.bind(i))
		
		list_container.add_child(label)
		list_labels.append(label)
		
	update_selection()
	if music_player:
		music_player.play()

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if music_player and not music_player.playing:
			music_player.play()

func _on_label_gui_input(event: InputEvent, index: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if music_player and not music_player.playing:
			music_player.play()
			
		if active_index == index:
			if confirm_sound:
				confirm_sound.play()
			confirm_selection()
		else:
			active_index = index
			update_selection()
			if select_sound:
				select_sound.play()

func _process(_delta):
	var prev_index = active_index
	if Input.is_action_just_pressed("ui_left"):
		active_index = (active_index - 1 + characters.size()) % characters.size()
	elif Input.is_action_just_pressed("ui_right"):
		active_index = (active_index + 1) % characters.size()
	elif Input.is_action_just_pressed("ui_up"):
		active_index = (active_index - 2 + characters.size()) % characters.size()
	elif Input.is_action_just_pressed("ui_down"):
		active_index = (active_index + 2) % characters.size()
		
	if active_index != prev_index:
		update_selection()
		if select_sound:
			select_sound.play()
			
	if Input.is_action_just_pressed("ui_accept"):
		if confirm_sound:
			confirm_sound.play()
		confirm_selection()

func update_selection():
	# Update labels styling
	for i in range(list_labels.size()):
		var label = list_labels[i]
		if i == active_index:
			label.text = "[ " + characters[i]["display_name"] + " ]"
			label.add_theme_color_override("font_color", Color(1, 0.8, 0)) # Gold
		else:
			label.text = characters[i]["display_name"]
			label.add_theme_color_override("font_color", Color(1, 1, 1)) # White
			
	# Update preview sprite
	var selected_char = characters[active_index]
	name_label.text = selected_char["display_name"].to_upper()
	
	var frames_path = selected_char["path"] + "Player_spriteframes.tres"
	if ResourceLoader.exists(frames_path):
		var frames = load(frames_path)
		sprite_preview.sprite_frames = frames
		
		# OpenBOR characters converted might have different casing: "idle" or "idle" animation
		var idle_anim = "idle"
		if frames.has_animation("idle"):
			idle_anim = "idle"
		elif frames.has_animation("IDLE"):
			idle_anim = "IDLE"
			
		sprite_preview.play(idle_anim)
	else:
		name_label.text = selected_char["display_name"].to_upper() + " (NO SPRITES)"

func confirm_selection():
	set_process(false)
	Globals.selected_character = characters[active_index]["id"]
	await get_tree().create_timer(0.4).timeout
	Globals.change_scene("res://src/menu/StageIntro.tscn")
