extends Control

@onready var day_button = $Box/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/DayButton
@onready var night_button = $Box/MarginContainer/VBoxContainer/MarginContainer/HBoxContainer/NightButton


func _on_day_button_pressed():
	get_tree().change_scene_to_file("res://point_and_click.tscn")


func _on_night_button_pressed():
	get_tree().reload_current_scene()
