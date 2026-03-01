extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var debug_label: Label = null

const SPEED = 150.0
const JUMP_VELOCITY = -300.0
const DOUBLE_JUMP_VELOCITY = -250.0
const ACCELERATION = 1200.0
const FRICTION = 1000.0

var jump_count: int = 0
var max_jumps: int = 2
var facing_right: bool = true

# Collision tracking
var is_colliding_ground: bool = false
var is_colliding_platform: bool = false
var collision_info: Array = []

# Platform drop-through system
var platform_drop_timer: float = 0.0
const PLATFORM_DROP_DURATION: float = 0.2

# Track previous collision states to avoid spam
var prev_colliding_ground: bool = false
var prev_colliding_platform: bool = false


func _ready() -> void:
	# Set player's own collision layer (what layer the player exists on)
	collision_layer = 0b1000  # Put player on layer 4 (separate from tiles)
	
	# Set collision mask to detect layers 1 (ground) and 2 (platforms)
	collision_mask = 0b11  # Binary: 11 = layers 1 and 2 (bitmask: 1 + 2 = 3)
	
	print("Player collision_layer set to: ", collision_layer)
	print("Player collision_mask set to: ", collision_mask)
	
	# Create debug label
	debug_label = Label.new()
	debug_label.position = Vector2(10, 10)
	debug_label.add_theme_font_size_override("font_size", 12)
	# Add to a CanvasLayer so it stays on screen
	var canvas_layer = CanvasLayer.new()
	canvas_layer.add_child(debug_label)
	add_child(canvas_layer)


func _physics_process(delta: float) -> void:
	# Update platform drop timer
	if platform_drop_timer > 0:
		platform_drop_timer -= delta
		if platform_drop_timer <= 0:
			# Re-enable platform collision
			set_collision_mask_value(2, true)  # Layer 2 = platforms
			print("Platform collision re-enabled")
	
	# Add gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		# Reset jump count when on floor
		jump_count = 0
	
	# Handle jump and double jump
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			# First jump
			velocity.y = JUMP_VELOCITY
			jump_count = 1
		elif jump_count < max_jumps:
			# Double jump
			velocity.y = DOUBLE_JUMP_VELOCITY
			jump_count += 1
	
	# Get movement input
	var direction := Input.get_axis("move_left", "move_right")
	
	# Apply movement with acceleration and friction
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
		# Update facing direction
		if direction > 0:
			facing_right = true
		else:
			facing_right = false
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
	
	# Update animations
	update_animation(direction)
	
	move_and_slide()
	
	# Check collisions after move_and_slide (BEFORE input check for drop-through)
	check_collisions()
	
	# Handle platform drop-through with "Down" key
	# This needs to be AFTER collision check so we have current frame data
	if Input.is_action_pressed("move_down") and is_on_floor():
		# Check if we're standing on a platform (layer 2)
		if is_colliding_platform:
			print("🔽 Dropping through platform!")
			# Temporarily disable platform collision
			set_collision_mask_value(2, false)  # Layer 2 = platforms
			platform_drop_timer = PLATFORM_DROP_DURATION
			# Give a small downward push to help start falling
			position.y += 2
	
	update_debug_display()


func check_collisions() -> void:
	# Reset collision flags
	is_colliding_ground = false
	is_colliding_platform = false
	collision_info.clear()
	
	var collision_count = get_slide_collision_count()
	
	# Check all slide collisions
	for i in range(collision_count):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider == null:
			continue
		
		# Get collision information
		var collision_data = {
			"name": collider.name if collider.has_method("get_name") else "Unknown",
			"type": collider.get_class(),
			"layers": []
		}
		
		# Check if collider is a TileMap or TileMapLayer to get layer info
		var tilemap = null
		var tileset = null
		
		if collider is TileMapLayer:
			var tilemaplayer = collider as TileMapLayer
			collision_data["tilemap_name"] = tilemaplayer.name
			tileset = tilemaplayer.tile_set
		elif collider is TileMap:
			tilemap = collider as TileMap
			collision_data["tilemap_name"] = tilemap.name
			tileset = tilemap.tile_set
		
		if tileset:
				# Check all physics layers in the tileset
				for physics_layer in range(tileset.get_physics_layers_count()):
					var collision_layer_mask = tileset.get_physics_layer_collision_layer(physics_layer)
					
					# Check if this physics layer is on collision layer 1 (ground)
					if collision_layer_mask & 1:  # Layer 1
						if not is_colliding_ground:
							is_colliding_ground = true
							if not prev_colliding_ground:
								print("🟫 GROUND (", collision_data["tilemap_name"], ")")
						if not 1 in collision_data["layers"]:
							collision_data["layers"].append(1)
					
					# Check if this physics layer is on collision layer 2 (platforms)
					if collision_layer_mask & 2:  # Layer 2
						if not is_colliding_platform:
							is_colliding_platform = true
							if not prev_colliding_platform:
								print("🟦 PLATFORM (", collision_data["tilemap_name"], ")")
						if not 2 in collision_data["layers"]:
							collision_data["layers"].append(2)
		
		collision_info.append(collision_data)
	
	# Print when collision state changes (removed spam)
	
	# Update previous states
	prev_colliding_ground = is_colliding_ground
	prev_colliding_platform = is_colliding_platform


func update_debug_display() -> void:
	if debug_label == null:
		return
	
	var debug_text = "=== PLAYER DEBUG ===\n"
	debug_text += "Position: " + str(global_position.snapped(Vector2(0.1, 0.1))) + "\n"
	debug_text += "Velocity: " + str(velocity.snapped(Vector2(0.1, 0.1))) + "\n"
	debug_text += "On Floor: " + str(is_on_floor()) + "\n\n"
	debug_text += "Ground Collision: " + ("✓" if is_colliding_ground else "✗") + "\n"
	debug_text += "Total Collisions: " + str(get_slide_collision_count()) + "\n"
	
	debug_label.text = debug_text


func update_animation(direction: float) -> void:
	# Determine which animation to play based on movement and state
	if is_on_floor():
		if abs(velocity.x) > 10:
			# Running
			if facing_right:
				sprite.play("run")
			else:
				sprite.play("run")
		else:
			# Idle
			if facing_right:
				sprite.play("idle")
			else:
				sprite.play("idle")
	else:
		# In air - could add jump/fall animations if available
		if abs(velocity.x) > 10:
			# Use dash animation for air movement
			if facing_right:
				sprite.play("dash")
			else:
				sprite.play("dash")
		else:
			# Use idle animation in air if not moving horizontally
			if facing_right:
				sprite.play("idle")
			else:
				sprite.play("idle")
