extends Node2D

@onready var wave_announcement = $CanvasLayer/WaveAnnouncement
@onready var wave_label: Label = wave_announcement.get_node("MarginContainer/VBoxContainer/WaveLabel")
@onready var subtitle_label: Label = wave_announcement.get_node("MarginContainer/VBoxContainer/Subtitle")
@onready var goblin_counter: Control = $CanvasLayer/GoblinCounter
@onready var peasant = $Peasant
@onready var health_bar = $CanvasLayer/HealthBar
@onready var game_over_box = $CanvasLayer/GameOverBox
@onready var pause_box = $CanvasLayer/PauseBox
@onready var blood_splatter = $CanvasLayer/BloodSplatter

@export var goblin_scene: PackedScene

@export var first_wave_countdown_duration: float = 5.0
@export var countdown_duration: float = 3.0
@export var break_duration: float = 5.0

@export var base_spawn_interval: float = 0.0001
@export var min_spawn_interval: float = 0.3
@export var interval_decrease_per_wave: float = 0.15

@export var base_goblins_per_wave: int = 10
@export var goblins_per_wave_increase: int = 3
@export var waves_total = 8

# after this each wave will be from all directions
var wave_directions: Array[Array] = [["north"],
 									["south"],
 									["east"],
 									["north", "south"],
 									["south", "east"],
 									["east"]]

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
var waves_left_label

var has_bow = false
var has_dodge = false
var has_revive = false
var has_sword = false
var recruited_blacksmith = false
var recruited_carpenter = false
var recruited_acrobat = false
var recruited_doctor = false
var recruited_hunter = false

var goblins_killed = 0




func _ready():
	# This must be commented out!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	#_apply_debug_overrides()
	
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
	cull_unwanted()
	
	health_bar.update_health(peasant.hitpoints, peasant.max_hitpoints)
	peasant.hitpoints_changed.connect(health_bar.update_health)
	peasant.player_defeated.connect(_on_player_defeated)
	peasant.hitpoints_changed.connect(_blood_splatter_animation)
	
	goblins_left_label = goblin_counter.get_child(0).get_child(0)
	waves_left_label = goblin_counter.get_child(0).get_child(1)
	
	for dir in direction_messages.keys():
		spawn_points_by_direction[dir] = get_tree().get_nodes_in_group("spawners_%s" % dir)

	spawn_timer = Timer.new()
	spawn_timer.one_shot = false
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)

	wave_announcement.visible = false
	subtitle_label.modulate = Color.TRANSPARENT
	goblins_left_label.visible = false
	waves_left_label.visible = false
	game_started = true
	_start_next_wave()
	
	blood_splatter.modulate = Color.TRANSPARENT
	
func _blood_splatter_animation(_a, _b):
	if _a < _b:
		var tween = get_tree().create_tween()
		tween.tween_property(blood_splatter, "modulate", Color.WHITE, 0.1)
		tween.tween_property(blood_splatter, "modulate", Color.TRANSPARENT, 0.2)


func _on_player_defeated():
	var vbox = peasant.game_over_menu.get_node("Box/MarginContainer/VBoxContainer")
	var title_label = vbox.get_child(0)
	var goblin_label = vbox.get_child(1)
	
	title_label.text = "Game Over"
	goblin_label.text = "Goblins Killed: %d" % goblins_killed


func assign_variables():
	peasant.has_bow = has_bow
	peasant.has_dodge = has_dodge
	peasant.has_revive = has_revive
	peasant.has_sword = has_sword


func _apply_debug_overrides():
	Dialogic.VAR.items.bow = true
	Dialogic.VAR.items.dodge = true
	Dialogic.VAR.items.revive = true
	Dialogic.VAR.items.sword = true
	Dialogic.VAR.recruitment.blacksmith_recruited = true
	Dialogic.VAR.recruitment.carpenter_recruited = true
	Dialogic.VAR.recruitment.acrobat_recruited = true
	Dialogic.VAR.recruitment.doctor_recruited = true
	Dialogic.VAR.recruitment.hunter_recruited = true


func cull_unwanted():
	if !recruited_blacksmith:
		$Blacksmith.queue_free()
	if !recruited_carpenter:
		$Carpenter.queue_free()
	else:
		for barricade in get_tree().get_nodes_in_group("barricades"):
			barricade.set_boarded_up(true)
	if !recruited_acrobat:
		$Acrobat.queue_free()
	if !recruited_doctor:
		$Doctor.queue_free()
	if !recruited_hunter:
		$Hunter.queue_free()



func _unhandled_input(event):
	if not game_started and event.is_action_pressed("start"):
		game_started = true
		_start_next_wave()


func _start_next_wave():
	if wave > waves_total:
		_trigger_victory()
		return
	
	wave += 1
	state = State.COUNTDOWN
	await _show_countdown()
	if not $AudioStreamPlayer.playing:
		$AudioStreamPlayer.play()
	waves_left_label.visible = true
	_begin_wave()


func _trigger_victory():
	state = State.IDLE
	spawn_timer.stop()
	
	if game_over_box:
		var vbox = game_over_box.get_node("Box/MarginContainer/VBoxContainer")
		var title_label = vbox.get_child(0)
		var goblin_label = vbox.get_child(1)
		
		title_label.text = "Victory"
		goblin_label.text = "Goblins Killed: %d" % goblins_killed
		
		game_over_box.modulate = Color.TRANSPARENT
		game_over_box.visible = true
		var tween = get_tree().create_tween()
		tween.tween_interval(1.0)
		tween.tween_property(game_over_box, "modulate", Color(1, 1, 1, .9), 1)


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

	var this_countdown = first_wave_countdown_duration if wave == 1 else countdown_duration
	var count = int(ceil(this_countdown))
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
	goblins_remaining = wave_goblins_total
	_update_goblins_left_label()
	_update_waves_left_label()
	
	goblins_left_label.visible = true
	waves_left_label.visible = true

	spawn_interval = max(min_spawn_interval, base_spawn_interval - interval_decrease_per_wave * (wave - 1))
	spawn_timer.wait_time = spawn_interval
	spawn_timer.start()

	var fade_out = get_tree().create_tween()
	fade_out.tween_interval(1.8)
	fade_out.tween_property(wave_announcement, "modulate", Color.TRANSPARENT, 1.0)
	await fade_out.finished
	wave_announcement.visible = false


func _end_wave():
	peasant.heal_to_full()
	wave_label.text = "Wave Finished"
	subtitle_label.text = ""
	wave_announcement.visible = true 
	wave_announcement.modulate = Color.TRANSPARENT
	var wave_text_fade = get_tree().create_tween()
	wave_text_fade.tween_property(wave_announcement, "modulate", Color(1, 1, 1, .9), 0.3)
	wave_text_fade.tween_interval(1)
	wave_text_fade.tween_property(wave_announcement, "modulate", Color.TRANSPARENT, 0.3)
	state = State.WAVE_BREAK
	spawn_timer.stop()
	goblins_left_label.visible = false
	_update_waves_left_label()
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
	goblin.goblin_died.connect(_on_goblin_died)


func _on_goblin_died():
	goblins_killed += 1
	goblins_remaining -= 1
	_update_goblins_left_label()
	if goblins_remaining <= 0 and goblins_spawned_this_wave >= wave_goblins_total and state == State.WAVE_ACTIVE:
		_end_wave()


func _update_goblins_left_label():
	goblins_left_label.text = "Goblins left: %d" % max(goblins_remaining, 0)

func _update_waves_left_label():
	waves_left_label.text = "Waves Left: %d" % min(waves_total - wave + 1, 8)
