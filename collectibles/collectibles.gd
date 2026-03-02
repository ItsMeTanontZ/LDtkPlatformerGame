extends Area2D
class_name Collectible

## Base class for all collectible items in the game
## Extend this class and override _on_collected() to implement custom behavior

func _ready() -> void:
	# Connect the body_entered signal
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Check if the body is the player
	if body.name == "Player" or body.is_in_group("player"):
		_on_collected(body)
		queue_free()  # Remove the collectible from the scene

## Virtual method to be overridden by child classes
## Called when the player collects this item
func _on_collected(player: Node2D) -> void:
	pass  # Override this in child classes
