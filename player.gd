extends CharacterBody2D

const SPEED: float = 200
const JUMP_VELOCITY: float = -390
const MAX_AIR_JUMPS: int = 1
const AIR_JUMP_VELOCITY: float = -250
const ANIMATION_SPEED: float = 100

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var sprite = $Sprite2D
@onready var collision = $CollisionPolygon2D
@onready var air_jump_particle_parent = $Node
@onready var walk_particles = $"walk particles"
@onready var jump_sfx = $"jump sound effects"

var air_jumps: int
var animation_playing: bool = false
var was_on_floor: bool
var playing_squash = false
var air_jump_particle
var air_jump_particle_is_fading = false

func _physics_process(delta):
	if not is_on_floor():
		when_in_air(delta)

	# Handle Jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		jump()

	handle_movement(delta)
	
	sprite_flipping()
	
	if is_on_floor():
		when_on_floor(delta)
	
	if Input.is_action_just_pressed("jump") and not is_on_floor() and air_jumps > 0:
		air_jump()
	
	if not was_on_floor and is_on_floor():
		on_land()
	
	was_on_floor = is_on_floor()
	
	if playing_squash:
		play_squash(delta)
	
	if air_jump_particle_is_fading:
		air_jump_particle.modulate.a -= 0.05
		if abs(air_jump_particle.modulate.a) <= 0.001:
			air_jump_particle.free()
			air_jump_particle_is_fading = false

	move_and_slide()

func handle_movement(delta):
	# Get the input direction and handle the movement/deceleration.
	var direction = Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
		if is_on_floor():
			walk_particles.emitting = true
		else:
			walk_particles.emitting = false
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		walk_particles.emitting = false

func jump(force = JUMP_VELOCITY):
	velocity.y = JUMP_VELOCITY
	jump_sfx.stream = load("res://assets/sounds/jump.wav")
	jump_sfx.play()

func air_jump():
	air_jumps =- 1
	velocity.y = AIR_JUMP_VELOCITY
	
	air_jump_particle_parent.add_child($air_jump_particle.duplicate())
	air_jump_particle = $Node/air_jump_particle
	print(air_jump_particle_parent.get_children())
	air_jump_particle.visible = true
	air_jump_particle.position = position
	air_jump_particle_is_fading = true
	
	jump_sfx.stream = load("res://assets/sounds/air jump.wav")
	jump_sfx.play()

func when_on_floor(delta):
	# Reset wall jumps
	air_jumps = MAX_AIR_JUMPS
	
	if not playing_squash:
		var target_scale = Vector2.ONE
		sprite.scale = lerp(sprite.scale, target_scale, ANIMATION_SPEED * delta)

func when_in_air(delta):
	velocity.y += gravity * delta
	
	playing_squash = false
	var target_scale = Vector2(0.875, 1.125)
	sprite.scale = lerp(sprite.scale, target_scale, ANIMATION_SPEED * delta)

# Flip sprites depending on which way you are looking.
func sprite_flipping():
	if Input.is_action_just_pressed("left"):
		sprite.flip_h = false
	elif Input.is_action_just_pressed("right"):
		sprite.flip_h = true

func on_land():
	playing_squash = true

func play_squash(delta):
	var target_scale = Vector2(1.125, 0.875)
	sprite.scale = lerp(sprite.scale, target_scale, ANIMATION_SPEED * delta)
	
	if Vector2(snappedf(sprite.scale.x, 0.001), snappedf(sprite.scale.y, 0.001)) == target_scale:
		playing_squash = false
