extends Control

@onready var menu_options = $CanvasLayer/VBoxContainer
@onready var selection_sound = $SelectionSound
@onready var confirm_sound = $ConfirmSound

var selected_index: int = 0
var options = ["START GAME", "TRAINING", "EXIT"]

func _ready():
	# Reset game stats on returning to main menu
	Globals.reset_game()
	
	update_menu_display()
	
	# Enable mouse filter for options to detect clicks/taps
	for i in range(menu_options.get_child_count()):
		var label = menu_options.get_child(i) as Label
		if label:
			label.mouse_filter = Control.MOUSE_FILTER_STOP
			label.gui_input.connect(_on_label_gui_input.bind(i))
	
	# Play menu music via global player (persists across scenes, retries on touch)
	Globals.play_music("res://assets/music/menu.ogg")

func _on_label_gui_input(event: InputEvent, index: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if selected_index == index:
			play_confirm_sound()
			execute_option()
		else:
			selected_index = index
			update_menu_display()
			play_selection_sound()

func _process(_delta):
	if Input.is_action_just_pressed("ui_up"):
		selected_index = (selected_index - 1 + options.size()) % options.size()
		update_menu_display()
		play_selection_sound()
	elif Input.is_action_just_pressed("ui_down"):
		selected_index = (selected_index + 1) % options.size()
		update_menu_display()
		play_selection_sound()
	elif Input.is_action_just_pressed("ui_accept"):
		play_confirm_sound()
		execute_option()

func update_menu_display():
	for i in range(menu_options.get_child_count()):
		var label = menu_options.get_child(i) as Label
		if label:
			if i == selected_index:
				label.text = "> " + options[i] + " <"
				label.add_theme_color_override("font_color", Color(1, 0.8, 0)) # Gold color
			else:
				label.text = "  " + options[i] + "  "
				label.add_theme_color_override("font_color", Color(1, 1, 1)) # White color

func play_selection_sound():
	if selection_sound:
		selection_sound.play()

func play_confirm_sound():
	if confirm_sound:
		confirm_sound.play()

func execute_option():
	# Disable processing during transition
	set_process(false)
	
	# Wait for confirm sound to finish before transitioning
	await get_tree().create_timer(0.4).timeout
	
	match selected_index:
		0: # START GAME
			Globals.change_scene("res://src/menu/CharSelect.tscn")
		1: # TRAINING
			Globals.change_scene("res://src/menu/CharSelect.tscn") # For demo, we'll select character then load
		2: # EXIT
			get_tree().quit()
