class_name Projectile extends Area2D

@export var speed := 1000
var damage = 1

func _physics_process(delta):
	position += -transform.y * speed * delta

func _on_body_entered(_body):
	queue_free()

func _on_area_entered(area):
	if area.get_parent() is Enemy:
		area.get_parent().take_damage(damage)
		area.get_parent().apply_knockback(global_position, 400)
	queue_free()
