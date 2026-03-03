extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var debug_label: Label = null

const SPEED = 150.0
const JUMP_VELOCITY = -300.0
const DOUBLE_JUMP_VELOCITY = -250.0
const ACCELERATION = 1200.0
const FRICTION = 1000.0
const DASH_SPEED = 300.0
const DASH_DURATION = 0.15
const DASH_COOLDOWN = 0.5

var jump_count: int = 0
var max_jumps: int = 2
var facing_right: bool = true
var just_double_jumped: bool = false

# Dash system
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_direction: int = 0
var dash_start_y: float = 0.0

# Collision tracking
var is_colliding_ground: bool = false
var is_colliding_platform: bool = false
var is_colliding_spike: bool = false
var collision_info: Array = []

# Death and respawn
var spawn_position: Vector2
var is_dead: bool = false
var is_respawning: bool = false
var falling_in_pit: bool = false

# Platform drop-through system
var platform_drop_timer: float = 0.0
const PLATFORM_DROP_DURATION: float = 0.2

# Track previous collision states to avoid spam
var prev_colliding_ground: bool = false
var prev_colliding_platform: bool = false
var prev_colliding_spike: bool = false

# Collectibles
var coins: int = 0

# Lives system
var lives: int = 3
var max_lives: int = 3


func _ready() -> void:
	# Save spawn position
	spawn_position = position
	
	# Connect to animation finished signal
	sprite.animation_finished.connect(_on_animation_finished)
	
	# Create debug label
	debug_label = Label.new()
	debug_label.position = Vector2(10, 10)
	debug_label.add_theme_font_size_override("font_size", 12)
	# Add to a CanvasLayer so it stays on screen
	var canvas_layer = CanvasLayer.new()
	canvas_layer.add_child(debug_label)
	add_child(canvas_layer)


func _physics_process(delta: float) -> void:
	# Don't process if dead or respawning (unless falling in pit)
	if (is_dead or is_respawning) and not falling_in_pit:
		return
	
	# If falling in pit, only apply gravity and movement
	if falling_in_pit:
		velocity += get_gravity() * delta
		move_and_slide()
		return
	
	# Update dash cooldown
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	
	# Handle dashing
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			# End dash
			is_dashing = false
			dash_cooldown_timer = DASH_COOLDOWN
		else:
			# During dash: maintain horizontal speed and Y position
			velocity.x = dash_direction * DASH_SPEED
			velocity.y = 0  # Lock Y position during dash
			position.y = dash_start_y  # Force keep Y position
			move_and_slide()
			check_collisions()
			update_debug_display()
			return  # Skip rest of physics processing while dashing
	
	# Update platform drop timer
	if platform_drop_timer > 0:
		platform_drop_timer -= delta
		if platform_drop_timer <= 0:
			# Re-enable platform collision
			set_collision_mask_value(2, true)  # Layer 2 = platforms
	
	# Add gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		# Reset jump count when on floor
		jump_count = 0
		just_double_jumped = false  # Reset double jump flag on landing
	
	# Handle jump and double jump
	if Input.is_action_just_pressed("jump"):
		if is_on_floor():
			# First jump
			velocity.y = JUMP_VELOCITY
			jump_count = 1
			just_double_jumped = false
		elif jump_count < max_jumps:
			# Double jump
			velocity.y = DOUBLE_JUMP_VELOCITY
			jump_count += 1
			just_double_jumped = true
	
	# Handle dash input (only if not on cooldown and not already dashing)
	if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0 and not is_dashing:
		# Start dash in current facing direction
		is_dashing = true
		dash_timer = DASH_DURATION
		dash_direction = 1 if facing_right else -1
		dash_start_y = position.y  # Remember Y position at start of dash
		velocity.x = dash_direction * DASH_SPEED
		velocity.y = 0
	
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
	is_colliding_spike = false
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
						if not 1 in collision_data["layers"]:
							collision_data["layers"].append(1)
					
					# Check if this physics layer is on collision layer 2 (platforms)
					if collision_layer_mask & 2:  # Layer 2
						if not is_colliding_platform:
							is_colliding_platform = true
						if not 2 in collision_data["layers"]:
							collision_data["layers"].append(2)
					
					# Check if this physics layer is on collision layer 3 (spikes)
					if collision_layer_mask & 4:  # Layer 3 (bit 2 = value 4)
						if not is_colliding_spike:
							is_colliding_spike = true
							if not prev_colliding_spike:
								die()
						if not 3 in collision_data["layers"]:
							collision_data["layers"].append(3)
		
		collision_info.append(collision_data)
	
	# Print when collision state changes (removed spam)
	
	# Update previous states
	prev_colliding_ground = is_colliding_ground
	prev_colliding_platform = is_colliding_platform
	prev_colliding_spike = is_colliding_spike

