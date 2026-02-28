extends Camera2D

const ROOM_WIDTH = 320
const ROOM_HEIGHT = 240

var current_room_x: int = 0
var current_room_y: int = 0


func _process(_delta: float) -> void:
	var player_pos = get_parent().global_position
	
	# Calculate which room the player is in
	var room_x = floor(player_pos.x / ROOM_WIDTH)
	var room_y = floor(player_pos.y / ROOM_HEIGHT)
	
	# Update camera position if player entered a new room
	if room_x != current_room_x or room_y != current_room_y:
		current_room_x = room_x
		current_room_y = room_y
	
	# Position camera at the center of the current room
	var target_x = current_room_x * ROOM_WIDTH + ROOM_WIDTH / 2
	var target_y = current_room_y * ROOM_HEIGHT + ROOM_HEIGHT / 2
	
	global_position = Vector2(target_x, target_y)
