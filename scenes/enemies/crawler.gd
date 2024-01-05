extends CharacterBody2D


const SPEED = 100.0

var astar = AStar2D.new()
@onready var player = $"../Player"
var current_path = []
var target_index = 0

func _physics_process(delta):
	if current_path.size() > 0 and position.distance_to(current_path[target_index]) < 5:
		target_index += 1
	elif current_path.size() == 0 or target_index >= current_path.size():
		astar.add_point(1, position)
		astar.add_point(2, player.position)
		astar.connect_points(1, 2)
		current_path = astar.get_point_path(1, 2)
		astar.clear()
		target_index = 0
	else:
		var direction = (current_path[target_index] - position).normalized()
		velocity = direction * SPEED
