extends CharacterBody2D

@export var speed = 400
@export var has_bow = false
@export var has_sword = false
@export var arrow_scene: PackedScene
@export var rock_scene: PackedScene

@onready var legs = $Legs
@onready var torso = $Torso
@onready var anim_tree = $AnimationTree
@onready var proj_spawn = $Torso/ProjectileSpawn

var damage = 1
var drawing = false
var swinging = false
var hitbox_array: Array[Enemy] = []

func _ready():
	legs.play("stand")
	anim_tree.active = true
	if has_sword:
		damage = 2
	z_index = 1

func _physics_process(_delta):
	get_input()
	if velocity != Vector2(0, 0):
		legs.play("walk")
	else:
		legs.play("stand")
	legs.rotation = velocity.angle() - PI / 2
	torso.look_at(get_global_mouse_position())
	torso.rotation += deg_to_rad(90)
	
	move_and_slide()

func get_input():
	var input_direction = Input.get_vector("left", "right", "up", "down")
	velocity = input_direction * speed
	if Input.is_action_pressed("draw"):
		drawing = true
	else:
		drawing = false
	if Input.is_action_pressed("swing"):
		swinging = true
	else:
		swinging = false

func _hit_enemies():
	for enemy in hitbox_array:
		enemy.take_damage(damage)

func _shoot_projectile():
	if has_bow:
		var arrow = arrow_scene.instantiate()
		get_parent().add_child(arrow)
		
		arrow.global_position = proj_spawn.global_position
		arrow.global_rotation = torso.global_rotation
	else:
		var rock = rock_scene.instantiate()
		get_parent().add_child(rock)
		
		rock.global_position = proj_spawn.global_position
		rock.global_rotation = torso.global_rotation

func _on_hit_box_area_body_entered(body):
	if body is Enemy:
		hitbox_array.append(body)


func _on_hit_box_area_body_exited(body):
	if body is Enemy:
		hitbox_array.erase(body)
