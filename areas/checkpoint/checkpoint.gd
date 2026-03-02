extends Area2D

var is_activated: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if is_activated:
		return
	
	if body.name == "Player" or body.is_in_group("player"):
		is_activated = true
		# Update player's spawn position to this checkpoint
		body.spawn_position = global_position
		print("Checkpoint activated at: ", global_position)
		
		# Visual feedback (you can add animation/sprite changes here)
		modulate = Color(0, 1, 0, 1)  # Turn green when activated
