class_name Character extends CharacterBody2D

@export var speed = 400
@export var has_bow = false
@export var has_sword = false
@export var arrow_scene: PackedScene
@export var rock_scene: PackedScene
@export var hitpoints = 5

@onready var legs = $Legs
@onready var torso = $Torso
@onready var anim_tree = $AnimationTree
@onready var proj_spawn = $Torso/ProjectileSpawn
@onready var hitbox = $Torso/HitBox/CollisionShape2D

var damage = 1
var drawing = false
var swinging = false
var hit_enemies := {}


func _ready():
	legs.play("stand")
	anim_tree.active = true
	if has_sword:
		damage = 2
	z_index = 1
	hitbox.disabled = true


func _physics_process(_delta):
	get_input()
	if velocity != Vector2(0, 0):
		legs.play("walk")
	else:
		legs.play("stand")
	legs.rotation = velocity.angle() + PI / 2
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


func _start_swing():
	hit_enemies.clear()
	hitbox.disabled = false


func _end_swing():
	hitbox.disabled = true


func take_damage(dam):
	hitpoints -= dam
	print("hp: ", hitpoints)
	if hitpoints <= 0:
		game_over()
	else:
		print("OOUUWWWOUWOWOUUWWWWUU")


func game_over():
	print("Oh no! I have been defeated by the Goblins")
	


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


func _on_hit_box_area_entered(area):
	if area.get_parent() is Enemy and !hit_enemies.has(area.get_parent()):
		hit_enemies[area.get_parent()] = true
		area.get_parent().take_damage(damage)
		area.get_parent().apply_knockback(torso.global_position, 400)
