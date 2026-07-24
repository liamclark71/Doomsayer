extends Enemy

@onready var legs = $Legs
@onready var torso = $Torso
@onready var anim_tree = $AnimationTree
@onready var hitbox = $Torso/HitBox/CollisionShape2D
@onready var hurtbox = $HurtBox/CollisionShape2D

@export var attack_range = 110
@export var damage = 1
@export var knockback_friction := 1500.0

var knockback_velocity := Vector2.ZERO
var in_range = false
var hitbox_array = []

func _ready():
	agent.path_desired_distance = 4.0
	agent.target_desired_distance = 80
	legs.play("stand")
	anim_tree.active = true
	

func _physics_process(_delta):
	if hitpoints <= 0:
		die()
	if velocity != Vector2(0, 0):
		legs.play("walk")
	else:
		legs.play("stand")
	
	agent.target_position = peasant.global_position
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
	
	if knockback_velocity.length() > 0:
		velocity = knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * _delta)
		move_and_slide()
		return

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
