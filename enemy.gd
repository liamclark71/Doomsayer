class_name Enemy extends CharacterBody2D

@export var speed = 400
@export var hitpoints = 2

func _physics_process(_delta):
	if hitpoints <= 0:
		die()

func take_damage(damage):
	hitpoints = hitpoints - damage

func die():
	queue_free()
