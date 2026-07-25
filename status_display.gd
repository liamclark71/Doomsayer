extends Control


@onready var Hours_label = $MarginContainer/BoxContainer/Hours_label
@onready var Gold_label = $MarginContainer/BoxContainer/Gold_label


func _process(delta: float) -> void:
	Hours_label.text = "Hours: " + str(Dialogic.VAR.hours)
	Gold_label.text = "Gold: " + str(Dialogic.VAR.gold)
