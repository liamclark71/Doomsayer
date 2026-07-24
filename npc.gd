extends Character

@onready var death_timer = $DeathTimer
@onready var swinging_duration_timer = $SwingingDurationTimer

func _ready():
	legs.play("stand")
	anim_tree.active = true
	if has_sword:
		damage = 2
	z_index = 1
	hitbox.disabled = true

func _physics_process(_delta):
	if alive:
		if velocity != Vector2(0, 0):
			legs.play("walk")
		else:
			legs.play("stand")
		legs.rotation = velocity.angle() + PI / 2
		
		var target = get_nearest_visible_goblin()
		if target:
			torso.look_at(target.global_position)
			torso.rotation += PI / 2
			if global_position.distance_to(target.global_position) <= 130:
				if swing_on_cooldown == false:
					drawing = false
					swinging = true
					swing_on_cooldown = true
					swing_timer.start()
					swinging_duration_timer.start()
			elif drawing == false:
				drawing = true
				shoot_timer.start()


func get_input():
	pass

func get_nearest_visible_goblin() -> Enemy:
	var nearest: Enemy = null
	var nearest_dist := INF
	
	var space_state = get_world_2d().direct_space_state
	for goblin in get_tree().get_nodes_in_group("goblin"):
		var query = PhysicsRayQueryParameters2D.create(
			global_position,
			goblin.global_position
		)
		query.exclude = [self]
		query.collision_mask = 1
		
		var result = space_state.intersect_ray(query)
		
		if result.is_empty():
			var dist = global_position.distance_squared_to(goblin.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = goblin
	
	return nearest

func game_over():
	anim_tree.active = false
	anim_player.play("die")
	legs.visible = false
	z_index = -1
	alive = false
	death_timer.start()

func _on_shoot_timer_timeout():
	drawing = false


func _on_swing_timer_timeout():
	swing_on_cooldown = false


func _on_swinging_duration_timer_timeout():
	swinging = false


func _on_death_timer_timeout():
	targetable = false
