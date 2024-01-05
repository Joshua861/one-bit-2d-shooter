extends CharacterBody2D

const SPEED: float = 200
const JUMP_VELOCITY: float = -390
const MAX_AIR_JUMPS: int = 1
const AIR_JUMP_VELOCITY: float = -250
const ANIMATION_SPEED: float = 100
const GUN_DISTANCE: float = 15

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var sprite = $Sprite2D
@onready var collision = $CollisionPolygon2D
@onready var air_jump_particle_parent = $Node
@onready var walk_particles = $"walk particles"
@onready var jump_sfx = $"jump sound effects"
@onready var footstep_sfx = $"footstep sound player"
@onready var footsteps_timer = $"footsteps timer"
@onready var land_particles = $"land particles"

var air_jumps: int
var animation_playing: bool = false
var was_on_floor: bool
var playing_squash = false
var air_jump_particle
var air_jump_particle_is_fading = false
var walking = false
var hit_enemy_timer = 5
var hit_enemy = true
var hit_enemy_this_frame

signal shoot

func _ready():
	footsteps_timer.timeout.connect(footsteps)

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
	
	if hit_enemy:
		hit_enemy_timer -= 1
		
		if hit_enemy_timer == 0:
			game_over()

	move_and_slide()
	
	if Input.is_action_just_pressed("shoot"):
		shoot.emit()
	
	var collisions = get_slide_collision_count()
	for i in range(collisions):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		
		if collider.is_in_group("enemies"):
			hit_enemy_this_frame = true
	
	hit_enemy = hit_enemy_this_frame
	hit_enemy_this_frame = false

func _process(delta):
	gun_movement()

func handle_movement(delta):
	# Get the input direction and handle the movement/deceleration.
	var direction = Input.get_axis("left", "right")
	if direction:
		velocity.x = direction * SPEED
		if is_on_floor():
			walk_particles.emitting = true
			walking = true
		else:
			walk_particles.emitting = false
			walking = false
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		walk_particles.emitting = false
		walking = false

func jump(force = JUMP_VELOCITY):
	velocity.y = JUMP_VELOCITY
	jump_sfx.stream = load("res://assets/sounds/jump.wav")
	jump_sfx.play()

func air_jump():
	air_jumps =- 1
	velocity.y = AIR_JUMP_VELOCITY
	
	air_jump_particle_parent.add_child($air_jump_particle.duplicate())
	air_jump_particle = $Node/air_jump_particle
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
	land_particles.restart()

func play_squash(delta):
	var target_scale = Vector2(1.125, 0.875)
	sprite.scale = lerp(sprite.scale, target_scale, ANIMATION_SPEED * delta)
	
	if Vector2(snappedf(sprite.scale.x, 0.001), snappedf(sprite.scale.y, 0.001)) == target_scale:
		playing_squash = false

func play_sound(path, player):
	var sound = load(path)
	player.stream = sound
	player.play()

func play_sound_from_folder(path, player):
	var dir = DirAccess.open(path)
	if dir:
		var files = dir.get_files()
		var file = 'import'
		while file.contains("import"):
			file = files[randi() % files.size()]
		play_sound(path + "/" + file, player)

func footsteps():
	if walking:
		play_sound_from_folder("res://assets/sounds/footsteps/", footstep_sfx)

func game_over():
	get_tree().reload_current_scene()

func gun_movement():
	var mouse_pos = get_global_mouse_position()
	var dir = (mouse_pos - global_position).normalized()
	var gun_pos = dir * GUN_DISTANCE
	
	$"Bouncy gun".position = gun_pos
	$"Bouncy gun".look_at(mouse_pos)
	
	if mouse_pos.x < global_position.x:
		$"Bouncy gun/Sprite2D".set_flip_v(true)
	else:
		$"Bouncy gun/Sprite2D".set_flip_v(false)
