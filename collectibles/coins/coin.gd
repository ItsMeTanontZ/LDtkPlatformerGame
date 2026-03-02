extends Collectible

## Coin collectible that adds 1 coin to the player

func _on_collected(player: Node2D) -> void:
	# Add coin to player
	if player.has_method("add_coin"):
		player.add_coin(5)
