extends Projectile

func _ready():
	damage = 2
	damageType = 'arrow'
	$CollisionAudioController.pitch_scale  = randf_range(0.8, 1.2)
