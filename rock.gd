extends Projectile

func _ready():
	damage = 1
	damageType = 'rock'
	$CollisionAudioController.pitch_scale  = randf_range(0.8, 1.2)
