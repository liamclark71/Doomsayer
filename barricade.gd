extends StaticBody2D

@export var hitpoints := 12
@export var boarded_up := false

@onready var collision_shape = $CollisionShape2D

var targetable := true
var glass_intact := true
var walls_layer: TileMapLayer
var cell
var current_source_id
var window_atlas_coords
var max_hitpoints := 36

var nearby_goblins := {}

@onready var barricade_broken_sound = preload("res://sound_assets/barricade_destroyed.wav")
var barricade_damage_sound_controller


func _ready():
	barricade_damage_sound_controller = $BoardDamageAudioController.stream
	max_hitpoints = hitpoints
	walls_layer = get_tree().get_first_node_in_group("walls")
	if walls_layer:
		cell = walls_layer.local_to_map(walls_layer.to_local(global_position))
		current_source_id = walls_layer.get_cell_source_id(cell)
		window_atlas_coords = walls_layer.get_cell_atlas_coords(cell)
		if boarded_up:
			_set_cell_rotated(Vector2i(-5, 1))


func get_global_rect() -> Rect2:
	var extents = collision_shape.shape.extents
	return Rect2(global_position - extents, extents * 2)


func set_boarded_up(value: bool):
	boarded_up = value
	if walls_layer:
		if boarded_up:
			_set_cell_rotated(Vector2i(-5, 1))
		else:
			walls_layer.set_cell(cell, current_source_id, window_atlas_coords)


func needs_repair() -> bool:
	return hitpoints < max_hitpoints


func can_repair() -> bool:
	return needs_repair() and nearby_goblins.is_empty()


func handle_board_damage_audio():
	if hitpoints <= 1:
		$BoardDamageAudioController.stream = barricade_broken_sound
		$BoardDamageAudioController.pitch_scale = randf_range(0.7, 1.3)
	else:
		$BoardDamageAudioController.stream = barricade_damage_sound_controller
	$BoardDamageAudioController.play()
	

func take_damage(dam, _damage_type):
	if glass_intact:
		break_glass()
		glass_intact = false
		if not boarded_up:
			break_barricade()
	else:
		handle_board_damage_audio()
		hitpoints -= dam
		if hitpoints <= 0:
			break_barricade()
		else:
			_set_cell_rotated(Vector2i(-1, 3))


func break_barricade():
	set_collision_layer_value(1, false)
	targetable = false
	_set_cell_rotated(Vector2i(-1, 1))

func handle_board_repair_audio():
	if hitpoints < max_hitpoints:
		$FixAudioController.play()

func repair_barricade():
	handle_board_repair_audio()
	if boarded_up:
		hitpoints = max_hitpoints
		_set_cell_rotated(Vector2i(-5, 3))
		targetable = true
		_enable_collision_when_clear()


func _enable_collision_when_clear():
	if _is_body_overlapping():
		await get_tree().create_timer(0.1).timeout
		_enable_collision_when_clear()
	else:
		set_collision_layer_value(1, true)


func _is_body_overlapping() -> bool:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	query.shape = collision_shape.shape
	query.transform = collision_shape.global_transform
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var results = space_state.intersect_shape(query)
	
	for r in results:
		if r.collider.is_in_group("characters"):
			return true
	return false


func break_glass_audio():
	$GlassShatterAudioController.pitch_scale = randf_range(0.8, 1.2)
	$GlassShatterAudioController.play()
	
	
func break_glass():
	break_glass_audio()
	if boarded_up:
		_set_cell_rotated(Vector2i(-5, 3))
	else:
		_set_cell_rotated(Vector2i(-1, 1))


func _on_goblin_detector_body_entered(body):
	if body.is_in_group("goblin"):
		nearby_goblins[body] = true


func _on_goblin_detector_body_exited(body):
	if body.is_in_group("goblin"):
		nearby_goblins.erase(body)

func _set_cell_rotated(cell_coords):
	var flip_h = TileSetAtlasSource.TRANSFORM_FLIP_H
	var flip_v = TileSetAtlasSource.TRANSFORM_FLIP_H
	var transpose = TileSetAtlasSource.TRANSFORM_TRANSPOSE
	var tile_alternate
	if self.rotation_degrees == 0.0:
		tile_alternate = 0
		walls_layer.set_cell(cell, current_source_id, window_atlas_coords + cell_coords, tile_alternate)
	elif self.rotation_degrees == 90.0:
		tile_alternate = transpose | flip_h
		walls_layer.set_cell(cell, current_source_id, window_atlas_coords + cell_coords, tile_alternate)
	elif self.rotation_degrees == 180.0:
		tile_alternate = flip_h | flip_v
		walls_layer.set_cell(cell, current_source_id, window_atlas_coords + cell_coords, tile_alternate)
	elif self.rotation_degrees == 270.0:
		tile_alternate = transpose | flip_v
		walls_layer.set_cell(cell, current_source_id, window_atlas_coords + cell_coords, tile_alternate)
