extends Control

func _ready():
	# Show on mobile, touchscreens, or debug builds (touch emulated from mouse)
	var is_mobile = OS.has_feature("mobile") or OS.has_feature("ios") or OS.has_feature("android")
	var is_touchscreen = DisplayServer.is_touchscreen_available()
	var is_debug = OS.is_debug_build()
	visible = is_mobile or is_touchscreen or is_debug
