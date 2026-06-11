extends Control

@export var action_name: String = ""
@export var label_text: String = ""
@export var color: Color = Color(0.2, 0.6, 1.0, 0.4)

var active_touch_index: int = -1
var is_pressed: bool = false

func _ready():
	custom_minimum_size = Vector2(32, 32)

func _draw():
	var center = size / 2.0
	var radius = min(size.x, size.y) / 2.0 - 1.5
	
	# Draw fill
	var fill_color = color
	if is_pressed:
		fill_color.a = 0.85
	else:
		fill_color.a = 0.4
	draw_circle(center, radius, fill_color)
	
	# Draw neon border
	var border_color = Color.WHITE
	border_color.a = 0.5 if not is_pressed else 0.95
	draw_arc(center, radius, 0, TAU, 32, border_color, 1.5, true)
	
	# Draw text
	var font = ThemeDB.fallback_font
	var font_size = 11
	var text_size = font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	# Center text horizontally and vertically
	var text_pos = center - Vector2(text_size.x / 2.0, -font_size / 3.0)
	draw_string(font, text_pos, label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.WHITE)

func _input(event):
	if event is InputEventScreenTouch:
		var local_pos = make_input_local(event).position
		var rect = Rect2(Vector2.ZERO, size)
		
		if event.pressed:
			if rect.has_point(local_pos) and active_touch_index == -1:
				active_touch_index = event.index
				is_pressed = true
				Input.action_press(action_name)
				queue_redraw()
		else:
			if event.index == active_touch_index:
				active_touch_index = -1
				is_pressed = false
				Input.action_release(action_name)
				queue_redraw()
