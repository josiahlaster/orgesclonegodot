extends Node2D

@onready var gameplay_area = $GameplayArea
@onready var camera = $Camera2D
@onready var music_player = $MusicPlayer
@onready var hud = $HUD
@onready var go_sign = $GoSign

# Spawning coordinates from stage1.txt
var spawn_triggers = [
	{
		"trigger_x": 310.0,
		"spawned": false,
		"enemies": [
			{"type": "ninja", "coords": Vector2(480, 215)},
			{"type": "ninja", "coords": Vector2(480, 230)},
			{"type": "ninja", "coords": Vector2(-30, 220)},
			{"type": "ninja", "coords": Vector2(-30, 230)}
		],
		"item": {"type": "statsItem", "coords": Vector2(600, 220)}
	},
	{
		"trigger_x": 1425.0,
		"spawned": false,
		"enemies": [
			{"type": "marine", "coords": Vector2(480, 215)},
			{"type": "marine", "coords": Vector2(480, 230)},
			{"type": "marine", "coords": Vector2(-30, 220)},
			{"type": "marine", "coords": Vector2(-30, 230)}
		],
		"item": null
	},
	{
		"trigger_x": 2058.0,
		"spawned": false,
		"enemies": [
			{"type": "lobster", "coords": Vector2(480, 215)},
			{"type": "lobster", "coords": Vector2(480, 230)},
			{"type": "lobster", "coords": Vector2(-30, 220)},
			{"type": "lobster", "coords": Vector2(-30, 230)}
		],
		"item": {"type": "hp_hundred", "coords": Vector2(2270, 220)}
	},
	{
		"trigger_x": 2800.0,
		"spawned": false,
		"enemies": [
			{"type": "sasuke_e", "coords": Vector2(530, 200), "boss": true},
			{"type": "SakuraNPC", "coords": Vector2(530, 97), "npc": true},
			{"type": "InoNPC", "coords": Vector2(569, 97), "npc": true}
		],
		"item": null
	}
]

var player_instance = null
var current_scroll_lock_x: float = 0.0
var is_scroll_locked: bool = false
var reinforcement_triggered: bool = false
var dialog_box = null
var _audio_unlocked: bool = false
var _stage_music_path: String = "res://assets/music/stage1.ogg"

func _ready():
	# Reset score/health
	Globals.reset_game()
	
	# Spawn selected player character
	spawn_player()
	
	# Play Stage 1 music
	if music_player:
		music_player.stream = load(_stage_music_path)
		music_player.play()
		_audio_unlocked = true
		
	# Setup initial camera limits
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_bottom = 278
	camera.limit_right = 3424

func _input(event):
	# Fallback audio unlock for mobile (in case OS blocks autoplay on scene load)
	if not _audio_unlocked and event is InputEventKey or (event is InputEventMouseButton and event.pressed):
		_audio_unlocked = true
		if music_player and not music_player.playing:
			music_player.play()

func spawn_player():
	var char_name = Globals.selected_character
	var scene_path = "res://characters/%s/Player.tscn" % char_name
	
	if ResourceLoader.exists(scene_path):
		var scene = load(scene_path)
		player_instance = scene.instantiate()
		
		# Add to group so HUD and enemies can find it
		player_instance.add_to_group("player")
		
		gameplay_area.add_child(player_instance)
		
		# Set start coordinates
		player_instance.global_position = Vector2(100.0, 210.0)
		player_instance.z_height = 0.0
	else:
		print("Error: Player scene not found: ", scene_path)

