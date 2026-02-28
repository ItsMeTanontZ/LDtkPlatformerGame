extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

const SPEED = 150.0
const JUMP_VELOCITY = -300.0
const DOUBLE_JUMP_VELOCITY = -250.0
const ACCELERATION = 1200.0
const FRICTION = 1000.0

var jump_count: int = 0
var max_jumps: int = 2
var facing_right: bool = true


func _physics_process(delta: float) -> void:
	# Add gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	else:
		# Reset jump count when on floor
		jump_count = 0
	
	# Handle jump and double jump
	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor():
			# First jump
			velocity.y = JUMP_VELOCITY
			jump_count = 1
		elif jump_count < max_jumps:
			# Double jump
			velocity.y = DOUBLE_JUMP_VELOCITY
			jump_count += 1
	
	# Handle platform drop-through with "S" or "Down" key
	if Input.is_action_pressed("ui_down") and is_on_floor():
		# Use set_collision_mask_value to temporarily allow passing through platforms
		# This assumes platforms are on collision layer 1
		# Move down to pass through one-way platforms
		position.y += 2
	
	# Get movement input
	var direction := Input.get_axis("ui_left", "ui_right")
	
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
