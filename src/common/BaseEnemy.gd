class_name BaseEnemy
extends CharacterBody2D

@export var max_health: float = 40.0
@export var speed_x: float = 80.0
@export var speed_y: float = 45.0
@export var damage: float = 8.0
@export var attack_cooldown: float = 1.5
@export var points: int = 100
@export var anim_speed_scale: float = 0.5

@onready var sprite = $AnimatedSprite2D
@onready var hurtbox = $Hurtbox
@onready var hitbox = $AttackHitbox

var health: float = 40.0
var player: CharacterBody2D = null

# AI States
var is_hit: bool = false
var is_attacking: bool = false
var is_dead: bool = false
var cooldown_timer: float = 0.0
var hit_timer: float = 0.0

# 2.5D simulated heights
var z_height: float = 0.0

func _ready():
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	collision_layer = 4
	collision_mask = 1
	health = max_health
	
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
				hurtbox_col.shape.size = Vector2(24.0, 55.0)
			elif hurtbox_col.shape is CapsuleShape2D:
				hurtbox_col.shape.radius = 12.0
				hurtbox_col.shape.height = 55.0
			hurtbox_col.position = Vector2(0, -30.0)
		
	# Configure Hitbox at runtime
	if hitbox:
		hitbox.set_script(load("res://src/common/Hitbox.gd"))
		hitbox._ready()
		hitbox.attacker = self
		hitbox.damage = damage
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
		
	# Add to group "enemies" for level management
	add_to_group("enemies")
	
	# Find player
	find_player()

func find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _physics_process(delta):
	# Update visual position of sprite, clamped so it doesn't go off-screen vertically
	if sprite:
		var target_sprite_y = -z_height
		var min_sprite_y = 15.0 - global_position.y # Keep head on-screen
		sprite.position.y = max(target_sprite_y, min_sprite_y)

	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide_clamped()
		return
		
	if is_hit:
		hit_timer -= delta
		if hit_timer <= 0:
			is_hit = false
		velocity.x = move_toward(velocity.x, 0, 6.0)
		velocity.y = move_toward(velocity.y, 0, 6.0)
		move_and_slide_clamped()
		return
		
	if is_attacking:
		velocity = Vector2.ZERO
		move_and_slide_clamped()
		return
		
	if cooldown_timer > 0:
		cooldown_timer -= delta
		
	if not player or not is_instance_valid(player) or player.is_dead:
		find_player()
		velocity = Vector2.ZERO
		play_anim("idle")
		move_and_slide_clamped()
		return
		
	# AI Logic: Chase player
	var diff = player.global_position - global_position
	var dist_x = abs(diff.x)
	var dist_y = abs(diff.y)
	
	# Attack range checks (X range: ~45px, Y range: ~10px)
	if dist_x < 50.0 and dist_y < 12.0:
		velocity = Vector2.ZERO
		if cooldown_timer <= 0.0:
			trigger_attack()
		else:
			play_anim("idle")
	else:
		# Walk towards player
		var dir = Vector2.ZERO
		
		# Move vertically (depth alignment)
		if dist_y > 8.0:
			dir.y = sign(diff.y)
		# Move horizontally
		if dist_x > 35.0:
			dir.x = sign(diff.x)
			
		dir = dir.normalized()
		velocity.x = dir.x * speed_x
		velocity.y = dir.y * speed_y
		
		# Flip sprite based on movement direction
		if velocity.x < 0:
			sprite.flip_h = true
			hitbox.scale.x = -1
		elif velocity.x > 0:
			sprite.flip_h = false
			hitbox.scale.x = 1
			
		play_anim("walk")
		
	move_and_slide_clamped()

func trigger_attack():
	# Decide animation to play
	var attack_anim = "attack1"
	if not sprite.sprite_frames.has_animation(attack_anim):
		if sprite.sprite_frames.has_animation("attack"):
			attack_anim = "attack"
		else:
			# Fallback if no attack anim
			cooldown_timer = attack_cooldown
			return
			
	is_attacking = true
	play_anim(attack_anim)
	
	# Enable attack hitbox
	var hitbox_col = hitbox.get_node_or_null("CollisionShape2D")
	if hitbox_col:
		hitbox_col.disabled = false
		
	# Play attack sound if exists
	var sound_player = get_node_or_null("AttackSound")
	if sound_player:
		sound_player.play()

func play_anim(anim_name: String):
	if sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
	elif anim_name == "walk" and sprite.sprite_frames.has_animation("walk"):
		sprite.play("walk")
	elif anim_name == "pain" and sprite.sprite_frames.has_animation("pain"):
		sprite.play("pain")
	else:
		if sprite.sprite_frames.has_animation("idle"):
			sprite.play("idle")

func _on_animation_finished():
	if is_attacking:
		is_attacking = false
		cooldown_timer = attack_cooldown
		var hitbox_col = hitbox.get_node_or_null("CollisionShape2D")
		if hitbox_col:
			hitbox_col.disabled = true
			
	if is_dead:
		queue_free()

func _on_hit_received(damage_amt: float, knockback: float, knockback_dir: Vector2):
	if is_dead: return
	
	is_hit = true
	is_attacking = false
	hit_timer = 0.35
	
	var hitbox_col = hitbox.get_node_or_null("CollisionShape2D")
	if hitbox_col:
		hitbox_col.disabled = true
		
	health -= damage_amt
	
	# Play hit sound if exists
	var pain_sound = get_node_or_null("PainSound")
	if pain_sound:
		pain_sound.play()
		
	# Update Boss HUD if this is boss
	if Globals.boss_active and Globals.boss_name == name:
		Globals.boss_health = health
		Globals.boss_health_changed.emit(health)
		
	if health <= 0:
		die(knockback_dir, knockback)
	else:
		# Apply knockback force
		velocity = knockback_dir * knockback
		play_anim("pain")

func die(knockback_dir: Vector2, knockback: float):
	is_dead = true
	velocity = knockback_dir * (knockback * 1.3)
	Globals.add_score(points)
	
	# Play dead/fall animation
	if sprite.sprite_frames.has_animation("fall"):
		play_anim("fall")
	elif sprite.sprite_frames.has_animation("die"):
		play_anim("die")
	elif sprite.sprite_frames.has_animation("dead"):
		play_anim("dead")
	else:
		_on_animation_finished()


func move_and_slide_clamped():
	move_and_slide()
	global_position.y = clamp(global_position.y, 55.0, 235.0)
