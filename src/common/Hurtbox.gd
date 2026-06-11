class_name Hurtbox
extends Area2D

signal hit_received(damage, knockback, knockback_dir)

func _ready():
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D):
	if area is Hitbox:
		# If hitting own master, ignore
		if area.attacker == owner:
			return
		
		# Calculate knockback direction relative to attacker
		var dir = Vector2.RIGHT
		if area.owner:
			var relative_diff = owner.global_position.x - area.owner.global_position.x
			dir = Vector2.RIGHT if relative_diff >= 0 else Vector2.LEFT
		
		hit_received.emit(area.damage, area.knockback, dir)
