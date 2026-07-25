extends StaticBody2D

@export var hitpoints = 8
@export var boarded_up = true

@onready var collision_shape = $CollisionShape2D

var targetable = true
var glass_intact = true
var walls_layer: TileMapLayer
var cell
var current_source_id
var window_atlas_coords
var max_hitpoints = 8

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
			walls_layer.set_cell(cell, current_source_id, window_atlas_coords + Vector2i(-5, 1))


func get_global_rect() -> Rect2:
	var extents = collision_shape.shape.extents
	return Rect2(global_position - extents, extents * 2)

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

func break_barricade():
	set_collision_layer_value(1, false)
	targetable = false
	walls_layer.set_cell(cell, current_source_id, window_atlas_coords + Vector2i(-1, 1))

func repair_barricade():
	if boarded_up:
		set_collision_layer_value(1, true)
		hitpoints = max_hitpoints
		walls_layer.set_cell(cell, current_source_id, window_atlas_coords + Vector2i(-5, 3))
		targetable = true

func break_glass_audio():
	$GlassShatterAudioController.pitch_scale = randf_range(0.8, 1.2)
	$GlassShatterAudioController.play()
	
func break_glass():
	break_glass_audio()
	if boarded_up:
		walls_layer.set_cell(cell, current_source_id, window_atlas_coords + Vector2i(-5, 3))
	else:
		walls_layer.set_cell(cell, current_source_id, window_atlas_coords + Vector2i(-1, 1))
