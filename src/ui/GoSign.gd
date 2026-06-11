extends Control

@onready var label = $CanvasLayer/Panel/Label
@onready var sound = $AudioStreamPlayer
@onready var timer = $Timer

var flashing: bool = false

func _ready():
	visible = false

func trigger_go():
	if flashing: return
	flashing = true
	visible = true
	if sound:
		sound.play()
	timer.start()

func stop_go():
	flashing = false
	visible = false
	timer.stop()

func _on_timer_timeout():
	if flashing:
		label.visible = not label.visible
