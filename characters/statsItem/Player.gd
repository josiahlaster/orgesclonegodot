extends CharacterBody2D
 
const SPEED = 100.0
const JUMP_VELOCITY = -200.0
 
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
 
@onready var anim_player = $AnimationPlayer
@onready var sprite = $AnimatedSprite2D
@onready var attack_hitbox = $AttackHitbox
@onready var attack_collision = $AttackHitbox/CollisionShape2D

var is_attacking = false

func _ready():
    # Make sure attack collision starts disabled
    if attack_collision:
        attack_collision.disabled = true
    # Connect sprite animation finished signal
    sprite.animation_finished.connect(_on_animation_finished)
 
func _physics_process(delta):
    # Add the gravity.
    if not is_on_floor():
        velocity.y += gravity * delta
 
    # Handle Jump (cannot jump while attacking on floor).
    if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not is_attacking:
        velocity.y = JUMP_VELOCITY
 
    # Check for combo transitions during attacks
    if is_attacking:
        if sprite.animation == "attack1" and Input.is_physical_key_pressed(KEY_A) and sprite.frame >= 1:
            trigger_attack("attack2")
        elif sprite.animation == "attack2" and Input.is_physical_key_pressed(KEY_A) and sprite.frame >= 1:
            trigger_attack("attack3")

    # Handle attacks if not already performing one
    if not is_attacking:
        if Input.is_physical_key_pressed(KEY_A):
            if not is_on_floor():
                trigger_attack("jumpattack")
            elif velocity.x != 0:
                trigger_attack("runattack")
            else:
                trigger_attack("attack1")
        elif Input.is_physical_key_pressed(KEY_S):
            trigger_attack("chargeattack")
        elif Input.is_physical_key_pressed(KEY_D):
            trigger_attack("freespecial")
        elif Input.is_physical_key_pressed(KEY_F):
            trigger_attack("freespecial2")
        elif Input.is_physical_key_pressed(KEY_W):
            trigger_attack("freespecial3")

    # Get the input direction and handle the movement/deceleration.
    var direction = Input.get_axis("ui_left", "ui_right")
    
    # Disable movement during ground attacks (except run/jump attacks)
    if is_attacking and sprite.animation not in ["runattack", "jumpattack", "jumpattack2"]:
        direction = 0
        velocity.x = move_toward(velocity.x, 0, SPEED)

    if direction:
        velocity.x = direction * SPEED
        sprite.flip_h = direction < 0
    else:
        velocity.x = move_toward(velocity.x, 0, SPEED)
 
    # Handle animations (if not attacking)
    if not is_attacking:
        if not is_on_floor():
            if sprite.sprite_frames.has_animation("jump"):
                sprite.play("jump")
        else:
            if velocity.x != 0:
                if sprite.sprite_frames.has_animation("run"):
                    sprite.play("run")
                elif sprite.sprite_frames.has_animation("walk"):
                    sprite.play("walk")
            else:
                if sprite.sprite_frames.has_animation("idle"):
                    sprite.play("idle")
 
    move_and_slide()

func trigger_attack(anim_name: String):
    if sprite.sprite_frames.has_animation(anim_name):
        is_attacking = true
        sprite.play(anim_name)
        if attack_collision:
            attack_collision.disabled = false

func _on_animation_finished():
    if is_attacking:
        is_attacking = false
        if attack_collision:
            attack_collision.disabled = true
