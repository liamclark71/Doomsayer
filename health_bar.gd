extends Control


@onready var fill: Panel = $MarginContainer/Background/Fill
@onready var background: Panel = $MarginContainer/Background

var full_width: float


func _ready():
	full_width = background.size.x-12


func update_health(current: int, max_hp: int):
	var pct = clamp(float(current) / float(max_hp), 0.0, 1.0)
	var tween = create_tween()
	tween.tween_property(fill, "size:x", full_width * pct, 0.2)
