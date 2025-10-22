extends CharacterBody2D


const MAX_SPEED = 200.0
const ACCELERATION = 10.0
const JUMP_VELOCITY = -500.0
const PLAYER_GRAVITY = 980.0
const ROTATION_SPEED = 10.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

enum GravityDirection { DOWN, UP, RIGHT, LEFT }
var GravOrientation = { GravityDirection.DOWN: 0, GravityDirection.RIGHT: -90, 
						GravityDirection.LEFT: 90, GravityDirection.UP: 180}

var in_air: bool = false
var PlayerGravity = GravityDirection.DOWN

func _physics_process(delta: float) -> void:
	# Get input direction: -1, 0, 1 (-1 when left, 1 when right)
	var direction := Input.get_axis("move_left", "move_right")
	
	# Add the gravity. Will change with PlayerGravity state
	if not is_on_floor():
		match PlayerGravity:
			GravityDirection.DOWN:
				velocity.y += PLAYER_GRAVITY * delta
				rotation = move_toward(rotation, GravOrientation[PlayerGravity], 
										ROTATION_SPEED)
		if not in_air:
			in_air = true
			animated_sprite.play("jump_start")
	else:
		match PlayerGravity:
			GravityDirection.UP:
				velocity.y -= PLAYER_GRAVITY * delta
				rotation = move_toward(rotation, GravOrientation[PlayerGravity], 
										ROTATION_SPEED)
			GravityDirection.RIGHT:
				velocity.x += PLAYER_GRAVITY * delta
				rotation = move_toward(rotation, GravOrientation[PlayerGravity], 
										ROTATION_SPEED)
			GravityDirection.LEFT:
				velocity.x -= PLAYER_GRAVITY * delta
				rotation = move_toward(rotation, GravOrientation[PlayerGravity], 
										ROTATION_SPEED)
		if in_air:
			in_air = false
			animated_sprite.play("jump_end")
		
		#supposed to only play once jump end animation is done, this doesn't 
		#work and it would require to much time to complete right now
		if animated_sprite.animation_finished:
			if direction == 0:
				animated_sprite.play("idle")
			else:
				animated_sprite.play("run")

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# :DEBUG: change gravity with ijkl, will be hooked to random timer later
	if Input.is_action_just_pressed("grav_up"):
		PlayerGravity = GravityDirection.UP
	if Input.is_action_just_pressed("grav_down"):
		PlayerGravity = GravityDirection.DOWN
	if Input.is_action_just_pressed("grav_left"):
		PlayerGravity = GravityDirection.LEFT
	if Input.is_action_just_pressed("grav_right"):
		PlayerGravity = GravityDirection.RIGHT
	
	# Flip the Sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
	
	# Apply movement
	if direction:
		velocity.x = move_toward(velocity.x, direction * MAX_SPEED, ACCELERATION)
	else:
		if PlayerGravity == GravityDirection.DOWN:
			velocity.x = move_toward(velocity.x, 0, MAX_SPEED)

	move_and_slide()
