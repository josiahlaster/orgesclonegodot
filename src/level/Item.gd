extends CharacterBody2D

@onready var sprite = $AnimatedSprite2D

func _ready():
	# Configure detection Area2D dynamically
	var area = Area2D.new()
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(40, 30)
	col.shape = shape
	area.add_child(col)
	add_child(area)
	
	area.body_entered.connect(_on_body_entered)
	
	if sprite:
		var anims = sprite.sprite_frames.get_animation_names()
		if anims.size() > 0:
			sprite.play(anims[0])

func _on_body_entered(body):
	# If player walks over the item, apply effect
	if body.is_in_group("player"):
		if name.to_lower().contains("hp_hundred") or name.to_lower().contains("meat"):
			Globals.set_player_health(Globals.player_health + 40.0) # Heal 40 HP
		else:
			Globals.add_score(500) # Give 500 points
			
		# Play pick up sound
		var sound = AudioStreamPlayer.new()
		sound.stream = load("res://assets/sounds/1up.wav")
		get_tree().current_scene.add_child(sound)
		sound.play()
		
		# Free sound node when done
		sound.finished.connect(sound.queue_free)
		
		queue_free()
