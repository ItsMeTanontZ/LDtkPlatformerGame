extends CanvasLayer

@onready var lives_label: Label = $MarginContainer/HBoxContainer/LivesLabel
@onready var coins_label: Label = $MarginContainer/HBoxContainer/CoinsLabel

func _ready() -> void:
	# Initialize display
	update_lives(3)
	update_coins(0)

func update_lives(lives: int) -> void:
	lives_label.text = "Lives: " + str(lives)

func update_coins(coin_count: int) -> void:
	coins_label.text = "Coins: " + str(coin_count)

func get_player() -> Node:
	return get_tree().get_first_node_in_group("player")

func _process(_delta: float) -> void:
	var player = get_player()
	if player:
		if player.has_method("get") or "lives" in player and "coins" in player:
			update_lives(player.lives)
			update_coins(player.coins)
