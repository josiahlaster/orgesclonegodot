extends Control

@export var max_drag_radius: float = 30.0
@export var joystick_color: Color = Color(0.2, 0.6, 1.0, 0.4)

var active_touch_index: int = -1
var joystick_center: Vector2 = Vector2.ZERO
var drag_position: Vector2 = Vector2.ZERO

func _ready():
	custom_minimum_size = Vector2(80, 80)
	# Wait for sizing
	await get_tree().process_frame
	joystick_center = size / 2.0
	drag_position = joystick_center

func _draw():
	# Draw base circle
	var base_color = joystick_color
	base_color.a = 0.15
	draw_circle(joystick_center, max_drag_radius, base_color)
	draw_arc(joystick_center, max_drag_radius, 0, TAU, 32, Color(1, 1, 1, 0.25), 1.5, true)
	
	# Draw center handle
	var handle_color = joystick_color
	handle_color.a = 0.65 if active_touch_index != -1 else 0.4
	draw_circle(drag_position, max_drag_radius * 0.4, handle_color)
	draw_arc(drag_position, max_drag_radius * 0.4, 0, TAU, 32, Color(1, 1, 1, 0.5), 1.0, true)

func _input(event):
	if event is InputEventScreenTouch:
		var local_pos = make_input_local(event).position
		var dist = local_pos.distance_to(joystick_center)
		
		if event.pressed:
			if dist <= max_drag_radius * 1.5 and active_touch_index == -1:
				active_touch_index = event.index
				update_joystick(local_pos)
		else:
			if event.index == active_touch_index:
				reset_joystick()
				
	elif event is InputEventScreenDrag:
		if event.index == active_touch_index:
			var local_pos = make_input_local(event).position
			update_joystick(local_pos)

func update_joystick(pos: Vector2):
	var diff = pos - joystick_center
	var dist = diff.length()
	
	if dist > max_drag_radius:
		diff = diff.normalized() * max_drag_radius
		
	drag_position = joystick_center + diff
	queue_redraw()
	
	var dir = diff / max_drag_radius
	process_joystick_direction(dir)

func reset_joystick():
	active_touch_index = -1
	drag_position = joystick_center
	queue_redraw()
	process_joystick_direction(Vector2.ZERO)

func process_joystick_direction(dir: Vector2):
	var threshold = 0.3
	
	# Horizontal direction
	if dir.x > threshold:
		if not Input.is_action_pressed("ui_right"):
			Input.action_press("ui_right")
		if Input.is_action_pressed("ui_left"):
			Input.action_release("ui_left")
	elif dir.x < -threshold:
		if not Input.is_action_pressed("ui_left"):
			Input.action_press("ui_left")
		if Input.is_action_pressed("ui_right"):
			Input.action_release("ui_right")
	else:
		if Input.is_action_pressed("ui_right"):
			Input.action_release("ui_right")
		if Input.is_action_pressed("ui_left"):
			Input.action_release("ui_left")
			
	# Vertical direction
	if dir.y > threshold:
		if not Input.is_action_pressed("ui_down"):
			Input.action_press("ui_down")
		if Input.is_action_pressed("ui_up"):
			Input.action_release("ui_up")
	elif dir.y < -threshold:
		if not Input.is_action_pressed("ui_up"):
			Input.action_press("ui_up")
		if Input.is_action_pressed("ui_down"):
			Input.action_release("ui_down")
	else:
		if Input.is_action_pressed("ui_up"):
			Input.action_release("ui_up")
		if Input.is_action_pressed("ui_down"):
			Input.action_release("ui_down")
