extends Control

@onready var title_label: Label = $PanelContainer/VBoxContainer/TitleLabel
@onready var coins_label: Label = $PanelContainer/VBoxContainer/CoinsLabel

var is_win: bool = false
var coins_collected: int = 0

func _ready() -> void:
	hide()  # Start hidden
	process_mode = Node.PROCESS_MODE_ALWAYS  # Always process even when paused

func show_game_over(won: bool, coins: int) -> void:
	is_win = won
	coins_collected = coins
	
	# Pause the game first
	get_tree().paused = true
	
	# Update title
	if is_win:
		title_label.text = "YOU WIN!"
		title_label.modulate = Color(0.2, 1, 0.2)  # Green
	else:
		title_label.text = "GAME OVER"
		title_label.modulate = Color(1, 0.2, 0.2)  # Red
	
	# Update coins display
	coins_label.text = "Coins: " + str(coins_collected)
	
	# Show the UI
	show()

func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()
