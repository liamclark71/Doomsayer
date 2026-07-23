extends Projectile

func _ready():
	damage = 2

func _on_body_entered(body):
	if body is Enemy:
		body.take_damage(damage)
	queue_free()
