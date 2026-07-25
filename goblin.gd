extends Enemy

@onready var legs = $Legs
@onready var torso = $Torso
@onready var anim_tree = $AnimationTree
@onready var anim_player = $AnimationPlayer
@onready var hitbox = $Torso/HitBox/CollisionShape2D
@onready var hurtbox = $HurtBox/CollisionShape2D
@onready var path_timer = $PathTimer

@export var attack_range = 110
@export var damage = 1
@export var knockback_friction := 1500.0
@onready var corpse_thud_sounds: Array[AudioStream] = [
	load("res://sound_assets/corpse_thud1.wav"),
	load("res://sound_assets/corpse_thud2.wav"),
]

var knockback_velocity := Vector2.ZERO
var in_range = false
var hitbox_array = []
var target
var alive = true


func _ready():
	agent.path_desired_distance = 4.0
	agent.target_desired_distance = 80
	legs.play("stand")
	anim_tree.active = true
	
	target = get_closest_character()
	if target:
		agent.target_position = target.global_position

func randomize_audio():
	$SpearAudioController.pitch_scale = randf_range(0.8, 1.2)

func _physics_process(_delta):
	if alive:
		if hitpoints <= 0:
			die()
		
		if knockback_velocity.length() > 0:
			velocity = knockback_velocity
			knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * _delta)
			move_and_slide()
			return
		
		if velocity != Vector2(0, 0):
			legs.play("walk")
		else:
			legs.play("stand")
		
		if target:
			agent.target_position = target.global_position
		
		var next_point = agent.get_next_path_position()
		var direction = (next_point - global_position).normalized()
		var intended_velocity = direction * speed
		agent.set_velocity(intended_velocity)
		legs.rotation = velocity.angle() + PI / 2
		
		torso.look_at(agent.target_position)
		torso.rotation += deg_to_rad(90)
		
		if agent.get_path_length() <= attack_range and agent.distance_to_target() <= attack_range:
			in_range = true
		else:
			in_range = false
	else:
		# dead, but stick knockback
		if knockback_velocity.length() > 0:
			velocity = knockback_velocity
			knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * _delta)
			move_and_slide()



func get_closest_character() -> Node2D:
	var candidates = []
	
	for character in get_tree().get_nodes_in_group("characters"):
		if character.targetable:
			candidates.append(character)
	if candidates.is_empty():
		return null

	candidates.sort_custom(func(a, b):
		return global_position.distance_squared_to(a.global_position) \
			< global_position.distance_squared_to(b.global_position)
	)

	var barricades = get_tree().get_nodes_in_group("barricades")
	var closest: Node2D = null
	var shortest_path := INF
	var map = agent.get_navigation_map()
	var chosen_path: PackedVector2Array = []

	for character in candidates.slice(0, 3):
		var path = NavigationServer2D.map_get_path(map, global_position, character.global_position, true)
		var length := 0.0
		for i in range(path.size() - 1):
			length += path[i].distance_to(path[i + 1])
		if length < shortest_path:
			shortest_path = length
			closest = character
			chosen_path = path
	
	if closest == null:
		return null
	
	for barricade in barricades:
		var rect = barricade.get_global_rect()
		for i in range(chosen_path.size() - 1):
			if _segment_intersects_rect(chosen_path[i], chosen_path[i + 1], rect):
				return barricade
	
	return closest


func apply_knockback(from_position: Vector2, strength: float):
	knockback_velocity = (global_position - from_position).normalized() * strength


func hit():
	for body in hitbox_array:
		body.take_damage(damage, 'test')


func take_damage(dam, damageType):
	hitpoints = hitpoints - dam
	var tween = get_tree().create_tween()
	tween.tween_property($Torso, "modulate", Color(1.0, 0.35, 0.35), 0.1)
	tween.tween_property($Torso, "modulate", Color.WHITE, 0.1)

func play_death_sound():
	$DeathAudioController.stream = corpse_thud_sounds.pick_random()
	$DeathAudioController.play()

func die():
	alive = false
	anim_tree.active = false
	legs.visible = false
	play_death_sound()
	hurtbox.disabled = true
	set_collision_layer_value(4, false)
	set_collision_mask_value(2, false)
	set_collision_mask_value(3, false)
	agent.avoidance_enabled = false
	
	anim_player.play("die")
	var tween = get_tree().create_tween()
	tween.tween_interval(2.0)
	tween.tween_property($Torso, "modulate", Color.TRANSPARENT, .8)
	tween.tween_callback(queue_free)


func _segment_intersects_rect(p1: Vector2, p2: Vector2, rect: Rect2) -> bool:
	if rect.has_point(p1) or rect.has_point(p2):
		return true
	var corners = [
		rect.position,
		rect.position + Vector2(rect.size.x, 0),
		rect.position + rect.size,
		rect.position + Vector2(0, rect.size.y)
	]
	for i in range(4):
		var edge_start = corners[i]
		var edge_end = corners[(i + 1) % 4]
		if Geometry2D.segment_intersects_segment(p1, p2, edge_start, edge_end):
			return true
	return false


func _on_navigation_agent_2d_velocity_computed(safe_velocity):
	if not alive:
		return
	velocity = safe_velocity
	move_and_slide()


func _on_hit_box_body_entered(body):
	if body.is_in_group("characters") or body.is_in_group("barricades"):
		hitbox_array.append(body)


func _on_hit_box_body_exited(body):
	hitbox_array.erase(body)


func _on_path_timer_timeout():
	target = get_closest_character()
