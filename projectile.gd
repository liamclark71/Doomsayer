class_name Projectile extends Area2D

@export var speed := 1000
var damage = 1

func _physics_process(delta):
	position += -transform.y * speed * delta

func _on_body_entered(body):
	if body is Enemy:
		body.take_damage(damage)
	queue_free()
