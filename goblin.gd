extends Enemy

@onready var legs = $Legs
@onready var torso = $Torso
@onready var anim_tree = $AnimationTree
@onready var hitbox = $Torso/HitBox/CollisionShape2D
@onready var hurtbox = $HurtBox/CollisionShape2D
@onready var path_timer = $PathTimer

@export var attack_range = 110
@export var damage = 1
@export var knockback_friction := 1500.0

var knockback_velocity := Vector2.ZERO
var in_range = false
var hitbox_array = []
var target


func _ready():
	agent.path_desired_distance = 4.0
	agent.target_desired_distance = 80
	legs.play("stand")
	anim_tree.active = true
	
	target = get_closest_character()
	if target:
		agent.target_position = target.global_position


func _physics_process(_delta):
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


func get_closest_character() -> Node2D:
	var candidates = get_tree().get_nodes_in_group("characters")
	if candidates.is_empty():
		return null

	candidates.sort_custom(func(a, b):
		return global_position.distance_squared_to(a.global_position) \
			< global_position.distance_squared_to(b.global_position)
	)

	var closest: Node2D = null
	var shortest_path := INF
	var map = agent.get_navigation_map()

	for character in candidates.slice(0, 3):
		var path = NavigationServer2D.map_get_path(map, global_position, character.global_position, true)
		var length := 0.0
		for i in range(path.size() - 1):
			length += path[i].distance_to(path[i + 1])
		if length < shortest_path:
			shortest_path = length
			closest = character

	return closest


func apply_knockback(from_position: Vector2, strength: float):
	knockback_velocity = (global_position - from_position).normalized() * strength


func hit():
	for body in hitbox_array:
		body.take_damage(damage)


func take_damage(dam):
	hitpoints = hitpoints - dam


func die():
	queue_free()


func _on_navigation_agent_2d_velocity_computed(safe_velocity):
	velocity = safe_velocity
	move_and_slide()


func _on_hit_box_body_entered(body):
	if body.get_collision_mask_value(2) or body.get_collision_mask_value(3): # if player or NPC
		hitbox_array.append(body)


func _on_hit_box_body_exited(body):
	hitbox_array.erase(body)


func _on_path_timer_timeout():
	target = get_closest_character()
