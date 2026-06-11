class_name Hitbox
extends Area2D

@export var damage: float = 10.0
@export var knockback: float = 200.0
@export var knockback_dir: Vector2 = Vector2.RIGHT

var attacker = null

func _ready():
	# Default collision layer/mask setup for combat
	# Layer 3: Player Hitbox, Layer 4: Enemy Hitbox
	pass
