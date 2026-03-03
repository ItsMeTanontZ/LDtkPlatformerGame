extends Area2D

## Win zone that triggers victory when player enters

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		if body.has_method("win"):
			body.win()
			print("Player reached the win zone!")
