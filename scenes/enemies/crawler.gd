extends Node2D

const SPEED = 1

@onready var player = $"../Player"
@onready var tilemap = $"../TileMap"
@onready var sprite_2d = $Sprite2D

var astar: AStarGrid2D

var start_cell: Vector2i
var end_cell: Vector2i

var current_id_path
var is_moving: bool
var target_position

var offset = Vector2i(16, 9)

func init_astar() -> void:
	astar = AStarGrid2D.new()
	astar.region = tilemap.get_used_rect()
	astar.cell_size = tilemap.tile_set.tile_size
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.update()
	
	var region_size = astar.region.size
	var region_position = astar.region.position
	
	for x in range(astar.size.x):
		for y in range(astar.size.x):
			var id = Vector2i(
				x + region_position.x,
				y + region_position.x)
			
			var tile_data = tilemap.get_cell_tile_data(0, id)
			
			if tile_data != null:
				astar.set_point_solid(id)
		

func _ready():
	init_astar()

func _process(_delta):
	var id_path
	
	if is_moving:
		return
	
	move()

func move():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var occupied_positions = []
	
	for enemy in enemies:
		if enemy == self:
			continue
		
		occupied_positions.append(tilemap.local_to_map(enemy.global_position))
	
	for pos in occupied_positions:
		astar.set_point_solid(pos, true)
	
	var path = astar.get_id_path(
		tilemap.local_to_map(global_position),
		tilemap.local_to_map(player.global_position)
	)
	
	path.pop_front()
	
	if path.is_empty():
		print(self.name, ": cant find path")
		return
	
	var original_position = Vector2(global_position)
	global_position = tilemap.map_to_local(path[0])
	sprite_2d.global_position = original_position
	
	if sprite_2d.global_position.x > global_position.x:
		sprite_2d.rotation = (PI / 2)
	elif sprite_2d.global_position.x < global_position.x:
		sprite_2d.rotation = -(PI / 2)
	elif sprite_2d.global_position.y < global_position.y:
		sprite_2d.rotation = 0
	else:
		sprite_2d.rotation = PI
	
	is_moving = true
	
	for pos in occupied_positions:
		astar.set_point_solid(pos, false)

func _physics_process(delta):
	if is_moving:
		sprite_2d.global_position = sprite_2d.global_position.move_toward(global_position, 1)
		
		if sprite_2d.global_position != global_position:
			return
		
		is_moving = false
