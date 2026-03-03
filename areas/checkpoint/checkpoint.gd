extends Area2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var is_activated: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	# Ensure sprite starts with not_activated animation
	if sprite:
		sprite.play("not_activated")

func _on_body_entered(body: Node2D) -> void:
	if is_activated:
		return
	
	if body.name == "Player" or body.is_in_group("player"):
		is_activated = true
		# Update player's spawn position to this checkpoint
		body.spawn_position = global_position
		print("Checkpoint activated at: ", global_position)
		
		# Change sprite to activated animation
		if sprite:
			sprite.play("activated")
