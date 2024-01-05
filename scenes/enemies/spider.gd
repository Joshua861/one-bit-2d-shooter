extends CharacterBody2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var speed = 30
var running_speed = 50
var current_speed: int

@onready var left_ray_cast = $LeftRayCast
@onready var left_ray_cast_down = $LeftRayCastDown
@onready var right_ray_cast_down = $RightRayCastDown
@onready var right_ray_cast = $RightRayCast
func _physics_process(delta):
	if not left_ray_cast_down.is_colliding():
		current_speed = speed
	if not right_ray_cast_down.is_colliding():
		current_speed = -speed
	
	velocity.x = current_speed
	
	if not is_on_floor() or is_on_wall() or is_on_ceiling():
		velocity.y += gravity * delta

	move_and_slide()
