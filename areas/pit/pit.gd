extends Area2D

## Death zone that kills the player on contact

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		if body.has_method("die"):
			body.die()
			print("Player fell into pit!")
