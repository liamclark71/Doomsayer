extends Node2D

@onready var wave_announcement = $CanvasLayer/WaveAnnouncement
@onready var wave_label: Label = wave_announcement.get_node("MarginContainer/VBoxContainer/WaveLabel")
@onready var subtitle_label: Label = wave_announcement.get_node("MarginContainer/VBoxContainer/Subtitle")
@onready var goblin_counter: Control = $CanvasLayer/GoblinCounter
@onready var peasant = $Peasant

@export var goblin_scene: PackedScene

@export var countdown_duration: float = 3.0
@export var break_duration: float = 5.0

@export var base_spawn_interval: float = 2.0
@export var min_spawn_interval: float = 0.3
@export var interval_decrease_per_wave: float = 0.15

@export var base_goblins_per_wave: int = 10
@export var goblins_per_wave_increase: int = 3

# after this each wave will be from all directions
var wave_directions: Array[Array] = [["north"], ["south"], ["east"], ["north", "south"], ["south", "east"]]

var direction_messages := {
	"north": "They come from the north!",
	"south": "They come from the south!",
	"east": "They come from the east!",
}

enum State { IDLE, COUNTDOWN, WAVE_ACTIVE, WAVE_BREAK }
var state: State = State.IDLE

var spawn_points_by_direction: Dictionary = {}
var current_directions: Array = ["north"]

var spawn_timer: Timer

var wave := 0
var spawn_interval := base_spawn_interval
var game_started := false

var wave_goblins_total := 0
var goblins_spawned_this_wave := 0
var goblins_remaining := 0
var goblins_left_label

@export var has_bow = false
@export var has_dodge = false
@export var has_revive = false
@export var has_sword = false
@export var recruited_blacksmith = false
@export var recruited_carpenter = false
@export var recruited_acrobat = false
@export var recruited_doctor = false
@export var recruited_hunter = false


func _ready():
	
	has_bow = Dialogic.VAR.items.bow
	has_dodge = Dialogic.VAR.items.dodge
	has_revive = Dialogic.VAR.items.revive
	has_sword = Dialogic.VAR.items.sword
	recruited_blacksmith = Dialogic.VAR.recruitment.blacksmith_recruited
	recruited_carpenter = Dialogic.VAR.recruitment.carpenter_recruited
	recruited_acrobat = Dialogic.VAR.recruitment.acrobat_recruited
	recruited_doctor = Dialogic.VAR.recruitment.doctor_recruited
	recruited_hunter = Dialogic.VAR.recruitment.hunter_recruited
	
	assign_variables()
	
	goblins_left_label = goblin_counter.get_child(0).get_child(0)
	for dir in direction_messages.keys():
		spawn_points_by_direction[dir] = get_tree().get_nodes_in_group("spawners_%s" % dir)

	spawn_timer = Timer.new()
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)

	wave_announcement.visible = false
	subtitle_label.modulate = Color.TRANSPARENT
	goblins_left_label.visible = false


func assign_variables():
	peasant.has_bow = has_bow
	peasant.has_dodge = has_dodge
	peasant.has_revive = has_revive
	peasant.has_sword = has_sword


func _unhandled_input(event):
	if not game_started and event.is_action_pressed("start"):
		game_started = true
		_start_next_wave()


func _start_next_wave():
	wave += 1
	state = State.COUNTDOWN
	await _show_countdown()
	_begin_wave()


func _pick_wave_directions() -> Array:
	if wave - 1 < wave_directions.size():
		return wave_directions[wave - 1]
	return direction_messages.keys()


func _build_subtitle_text(dirs: Array) -> String:
	if dirs.size() == 1:
		return direction_messages.get(dirs[0], "")
	var names = []
	for d in dirs:
		names.append(d)
	if dirs.size() == 3:
		return "They come from all sides!"
	return "They come from the %s!" % " and ".join(names)


func _show_countdown() -> void:
	current_directions = _pick_wave_directions()

	wave_label.text = ""
	subtitle_label.text = _build_subtitle_text(current_directions)
	subtitle_label.modulate = Color.TRANSPARENT

	wave_announcement.visible = true
	wave_announcement.modulate = Color.TRANSPARENT
	var fade_in = get_tree().create_tween()
	fade_in.tween_property(wave_announcement, "modulate", Color(1, 1, 1, .9), 0.4)
	await fade_in.finished

	var count = int(ceil(countdown_duration))
	for i in range(count, 0, -1):
		wave_label.text = "%s" % i
		wave_label.modulate = Color.TRANSPARENT

		var number_fade = get_tree().create_tween()
		number_fade.tween_property(wave_label, "modulate", Color(1, 1, 1, .9), 0.2)
		await number_fade.finished

		await get_tree().create_timer(0.8).timeout

	wave_label.text = "Wave %s" % wave
	wave_label.modulate = Color.TRANSPARENT
	var wave_text_fade = get_tree().create_tween()
	wave_text_fade.tween_property(wave_label, "modulate", Color(1, 1, 1, .9), 0.3)
	await wave_text_fade.finished

	var subtitle_fade = get_tree().create_tween()
	subtitle_fade.tween_property(subtitle_label, "modulate", Color(1, 1, 1, .9), 0.3)
	await subtitle_fade.finished


func _begin_wave():
	state = State.WAVE_ACTIVE

	wave_goblins_total = base_goblins_per_wave + goblins_per_wave_increase * (wave - 1)
	goblins_spawned_this_wave = 0
	goblins_remaining = 0
	_update_goblins_left_label()
	goblins_left_label.visible = true

	spawn_interval = max(min_spawn_interval, base_spawn_interval - interval_decrease_per_wave * (wave - 1))
	spawn_timer.wait_time = spawn_interval
	spawn_timer.start()

	var fade_out = get_tree().create_tween()
	fade_out.tween_interval(1.8)
	fade_out.tween_property(wave_announcement, "modulate", Color.TRANSPARENT, 1.0)
	await fade_out.finished
	wave_announcement.visible = false


func _end_wave():
	state = State.WAVE_BREAK
	spawn_timer.stop()
	goblins_left_label.visible = false
	await get_tree().create_timer(break_duration).timeout
	_start_next_wave()


func _on_spawn_timer_timeout():
	if state != State.WAVE_ACTIVE:
		return
	if goblins_spawned_this_wave >= wave_goblins_total:
		spawn_timer.stop()
		return
	_spawn_goblin()


func _spawn_goblin():
	if current_directions.is_empty():
		return
	var direction = current_directions[randi() % current_directions.size()]
	var points: Array = spawn_points_by_direction.get(direction, [])
	if points.is_empty():
		return
	var point = points[randi() % points.size()]
	var goblin = goblin_scene.instantiate()
	get_tree().current_scene.add_child(goblin)
	goblin.global_position = point.global_position

	goblins_spawned_this_wave += 1
	goblins_remaining += 1
	_update_goblins_left_label()
	goblin.tree_exited.connect(_on_goblin_died)


func _on_goblin_died():
	goblins_remaining -= 1
	_update_goblins_left_label()
	if goblins_remaining <= 0 and goblins_spawned_this_wave >= wave_goblins_total and state == State.WAVE_ACTIVE:
		_end_wave()


func _update_goblins_left_label():
	goblins_left_label.text = "Goblins left: %d" % max(goblins_remaining, 0)
