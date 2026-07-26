class_name Enemy extends CharacterBody2D

@export var speed = 300
@export var hitpoints: int = 2

@onready var agent = $NavigationAgent2D
@onready var peasant = $"../Peasant"

func _ready():
	agent.path_desired_distance = 4.0
	agent.target_desired_distance = 8.0
	

func _physics_process(_delta):
	if hitpoints <= 0:
		die()
	
	agent.target_position = peasant.global_position
	var next_point = agent.get_next_path_position()
	var direction = (next_point - global_position).normalized()
	var intended_velocity = direction * speed
	agent.set_velocity(intended_velocity)
	#velocity = direction * speed
	rotation = velocity.angle() + PI / 2
	#move_and_slide()

func take_damage(damage, _damageType):
	hitpoints = hitpoints - damage

func die():
	queue_free()

func _on_navigation_agent_2d_velocity_computed(safe_velocity):
	velocity = safe_velocity
	move_and_slide()
