extends CharacterBody2D


const MAX_SPEED = 200.0
const ACCELERATION = 20.0
const AIR_ACCELERATION = 5.0
const JUMP_VELOCITY = -500.0
const PLAYER_GRAVITY = 980.0
const ROTATION_SPEED = 10.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var camera: Camera2D = $Camera2D
@onready var player: CharacterBody2D = $"."
@onready var gravCountdown: Label = $Camera2D/UI/GravCountdownNotif
@onready var deathbox: Area2D = $"../DeathBoxes"
@onready var deathsound := $WhiteNoiseDeath
@onready var mode_label: Label = $Camera2D/UI/ModeLabel

class GravityHandler:
	# time_before_switch in seconds, change it to change timer
	var time_before_switch: float = 10.0
	var elapsed_cntdwn: float = time_before_switch
	var randGravDirection: int = 0
	var countPresent: bool = true
	var player: CharacterBody2D
	var cntdwnLbl: Label
	var mode_label: Label
	var cntdwnlbltoppos: Vector2
	var cntdwnlblbotpos: Vector2
	var currgravdirection: int = 0
	var posGravDirections = [ "DOWN", "RIGHT", "UP", "LEFT" ]
	var grav_mode: String = "None"

	func _init(playerRef: CharacterBody2D, cntdwnLblRef: Label, modeLblRef: Label) -> void:
		player = playerRef
		cntdwnLbl = cntdwnLblRef
		cntdwnlbltoppos = cntdwnLbl.position
		cntdwnlblbotpos = cntdwnLbl.position
		cntdwnlblbotpos.y += 200
		toggleGravCntdwn()
		mode_label = modeLblRef

	func rotate_right():
		rotateGravDirection(-1)
	
	func rotate_left():
		rotateGravDirection(1)
	
	func flip():
		rotateGravDirection(2)
	
	#positive rotates left, negative rotates right
	func rotateGravDirection(rotations: int):
		while rotations != 0:
			if rotations < 0:
				currgravdirection -= 1
				rotations += 1
				if currgravdirection < 0:
					currgravdirection = posGravDirections.size() - 1
				player.up_direction = player.up_direction.orthogonal()
			else:
				currgravdirection += 1
				rotations -= 1
				if currgravdirection > posGravDirections.size() - 1:
					currgravdirection = 0
				player.up_direction = -player.up_direction.orthogonal()
	
	func setGravDirection(newGravDirection: String):
		var numGravDirection: int = posGravDirections.find(newGravDirection)
		if currgravdirection == numGravDirection:
			return
		var diff: int = numGravDirection - currgravdirection
		if diff < -2:
			diff += 4
		if diff > 2:
			diff -= 4
		rotateGravDirection(diff)
	
	func getGravDirection() -> String:
		return posGravDirections[currgravdirection]
	
	func toggleGravCntdwn():
		if countPresent:
			cntdwnLbl.position = cntdwnlblbotpos
			countPresent = false
		else:
			var tween = cntdwnLbl.create_tween()
			tween.tween_property(cntdwnLbl, "position", cntdwnlbltoppos, 1.0)
			tween.set_ease(Tween.EASE_IN)
			countPresent = true
	
	func updtUsrInptGrav():
		if Input.is_action_just_pressed("grav_down"):
			flip()
		if Input.is_action_just_pressed("grav_left"):
			rotate_left()
		if Input.is_action_just_pressed("grav_right"):
			rotate_right()
	
	func updtGravTimer(frame_delta: float):
		elapsed_cntdwn -= frame_delta
		
		if(elapsed_cntdwn < 6.0):
			if !countPresent:
				toggleGravCntdwn()
				randGravDirection = randi_range(0, 2)
			cntdwnLbl.text = str(int(elapsed_cntdwn))
		
		if elapsed_cntdwn <= 0:
			if countPresent:
				toggleGravCntdwn()
			elapsed_cntdwn = time_before_switch
			match randGravDirection:
				0:
					rotate_left()
				1:
					flip()
				2:
					rotate_right()
	
	func update(frame_delta: float):
		if Input.is_action_just_pressed("switch_player_mode"):
			if grav_mode == "Timer":
				grav_mode = "Manual"
			elif grav_mode == "Manual":
				grav_mode = "None"
			else:
				grav_mode = "Timer"
			mode_label.text = "Mode: " + grav_mode + " (press m to change it)"
		
		if grav_mode == "Timer":
			updtGravTimer(frame_delta)
		elif grav_mode == "Manual":
			updtUsrInptGrav()
		elif grav_mode == "None":
			pass


var in_air: bool = false
var in_air_animation: bool = false
var dying: bool = false

var grav_handler: GravityHandler

func _ready() -> void:
	grav_handler = GravityHandler.new(player, gravCountdown, mode_label)
	

func _physics_process(delta: float) -> void:
	if !dying:
		grav_handler.update(delta)
	else:
		if grav_handler.countPresent:
			grav_handler.toggleGravCntdwn()
	
	var down_direction = -up_direction
	var right_direction = -up_direction.orthogonal()

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
	var target_velocity = right_direction * direction * MAX_SPEED
	var acceleration = ACCELERATION if is_on_floor() || (in_air && in_air_animation) else AIR_ACCELERATION
	velocity = velocity.project(right_direction).move_toward(target_velocity, acceleration) + velocity.slide(right_direction)

	# Ground Animations
	if in_air_animation && !animated_sprite.is_playing():
		in_air_animation = false

	if !in_air:
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
		ROTATION_SPEED * delta,
	)
	deathchecker(delta)
	move_and_slide()

var deathcntdwn = 5.0

func deathchecker(delta: float) -> void:
	if dying:
		if !deathsound.playing:
			deathsound.play()
		deathsound.volume_db += delta * 6.0
		deathcntdwn -= delta
		if deathcntdwn <= 0:
			get_tree().quit()


func _on_death_boxes_body_entered(body: Node2D) -> void:
	if(body.name == "SpacePlayer"):
		body.dying = true


func _on_down_boxes_body_entered(body: Node2D) -> void:
	if(body.name == "SpacePlayer"):
		grav_handler.setGravDirection("DOWN")


func _on_up_boxes_body_entered(body: Node2D) -> void:
	if(body.name == "SpacePlayer"):
		grav_handler.setGravDirection("UP")


func _on_left_boxes_body_entered(body: Node2D) -> void:
	if(body.name == "SpacePlayer"):
		grav_handler.setGravDirection("LEFT")


func _on_right_boxes_body_entered(body: Node2D) -> void:
	if(body.name == "SpacePlayer"):
		grav_handler.setGravDirection("RIGHT")
