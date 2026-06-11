extends Control

@export var action_name: String = ""
@export var label_text: String = ""
@export var color: Color = Color(0.2, 0.6, 1.0, 0.5)

var active_touch_index: int = -1
var is_pressed: bool = false

func _ready():
	custom_minimum_size = Vector2(38, 38)

func _draw():
	var center = size / 2.0
	var radius = min(size.x, size.y) / 2.0 - 2.0

	# Outer glow when pressed
	if is_pressed:
		var glow = color
		glow.a = 0.2
		draw_circle(center, radius + 6.0, glow)

	# Fill
	var fill_color = color
	fill_color.a = 0.75 if is_pressed else 0.38
	draw_circle(center, radius, fill_color)

	# Border
	var border_alpha = 0.9 if is_pressed else 0.45
	draw_arc(center, radius, 0, TAU, 48, Color(1, 1, 1, border_alpha), 2.0, true)

	# Inner ring for depth
	draw_arc(center, radius * 0.6, 0, TAU, 32, Color(1, 1, 1, 0.12 if not is_pressed else 0.25), 1.0, true)

	# Label
	var font = ThemeDB.fallback_font
	var font_size = 11
	var text_size = font.get_string_size(label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos = center - Vector2(text_size.x / 2.0, -font_size / 3.5)
	var text_color = Color.WHITE if is_pressed else Color(1, 1, 1, 0.85)
	draw_string(font, text_pos, label_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_color)

func _input(event):
	if event is InputEventScreenTouch:
		var local_pos = make_input_local(event).position
		var rect = Rect2(Vector2(-8, -8), size + Vector2(16, 16))  # Slightly enlarged hit area

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
