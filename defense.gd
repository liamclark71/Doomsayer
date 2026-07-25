extends Node2D

@onready var wave_announcement = $CanvasLayer/WaveAnnouncement

@export var goblin_scene: PackedScene
@export var min_spawn_interval: float = 0.5
@export var spawn_interval: float = 0.01
@export var interval_decrease_rate: float = 0.03  # per second

var spawn_points: Array[Node2D] = []
var spawn_timer: Timer
var elapsed_time: float = 0.0
var wave = 1


func _ready():
	spawn_points.assign(get_tree().get_nodes_in_group("spawners"))
	spawn_timer = Timer.new()
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	spawn_timer.start()
	wave_begin()


func _physics_process(delta):
	elapsed_time += delta
	_ramp_difficulty(delta)


func _ramp_difficulty(delta):
	spawn_interval = max(min_spawn_interval, spawn_interval - interval_decrease_rate * delta)
	spawn_timer.wait_time = spawn_interval


func _on_spawn_timer_timeout():
	if spawn_points.size() > 0:
		_spawn_goblin()

func _spawn_goblin():
	var point = spawn_points[randi() % spawn_points.size()]
	var goblin = goblin_scene.instantiate()
	get_tree().current_scene.add_child(goblin)
	goblin.global_position = point.global_position

func wave_begin():
	wave_announcement.get_child(0).get_child(0).text = "Wave %s" % wave
	wave_announcement.visible = true
	wave_announcement.modulate = Color.TRANSPARENT
	var tween = get_tree().create_tween()
	tween.tween_property(wave_announcement, "modulate", Color(1,1,1,.9), 1)
	tween.tween_interval(2.0)
	tween.tween_property(wave_announcement, "modulate", Color.TRANSPARENT, 1)
	
