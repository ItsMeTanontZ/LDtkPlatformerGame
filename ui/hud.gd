extends CanvasLayer

@onready var lives_label: Label = $MarginContainer/HBoxContainer/LivesLabel
@onready var coins_label: Label = $MarginContainer/HBoxContainer/CoinsLabel
@onready var tutorial_label: Label = $MarginContainer/TutorialContainer/TutorialLabel

var current_stage: int = -1
var tutorial_shown: bool = false
var tutorial_timer: float = 0.0
const TUTORIAL_DISPLAY_TIME: float = 5.0

# Tutorial texts for each stage
var tutorial_texts: Dictionary = {
	0: "Use WASD to move",
	1: "Press SPACE to jump",
	2: "Press SPACE twice to double jump",
	3: "Yellow platforms are solid\nGreen platforms: Press S to drop through",
	4: "Avoid the spikes!",
	5: "Don't fall into pits!"
}

func _ready() -> void:
	# Initialize display
	update_lives(3)
	update_coins(0)
	tutorial_label.text = ""

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
		
		# Get the camera to determine current stage
		var camera = player.get_node_or_null("Camera2D")
		if camera and "current_room_x" in camera:
			var stage = camera.current_room_x
			
			# Check if we entered a new stage
			if stage != current_stage:
				current_stage = stage
				tutorial_shown = false
				tutorial_timer = 0.0
				show_tutorial_for_stage(stage)
		
		# Update tutorial timer and fade out
		if tutorial_timer > 0:
			tutorial_timer -= _delta
			if tutorial_timer <= 0:
				hide_tutorial()
			elif tutorial_timer < 1.0:
				# Fade out in the last second
				tutorial_label.modulate.a = tutorial_timer

func show_tutorial_for_stage(stage: int) -> void:
	if tutorial_texts.has(stage) and not tutorial_shown:
		tutorial_label.text = tutorial_texts[stage]
		tutorial_label.modulate.a = 1.0
		tutorial_timer = TUTORIAL_DISPLAY_TIME
		tutorial_shown = true
	else:
		# No tutorial for this stage
		tutorial_label.text = ""
		tutorial_label.modulate.a = 0.0

func hide_tutorial() -> void:
	tutorial_label.modulate.a = 0.0
