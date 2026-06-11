extends Control

# Floating joystick — activates wherever the player touches on the left half of screen
@export var max_drag_radius: float = 45.0
@export var joystick_color: Color = Color(0.18, 0.5, 0.94, 0.5)

var active_touch_index: int = -1
var touch_start: Vector2 = Vector2.ZERO   # Where finger first landed
var drag_position: Vector2 = Vector2.ZERO  # Current finger position
var is_active: bool = false

func _ready():
	pass  # Anchors set in .tscn, no override needed

func _draw():
	if not is_active:
		# Draw faint hint circle so players know where to press
		var vp = get_viewport_rect().size
		var hint_pos = Vector2(vp.x * 0.25, vp.y * 0.78)
		draw_arc(hint_pos, max_drag_radius, 0, TAU, 32, Color(1, 1, 1, 0.08), 1.5, true)
		var inner = max_drag_radius * 0.35
		draw_circle(hint_pos, inner, Color(1, 1, 1, 0.06))
		return

	# Draw base ring at touch origin
	var base_color = joystick_color
	base_color.a = 0.18
	draw_circle(touch_start, max_drag_radius, base_color)
	draw_arc(touch_start, max_drag_radius, 0, TAU, 48, Color(1, 1, 1, 0.3), 2.0, true)

	# Draw inner guide ring
	draw_arc(touch_start, max_drag_radius * 0.5, 0, TAU, 32, Color(1, 1, 1, 0.12), 1.0, true)

	# Draw movable handle
	var handle_color = joystick_color
	handle_color.a = 0.75
	draw_circle(drag_position, max_drag_radius * 0.38, handle_color)
	draw_arc(drag_position, max_drag_radius * 0.38, 0, TAU, 32, Color(1, 1, 1, 0.7), 1.5, true)

func _input(event):
	if event is InputEventScreenTouch:
		var pos = event.position

		if event.pressed:
			# Only claim touches on the left 55% of screen
			var screen_w = get_viewport_rect().size.x
			if active_touch_index == -1 and pos.x < screen_w * 0.55:
				active_touch_index = event.index
				touch_start = pos
				drag_position = pos
				is_active = true
				queue_redraw()
				process_direction(Vector2.ZERO)
		else:
			if event.index == active_touch_index:
				_release()

	elif event is InputEventScreenDrag:
		if event.index == active_touch_index:
			drag_position = event.position
			var diff = drag_position - touch_start
			if diff.length() > max_drag_radius:
				diff = diff.normalized() * max_drag_radius
				drag_position = touch_start + diff
			queue_redraw()
			process_direction(diff / max_drag_radius)

func _release():
	active_touch_index = -1
	is_active = false
	drag_position = touch_start
	queue_redraw()
	process_direction(Vector2.ZERO)

func process_direction(dir: Vector2):
	var threshold = 0.28

	# Horizontal
	if dir.x > threshold:
		if not Input.is_action_pressed("ui_right"): Input.action_press("ui_right")
		if Input.is_action_pressed("ui_left"):      Input.action_release("ui_left")
	elif dir.x < -threshold:
		if not Input.is_action_pressed("ui_left"):  Input.action_press("ui_left")
		if Input.is_action_pressed("ui_right"):     Input.action_release("ui_right")
	else:
		if Input.is_action_pressed("ui_right"): Input.action_release("ui_right")
		if Input.is_action_pressed("ui_left"):  Input.action_release("ui_left")

	# Vertical
	if dir.y > threshold:
		if not Input.is_action_pressed("ui_down"): Input.action_press("ui_down")
		if Input.is_action_pressed("ui_up"):       Input.action_release("ui_up")
	elif dir.y < -threshold:
		if not Input.is_action_pressed("ui_up"):   Input.action_press("ui_up")
		if Input.is_action_pressed("ui_down"):     Input.action_release("ui_down")
	else:
		if Input.is_action_pressed("ui_up"):   Input.action_release("ui_up")
		if Input.is_action_pressed("ui_down"): Input.action_release("ui_down")