func _physics_process(_delta):
	if not player_instance or not is_instance_valid(player_instance):
		return
		
	# Update Camera position to follow player horizontally
	var cam_target_x = player_instance.global_position.x
	
	if is_scroll_locked:
		# Lock camera at current scroll lock position
		cam_target_x = clamp(cam_target_x, current_scroll_lock_x, current_scroll_lock_x)
		camera.limit_right = int(current_scroll_lock_x + 240.0) # Lock screen bounds
		camera.limit_left = int(current_scroll_lock_x - 240.0)
		
		# Restrict player within screen bounds
		player_instance.global_position.x = clamp(player_instance.global_position.x, camera.limit_left + 15.0, camera.limit_right - 15.0)
		player_instance.global_position.y = clamp(player_instance.global_position.y, 55.0, 235.0)
		
		# Restrict enemies within screen bounds to prevent off-screen sticking
		var active_enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in active_enemies:
			if is_instance_valid(enemy) and not enemy.is_dead:
				enemy.global_position.x = clamp(enemy.global_position.x, camera.limit_left + 15.0, camera.limit_right - 15.0)
				enemy.global_position.y = clamp(enemy.global_position.y, 55.0, 235.0)
		
		# Check if lock is cleared (no active enemies left)
		if active_enemies.size() == 0:
			clear_scroll_lock()
	else:
		# Normal scrolling, camera follows player
		cam_target_x = clamp(cam_target_x, 240.0, 3424.0 - 240.0)
		camera.limit_left = int(cam_target_x - 240.0)
		camera.limit_right = int(cam_target_x + 240.0)
		
		# Restrict player to camera bounds
		player_instance.global_position.x = clamp(player_instance.global_position.x, camera.limit_left + 15.0, camera.limit_right - 15.0)
		player_instance.global_position.y = clamp(player_instance.global_position.y, 55.0, 235.0)
		
		# Restrict enemies vertically even when not scroll locked
		var active_enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in active_enemies:
			if is_instance_valid(enemy) and not enemy.is_dead:
				enemy.global_position.y = clamp(enemy.global_position.y, 55.0, 235.0)
		
		# Check spawn triggers
		check_spawn_triggers(player_instance.global_position.x)

	camera.global_position = Vector2(cam_target_x, 139.0)

func check_spawn_triggers(player_x: float):
	for trigger in spawn_triggers:
		if not trigger["spawned"] and player_x >= trigger["trigger_x"]:
			trigger["spawned"] = true
			trigger_scroll_lock(trigger)
			break

func trigger_scroll_lock(trigger):
	is_scroll_locked = true
	current_scroll_lock_x = max(240.0, camera.global_position.x)
	if go_sign:
		go_sign.stop_go()
		
	# Spawn items if any
	if trigger["item"]:
		spawn_item(trigger["item"]["type"], trigger["item"]["coords"])
		
	# Spawn enemies/bosses/NPCs
	var spawned_boss = null
	for item in trigger["enemies"]:
		var spawn_x = current_scroll_lock_x + (item["coords"].x - 240.0)
		# Clamp to keep spawns within screen bounds
		spawn_x = clamp(spawn_x, current_scroll_lock_x - 235.0, current_scroll_lock_x + 235.0)
		var spawn_pos = Vector2(spawn_x, item["coords"].y)
		
		if item.get("npc", false):
			spawn_npc(item["type"], spawn_pos)
		elif item.get("boss", false):
			spawned_boss = spawn_enemy(item["type"], spawn_pos, true)
		else:
			spawn_enemy(item["type"], spawn_pos, false)
			
	if spawned_boss:
		# Sasuke boss dialogue interlude
		trigger_boss_intro(spawned_boss)

func spawn_enemy(type: String, pos: Vector2, is_boss: bool) -> CharacterBody2D:
	var path = "res://characters/Ninja/Player.tscn"
	var display_name = "Ninja"
	var max_hp = 40.0
	var spd_x = 80.0
	var points_val = 100
	var enemy_damage = 8.0
	
	if type == "marine":
		path = "res://characters/Marine/Player.tscn"
		display_name = "Marine"
		max_hp = 60.0
		spd_x = 70.0
		points_val = 150
		enemy_damage = 10.0
	elif type == "lobster":
		path = "res://characters/Lobster/Player.tscn"
		display_name = "Lobster"
		max_hp = 80.0
		spd_x = 60.0
		points_val = 200
		enemy_damage = 12.0
	elif type == "sasuke_e":
		path = "res://characters/Sasuke/Player.tscn"
		display_name = "Sasuke"
		max_hp = 300.0
		spd_x = 100.0
		points_val = 1000
		enemy_damage = 18.0
		
	if ResourceLoader.exists(path):
		var scene = load(path)
		var enemy = scene.instantiate() as CharacterBody2D
		
		enemy.name = display_name
		enemy.max_health = max_hp
		enemy.speed_x = spd_x
		enemy.damage = enemy_damage
		enemy.points = points_val
		
		# Set attacker reference for sound on hits
		var attack_snd = AudioStreamPlayer2D.new()
		attack_snd.name = "AttackSound"
		attack_snd.stream = load("res://assets/sounds/punch.wav")
		enemy.add_child(attack_snd)
		
		var pain_snd = AudioStreamPlayer2D.new()
		pain_snd.name = "PainSound"
		pain_snd.stream = load("res://assets/sounds/die1.wav")
		enemy.add_child(pain_snd)
		
		gameplay_area.add_child(enemy)
		enemy.global_position = pos
		enemy.z_height = 0.0
		
		if is_boss:
			Globals.boss_active = true
			Globals.boss_name = display_name
			Globals.boss_max_health = max_hp
			Globals.boss_health = max_hp
			Globals.boss_health_changed.emit(max_hp)
			Globals.boss_state_changed.emit(true)
			
		return enemy
	return null

