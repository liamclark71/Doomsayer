extends Control

@onready var resume_button = $Box/MarginContainer/VBoBox/MarginContainer/VBoxContainer/MarginContainer2/ResumeButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_resume_button_pressed():
	get_tree().paused = false
	visible = false
