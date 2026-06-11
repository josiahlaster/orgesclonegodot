class_name BasePlayer
extends CharacterBody2D

# Constants matching character specs
@export var base_speed_x: float = 140.0
@export var base_speed_y: float = 80.0
@export var jump_force: float = 220.0
@export var gravity: float = 600.0
@export var anim_speed_scale: float = 0.5

@onready var sprite = $AnimatedSprite2D
@onready var hurtbox = $Hurtbox
@onready var hitbox = $AttackHitbox
@onready var collision_shape = $CollisionShape2D

# Simulated 2.5D Jump variables
var z_height: float = 0.0
var z_velocity: float = 0.0

# Gameplay states
var is_attacking: bool = false
var is_hit: bool = false
var is_dead: bool = false
var hit_timer: float = 0.0

# Combo variables
var combo_step: int = 0
var combo_timer: float = 0.0

# Attack configuration mapping
var attack_anims = {
	"attack1": "attack1",
	"attack2": "attack2",
	"attack3": "attack3",
	"runattack": "runattack",
	"jumpattack": "jumpattack",
	"chargeattack": "chargeattack",
	"special": "freespecial",
	"special2": "freespecial2",
	"special3": "freespecial3"
}

func _ready():
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 2
	collision_mask = 1
	
	if sprite:
		sprite.speed_scale = anim_speed_scale
	
	# Resize physics collision shape
	var main_col = get_node_or_null("CollisionShape2D")
	if main_col and main_col.shape:
		main_col.shape = main_col.shape.duplicate()
		if main_col.shape is CapsuleShape2D:
			main_col.shape.radius = 8.0
			main_col.shape.height = 20.0
		elif main_col.shape is RectangleShape2D:
			main_col.shape.size = Vector2(16.0, 16.0)
		main_col.position = Vector2(0, -10)
	
	# Configure Hurtbox at runtime
	if hurtbox:
		hurtbox.set_script(load("res://src/common/Hurtbox.gd"))
		hurtbox._ready()
		hurtbox.hit_received.connect(_on_hit_received)
		var hurtbox_col = hurtbox.get_node_or_null("CollisionShape2D")
		if hurtbox_col and hurtbox_col.shape:
			hurtbox_col.shape = hurtbox_col.shape.duplicate()
			if hurtbox_col.shape is RectangleShape2D:
				# Head-to-torso only: narrower and shorter than full body
				hurtbox_col.shape.size = Vector2(22.0, 32.0)
			elif hurtbox_col.shape is CapsuleShape2D:
				hurtbox_col.shape.radius = 10.0
				hurtbox_col.shape.height = 32.0
			# Position centered on torso/chest, offset upward from feet
			hurtbox_col.position = Vector2(0, -38.0)
		
	# Configure Hitbox at runtime
	if hitbox:
		hitbox.set_script(load("res://src/common/Hitbox.gd"))
		hitbox._ready()
		hitbox.attacker = self
		# Disable hitbox collision shape initially
		var hitbox_col = hitbox.get_node_or_null("CollisionShape2D")
		if hitbox_col:
			hitbox_col.disabled = true
			if hitbox_col.shape:
				hitbox_col.shape = hitbox_col.shape.duplicate()
				if hitbox_col.shape is RectangleShape2D:
					hitbox_col.shape.size = Vector2(35.0, 15.0)
				elif hitbox_col.shape is CapsuleShape2D:
					hitbox_col.shape.radius = 7.5
					hitbox_col.shape.height = 35.0
				hitbox_col.position = Vector2(15.0, -30.0)
			
	# Connect animation finished signal
	if sprite:
		sprite.animation_finished.connect(_on_animation_finished)
		
	# Setup dynamic sound players
	var attack_snd = AudioStreamPlayer.new()
	attack_snd.name = "AttackSound"
	attack_snd.stream = load("res://assets/sounds/punch.wav")
	attack_snd.volume_db = -5.0
	add_child(attack_snd)
	
	var pain_snd = AudioStreamPlayer.new()
	pain_snd.name = "PainSound"
	pain_snd.stream = load("res://assets/sounds/die1.wav")
	pain_snd.volume_db = -3.0
	add_child(pain_snd)
		
	# Initialize Globals stats
	Globals.player_health = Globals.player_max_health
	Globals.player_mp = 0.0
	Globals.player_health_changed.emit(Globals.player_health)
	Globals.player_mp_changed.emit(Globals.player_mp)