func spawn_npc(type: String, pos: Vector2):
	var path = "res://characters/%s/Player.tscn" % type
	if ResourceLoader.exists(path):
		var scene = load(path)
		var npc = scene.instantiate()
		gameplay_area.add_child(npc)
		npc.global_position = pos
		var sprite = npc.get_node_or_null("AnimatedSprite2D")
		if sprite:
			sprite.speed_scale = 0.5
			sprite.play("idle")

func spawn_item(type: String, coords: Vector2):
	# Spawn recovery food (hp_hundred) or item container (statsItem)
	var path = "res://characters/%s/Player.tscn" % type
	if ResourceLoader.exists(path):
		var scene = load(path)
		var item = scene.instantiate() as CharacterBody2D
		
		# Attach simple item script
		item.set_script(load("res://src/level/Item.gd"))
		item.name = type
		
		gameplay_area.add_child(item)
		item.global_position = Vector2(current_scroll_lock_x + (coords.x - 240.0), coords.y)

func trigger_boss_intro(boss_instance):
	# Switch music to boss
	if music_player:
		music_player.stream = load("res://assets/music/stage1-boss.ogg")
		music_player.play()
		
	# Freeze player and boss controls
	if player_instance:
		player_instance.set_physics_process(false)
	boss_instance.set_physics_process(false)
	
	# Create Dialog Box
	create_dialog("Sasuke: So, you've made it this far... But this is where it ends!")
	
	# Wait for dialog close (Enter pressed)
	await get_tree().create_timer(3.0).timeout
	clear_dialog()
	
	# Restore controls
	if player_instance:
		player_instance.set_physics_process(true)
	boss_instance.set_physics_process(true)

func create_dialog(text: String):
	dialog_box = Panel.new()
	dialog_box.size = Vector2(300, 50)
	dialog_box.position = Vector2(90, 15)
	
	var label = Label.new()
	label.text = text
	label.size = Vector2(280, 40)
	label.position = Vector2(10, 5)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 9)
	
	dialog_box.add_child(label)
	$HUD/CanvasLayer.add_child(dialog_box)

func clear_dialog():
	if dialog_box:
		dialog_box.queue_free()
		dialog_box = null

func clear_scroll_lock():
	is_scroll_locked = false
	if go_sign:
		go_sign.trigger_go()
		
	# Restore camera limits to normal
	camera.limit_left = 0
	camera.limit_right = 3424
	
	# If Sasuke boss was defeated, check victory or trigger reinforcements
	if Globals.boss_active and not reinforcement_triggered:
		reinforcement_triggered = true
		trigger_victory()

func trigger_victory():
	Globals.boss_active = false
	Globals.boss_state_changed.emit(false)
	
	# Play Stage Clear music
	if music_player:
		music_player.stream = load("res://assets/music/complete.ogg")
		music_player.play()
		
	if player_instance:
		player_instance.set_physics_process(false)
		
	# Victory UI banner
	var banner = Label.new()
	banner.text = "STAGE 1 CLEAR!"
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner.size = Vector2(200, 50)
	banner.position = Vector2(140, 110)
	banner.add_theme_font_size_override("font_size", 20)
	banner.add_theme_color_override("font_color", Color(1, 0.8, 0))
	$HUD/CanvasLayer.add_child(banner)
	
	# Go to main menu after 5 seconds
	await get_tree().create_timer(5.0).timeout
	Globals.change_scene("res://src/menu/TitleScreen.tscn")
