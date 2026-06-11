extends Control

func _ready():
	# Decide whether to show touch controls
	var is_mobile = OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")
	var is_debug = OS.is_debug_build()
	var is_touchscreen = DisplayServer.is_touchscreen_available()
	
	# Show touch controls on mobile devices, touchscreens, or during debug/testing (since we enabled touch emulation from mouse)
	visible = is_mobile or is_debug or is_touchscreen
