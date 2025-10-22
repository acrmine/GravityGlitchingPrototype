extends CharacterBody2D


const MAX_SPEED = 200.0
const ACCELERATION = 20.0
const AIR_ACCELERATION = 5.0
const JUMP_VELOCITY = -500.0
const PLAYER_GRAVITY = 980.0
const ROTATION_SPEED = 10.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D

var in_air: bool = false
var in_air_animation: bool = false

func _physics_process(delta: float) -> void:
	# :DEBUG: change gravity with j/l or k to flip, will be hooked to random timer later
	if Input.is_action_just_pressed("grav_down"):
		up_direction = -up_direction
	if Input.is_action_just_pressed("grav_left"):
		up_direction = up_direction.rotated(deg_to_rad(90))
	if Input.is_action_just_pressed("grav_right"):
		up_direction = up_direction.rotated(deg_to_rad(-90))

	var down_direction = -up_direction
	var right_direction = up_direction.rotated(deg_to_rad(90))

	# Get input direction: -1, 0, 1 (-1 when left, 1 when right)
	var direction := Input.get_axis("move_left", "move_right")

	# Vertical Movement
	if is_on_floor():
		if Input.is_action_just_pressed("jump"):
			velocity += down_direction * JUMP_VELOCITY
			if not in_air:
				in_air = true
				animated_sprite.play("jump_start")
				in_air_animation = true
		else:
			if in_air:
				in_air = false
				animated_sprite.play("jump_end")
				in_air_animation = true
	else:
		velocity += down_direction * PLAYER_GRAVITY * delta

	# Horizontal Movement
	var ground = is_on_floor() || (in_air && in_air_animation)
	if down_direction.y > 0.000001 || down_direction.y < -0.000001:
		velocity.x = move_toward(velocity.x, right_direction.x * direction * MAX_SPEED, ACCELERATION if ground else AIR_ACCELERATION)
	else:
		velocity.y = move_toward(velocity.y, right_direction.y * direction * MAX_SPEED, ACCELERATION if ground else AIR_ACCELERATION)

	# Ground Animations
	if in_air_animation && !animated_sprite.is_playing():
		in_air_animation = false

	if !in_air_animation:
		if direction == 0:
			animated_sprite.play("idle")
		else:
			animated_sprite.play("run")

	# Sprite
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true

	# Camera
	rotation = rotate_toward(
		rotation,
		right_direction.angle(),
		ROTATION_SPEED * delta
	)

	move_and_slide()
