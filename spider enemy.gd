extends CharacterBody2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var speed = 50
var current_speed: int

@onready var left_ray = $LeftRayCast
@onready var right_ray = $RightRayCast

func _physics_process(delta):
	if not left_ray.is_colliding():
		current_speed = speed

	if not right_ray.is_colliding():
		current_speed = -speed
	
	velocity.x = current_speed
	
	if not is_on_floor() or is_on_wall() or is_on_ceiling():
		velocity.y += gravity * delta

	move_and_slide()