func die() -> void:
	if is_dead:
		return
	
	is_dead = true
	is_dashing = false  # Cancel dash on death
	lives -= 1
	print("Lives remaining: ", lives)
	
	# Play death animation
	sprite.play("die")
	
	# Disable physics temporarily
	velocity = Vector2.ZERO
	
	# Wait a moment then respawn or game over
	await get_tree().create_timer(0.5).timeout
	
	if lives > 0:
		respawn()
	else:
		reset_game()

func die_from_pit() -> void:
	if is_dead:
		return
	
	is_dead = true
	falling_in_pit = true
	is_dashing = false  # Cancel dash on death
	lives -= 1
	print("Lives remaining: ", lives)
	
	# Let player continue falling (don't freeze physics)
	# Wait for them to fall out of view before respawning
	await get_tree().create_timer(1.5).timeout
	falling_in_pit = false
	
	if lives > 0:
		respawn()
	else:
		reset_game()

func respawn() -> void:
	# Set respawning flag first to prevent camera from following
	is_respawning = true
	
	position = spawn_position
	velocity = Vector2.ZERO
	is_dead = false
	is_colliding_spike = false
	prev_colliding_spike = false
	is_dashing = false
	dash_timer = 0.0
	dash_cooldown_timer = 0.0
	just_double_jumped = false
	
	# Play respawn animation
	sprite.play("respawn")
	# Controls will be unlocked when animation finishes
	
	# Update previous states
	prev_colliding_ground = is_colliding_ground
	prev_colliding_platform = is_colliding_platform


func _on_animation_finished() -> void:
	# Unlock controls when respawn animation finishes
	if sprite.animation == "respawn":
		is_respawning = false


func reset_game() -> void:
	print("Game Over! Resetting...")
	# Reset lives and coins
	lives = max_lives
	coins = 0
	# Reload the current scene
	get_tree().reload_current_scene()


func win() -> void:
	print("🎉 You Win! 🎉")
	print("Total Coins Collected: ", coins)
	# Freeze player
	is_dead = true
	velocity = Vector2.ZERO
	# Wait a moment before reloading
	await get_tree().create_timer(2.0).timeout
	# Reset and reload the scene
	lives = max_lives
	coins = 0
	get_tree().reload_current_scene()


func update_debug_display() -> void:
	if debug_label == null:
		return
	
	var debug_text = "=== PLAYER DEBUG ===\n"
	debug_text += "Lives: " + str(lives) + "/" + str(max_lives) + "\n"
	debug_text += "Coins: " + str(coins) + "\n\n"
	debug_text += "Position: " + str(global_position.snapped(Vector2(0.1, 0.1))) + "\n"
	debug_text += "Velocity: " + str(velocity.snapped(Vector2(0.1, 0.1))) + "\n"
	debug_text += "On Floor: " + str(is_on_floor()) + "\n\n"
	debug_text += "Ground Collision: " + ("✓" if is_colliding_ground else "✗") + "\n"
	debug_text += "Total Collisions: " + str(get_slide_collision_count()) + "\n"
	
	debug_label.text = debug_text


func update_animation(direction: float) -> void:
	# Flip sprite based on facing direction
	sprite.flip_h = not facing_right
	
	# Determine which animation to play based on movement and state
	if is_dashing:
		# Dashing animation
		sprite.play("dash")
	elif is_on_floor():
		if abs(velocity.x) > 10:
			# Running
			sprite.play("run")
		else:
			# Idle
			sprite.play("idle")
	else:
		# In air
		if just_double_jumped:
			# Double jump animation
			sprite.play("double_jump")
		elif velocity.y < 0:
			# Moving up (jumping)
			sprite.play("jump_up")
		elif abs(velocity.x) > 10:
			# Moving horizontally in air
			sprite.play("jump_mid")
		else:
			# Falling or stationary in air
			sprite.play("jump_fall")


func add_coin(value: int) -> void:
	coins += value
	print("Coins collected: ", coins)