func _physics_process(delta):
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide_clamped()
		return
		
	# Handle recovery timer when hit
	if is_hit:
		hit_timer -= delta
		if hit_timer <= 0:
			is_hit = false
		velocity.x = move_toward(velocity.x, 0, 8.0)
		velocity.y = move_toward(velocity.y, 0, 8.0)
		move_and_slide_clamped()
		return
		
	# Apply 2.5D gravity to Z-height
	if z_height > 0.0 or z_velocity != 0.0:
		z_height += z_velocity * delta
		z_velocity -= gravity * delta
		if z_height <= 0.0:
			z_height = 0.0
			z_velocity = 0.0
			# Land sound/effect can be played here
			if is_attacking and sprite.animation == "jumpattack":
				is_attacking = false
				
	# Update visual position of sprite, clamped so it doesn't go off-screen vertically
	var target_sprite_y = -z_height
	var min_sprite_y = 15.0 - global_position.y # Keep head on-screen
	sprite.position.y = max(target_sprite_y, min_sprite_y)
	
	# Combo reset timer
	if combo_step > 0:
		combo_timer -= delta
		if combo_timer <= 0:
			combo_step = 0
			
	# Process player controls and movement
	handle_attacks()
	handle_movement(delta)

func handle_movement(_delta):
	if is_attacking:
		# Slow down/stop during ground attacks
		if z_height == 0.0 and sprite.animation not in ["runattack", "chargeattack"]:
			velocity = Vector2.ZERO
		move_and_slide_clamped()
		return
		
	# 8-way movement input
	var input_dir = Vector2.ZERO
	input_dir.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_dir.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_dir = input_dir.normalized()
	
	# Apply movement velocity
	velocity.x = input_dir.x * base_speed_x
	velocity.y = input_dir.y * base_speed_y
	
	# Flip sprite according to direction
	if input_dir.x < 0:
		sprite.flip_h = true
		hitbox.scale.x = -1
	elif input_dir.x > 0:
		sprite.flip_h = false
		hitbox.scale.x = 1
		
	# Handle Jump (Accept key: Space/Enter)
	if Input.is_action_just_pressed("ui_accept") and z_height == 0.0:
		z_velocity = jump_force
		
	# Play animations based on state
	if z_height > 0.0:
		play_anim("jump")
	elif velocity != Vector2.ZERO:
		if Input.is_action_pressed("ui_dash") or Globals.player_mp > 80.0: # Run state
			play_anim("run")
		else:
			play_anim("walk")
	else:
		play_anim("idle")
		
	move_and_slide_clamped()

func handle_attacks():
	if is_attacking:
		# Check for combo hits during standard attack animations
		if Input.is_action_just_pressed("ui_attack"):
			if sprite.animation == "attack1" and sprite.frame >= 1:
				trigger_attack("attack2")
			elif sprite.animation == "attack2" and sprite.frame >= 1:
				trigger_attack("attack3")
		return
		
	# Trigger attacks based on action inputs
	if Input.is_action_just_pressed("ui_attack"):
		if z_height > 0.0:
			trigger_attack("jumpattack")
		elif velocity.x != 0 and Input.is_action_pressed("ui_dash"):
			trigger_attack("runattack")
		else:
			# Start combo sequence
			if combo_step == 0:
				trigger_attack("attack1")
			elif combo_step == 1:
				trigger_attack("attack2")
			elif combo_step == 2:
				trigger_attack("attack3")
	elif Input.is_action_just_pressed("ui_dash"):
		trigger_attack("chargeattack")
	elif Input.is_action_just_pressed("ui_power"):
		# Power attack (consumes 20 MP if available, adds flair)
		if Globals.player_mp >= 20.0:
			Globals.set_player_mp(Globals.player_mp - 20.0)
			trigger_attack("special")
		else:
			trigger_attack("attack1")
	elif Input.is_action_just_pressed("ui_special"):
		# Free special 2
		trigger_attack("special2")
	elif Input.is_action_just_pressed("ui_movelist"):
		# Free special 3
		trigger_attack("special3")

