class_name Projectile extends Area2D

@export var speed := 1000
var damage = 1
var damageType


func _physics_process(delta):
	position += -transform.y * speed * delta

func _on_body_entered(body):
	$CollisionAudioController.play()

	if not body.get_collision_mask_value(4):
		body.take_damage(damage, damageType)
		
	visible = false
	$CollisionShape2D.queue_free()
	$RockSprite.queue_free()
	
	await get_tree().create_timer(4.0).timeout

	queue_free()

func _on_area_entered(area):
	$CollisionAudioController.play()

	if area.get_parent() is Enemy:
		area.get_parent().take_damage(damage, damageType)
		area.get_parent().apply_knockback(global_position, 400)
		
	visible = false
	$CollisionShape2D.queue_free()
	$RockSprite.queue_free()
	
	await get_tree().create_timer(4.0).timeout
	queue_free()
