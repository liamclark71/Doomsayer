extends StaticBody2D

@export var hitpoints = 8
@export var boarded_up = true

@onready var collision_shape = $CollisionShape2D

var targetable = true
var glass_intact = true
var walls_layer: TileMapLayer
var cell
var current_source_id
var current_atlas_coords

func _ready():
	walls_layer = get_tree().get_first_node_in_group("walls")
	if walls_layer:
		cell = walls_layer.local_to_map(walls_layer.to_local(global_position))
		current_source_id = walls_layer.get_cell_source_id(cell)
		current_atlas_coords = walls_layer.get_cell_atlas_coords(cell)
		if boarded_up:
			walls_layer.set_cell(cell, current_source_id, current_atlas_coords + Vector2i(-5, 1))


func get_global_rect() -> Rect2:
	var extents = collision_shape.shape.extents
	return Rect2(global_position - extents, extents * 2)


func take_damage(dam, damage_type):
	if glass_intact:
		break_glass()
		glass_intact = false
		if not boarded_up:
			queue_free()
	else:
		hitpoints -= dam
		if hitpoints <= 0:
			queue_free()

func break_glass():
		if boarded_up:
			walls_layer.set_cell(cell, current_source_id, current_atlas_coords + Vector2i(-5, 3))
		else:
			walls_layer.set_cell(cell, current_source_id, current_atlas_coords + Vector2i(-1, 1))
