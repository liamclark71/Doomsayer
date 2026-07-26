extends Control

@onready var day_button = $Box/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/DayButton
@onready var night_button = $Box/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/NightButton

var bus_index
var volume
var volume_before_visible = -1

func _ready():
	bus_index = AudioServer.get_bus_index("Sound Effects")

func _process(_delta):
	if visible:
		if volume_before_visible == -1:
			volume_before_visible = db_to_linear(AudioServer.get_bus_volume_db(bus_index))
			volume = volume_before_visible
		volume *= 0.995
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(volume))


func _on_day_button_pressed():
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(volume_before_visible))
	volume_before_visible = -1
	_reset_flags()
	get_tree().change_scene_to_file("res://point_and_click.tscn")


func _on_night_button_pressed():
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(volume_before_visible))
	volume_before_visible = -1
	get_tree().reload_current_scene()

func _reset_flags():
	Dialogic.VAR.reset()
