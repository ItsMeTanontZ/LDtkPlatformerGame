extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$AnimationPlayer.play("RESET")
	hide()  # Start hidden

# Called every frame. 'delta' is the elapsed time since the previous frame.
func test_esc():
	if Input.is_action_just_pressed("pause") and !get_tree().paused:
		pause()
	elif Input.is_action_just_pressed("pause") and get_tree().paused:
		resume()

func resume():
	get_tree().paused = false
	$AnimationPlayer.play_backwards("blur")
	hide()

func pause():
	get_tree().paused = true
	show()
	$AnimationPlayer.play("blur")

func _on_resume_pressed() -> void:
	resume()

func _on_restart_pressed() -> void:
	resume()
	get_tree().reload_current_scene()

func _on_exit_pressed() -> void:
	get_tree().quit()
	
func _process(delta: float) -> void:
	test_esc()