func trigger_attack(anim_name: String):
	var mapped_anim = attack_anims.get(anim_name, anim_name)
	if sprite.sprite_frames.has_animation(mapped_anim):
		is_attacking = true
		play_anim(mapped_anim)
		
		# Set combo variables if combo attack
		if anim_name == "attack1":
			combo_step = 1
			combo_timer = 1.0
		elif anim_name == "attack2":
			combo_step = 2
			combo_timer = 1.0
		elif anim_name == "attack3":
			combo_step = 0
			
		# Enable attack hitbox collision shape
		var hitbox_col = hitbox.get_node_or_null("CollisionShape2D")
		if hitbox_col:
			hitbox_col.disabled = false
			# Play punch/attack sound effect
			var sound_player = get_node_or_null("AttackSound")
			if sound_player:
				sound_player.play()

func play_anim(anim_name: String):
	if sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
	elif anim_name == "walk" and sprite.sprite_frames.has_animation("walk"):
		sprite.play("walk")
	elif anim_name == "run" and sprite.sprite_frames.has_animation("run"):
		sprite.play("run")
	elif anim_name == "pain" and sprite.sprite_frames.has_animation("pain"):
		sprite.play("pain")
	else:
		# Fallback to idle if animation doesn't exist
		if sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")

func _on_animation_finished():
	if is_attacking:
		is_attacking = false
		# Disable attack hitbox collision shape
		var hitbox_col = hitbox.get_node_or_null("CollisionShape2D")
		if hitbox_col:
			hitbox_col.disabled = true
			
	if is_dead:
		# Handle death respawn or game over
		visible = false
		Globals.player_lives -= 1
		Globals.player_lives_changed.emit(Globals.player_lives)
		
		if Globals.player_lives > 0:
			# Respawn player after 2 seconds
			await get_tree().create_timer(2.0).timeout
			respawn()
		else:
			# Game over
			await get_tree().create_timer(1.5).timeout
			Globals.change_scene("res://src/menu/TitleScreen.tscn")

func _on_hit_received(damage: float, knockback: float, knockback_dir: Vector2):
	if is_dead: return
	
	is_hit = true
	is_attacking = false
	hit_timer = 0.4 # Lock player control briefly
	
	# Disable attack hitbox just in case
	var hitbox_col = hitbox.get_node_or_null("CollisionShape2D")
	if hitbox_col:
		hitbox_col.disabled = true
		
	# Reduce health
	Globals.set_player_health(Globals.player_health - damage)
	
	# Add MP on taking hits
	Globals.set_player_mp(Globals.player_mp + 5.0)
	
	# Play pain sound
	var pain_sound = get_node_or_null("PainSound")
	if pain_sound:
		pain_sound.play()
		
	# Check for death
	if Globals.player_health <= 0.0:
		die(knockback_dir, knockback)
	else:
		# Apply knockback force
		velocity = knockback_dir * knockback
		play_anim("pain")

func die(knockback_dir: Vector2, knockback: float):
	is_dead = true
	velocity = knockback_dir * (knockback * 1.5)
	
	# Play fall/dead animation
	if sprite.sprite_frames.has_animation("fall"):
		play_anim("fall")
	elif sprite.sprite_frames.has_animation("die"):
		play_anim("die")
	elif sprite.sprite_frames.has_animation("dead"):
		play_anim("dead")
	else:
		_on_animation_finished()

func respawn():
	is_dead = false
	is_hit = false
	is_attacking = false
	visible = true
	z_height = 100.0 # Drop down from sky
	z_velocity = 0.0
	
	# Reset position to stage left edge (relative to camera)
	var camera = get_viewport().get_camera_2d()
	if camera:
		global_position = Vector2(camera.global_position.x - 200.0, 200.0)
	else:
		global_position = Vector2(100.0, 200.0)
		
	Globals.set_player_health(Globals.player_max_health)
	Globals.set_player_mp(0.0)
	play_anim("idle")


func move_and_slide_clamped():
	move_and_slide()
	global_position.y = clamp(global_position.y, 55.0, 235.0)
