class_name Character extends CharacterBody2D

@export var speed = 400
@export var has_bow = false
@export var has_sword = false
@export var dodge_unlocked = false
@export var arrow_scene: PackedScene
@export var rock_scene: PackedScene
@export var hitpoints = 5
@export var dodge_speed = 1500
@export var dodge_duration = 0.1
@export var dodge_cooldown = 0.5
@export var camera_lookahead = 0.15

@onready var legs = $Legs
@onready var torso = $Torso
@onready var anim_tree = $AnimationTree
@onready var anim_player = $AnimationPlayer
@onready var proj_spawn = $Torso/ProjectileSpawn
@onready var hitbox = $Torso/HitBox/CollisionShape2D
@onready var swing_timer = $SwingTimer
@onready var shoot_timer = $ShootTimer
@onready var game_over_menu = get_node("/root/defense/CanvasLayer/GameOverBox")

@onready var bat_melee_sounds: Array[AudioStream] = [
	load("res://sound_assets/bathit1.wav"),
	load("res://sound_assets/bathit2.wav"),
	load("res://sound_assets/bathit3.wav"),
	load("res://sound_assets/bathit4.wav"),
	load("res://sound_assets/bathit5.wav")
]
@onready var whiff_melee_sounds: Array[AudioStream] = [
load("res://sound_assets/whiff1.wav"),
load("res://sound_assets/whiff2.wav"),
load("res://sound_assets/whiff3.wav"),
load("res://sound_assets/whiff4.wav")
]

var camera 

var damage = 1
var drawing = false
var swinging = false
var hit_enemies := {}
var alive = true
var targetable = true

var dodging = false
var can_dodge = true
var dodge_direction = Vector2.ZERO
var last_move_direction = Vector2.DOWN
var swing_on_cooldown = false
var shoot_on_cooldown = false


func _ready():
	camera = $Camera
	legs.play("stand")
	anim_tree.active = true
	if has_sword:
		damage = 2
	z_index = 1
	hitbox.disabled = true


func _physics_process(_delta):
	if alive:
		get_input()
		if dodging:
			velocity = dodge_direction * dodge_speed
		else:
			if velocity != Vector2(0, 0):
				legs.play("walk")
			else:
				legs.play("stand")
		legs.rotation = velocity.angle() + PI / 2
		torso.look_at(get_global_mouse_position())
		torso.rotation += deg_to_rad(90)
		move_and_slide()
		
		var mouse_offset = (get_global_mouse_position() - global_position) * camera_lookahead
		camera.position = mouse_offset


func get_input():
	var input_direction = Input.get_vector("left", "right", "up", "down")
	
	if input_direction != Vector2.ZERO:
		last_move_direction = input_direction
	
	if not dodging:
		velocity = input_direction * speed
	
	if Input.is_action_just_pressed("dodge") and can_dodge and not dodging:
		_start_dodge(input_direction)
	
	if Input.is_action_pressed("draw") and shoot_on_cooldown == false:
		drawing = true
	else:
		drawing = false
	if Input.is_action_pressed("swing") and swing_on_cooldown == false:
		swinging = true
		swing_on_cooldown = true
		swing_timer.start()
	else:
		swinging = false

func _start_dodge(input_direction: Vector2):
	if input_direction != Vector2.ZERO:
		dodge_direction = input_direction 
	else: 
		return
	dodging = true
	can_dodge = false
	
	await get_tree().create_timer(dodge_duration).timeout
	dodging = false
	
	await get_tree().create_timer(dodge_cooldown).timeout
	can_dodge = true

func _start_swing():
	$MeleeAudioController.stream = whiff_melee_sounds.pick_random()
	$MeleeAudioController.play()
	hit_enemies.clear()
	hitbox.disabled = false


func _end_swing():
	hitbox.disabled = true


func take_damage(dam, damageType):
	$GotStabbedAudioController.play()
	if not alive:
		return
	var tween = get_tree().create_tween()
	tween.tween_property($Torso, "modulate", Color(1.0, 0.35, 0.35), 0.1)
	tween.tween_property($Torso, "modulate", Color.WHITE, 0.1)
	hitpoints -= dam
	print("hp: ", hitpoints)
	if hitpoints <= 0:
		game_over()
	else:
		print("OOUUWWWOUWOWOUUWWWWUU")


func game_over():
	print("Oh no! I have been defeated by the Goblins")
	anim_tree.active = false
	anim_player.play("die")
	legs.visible = false
	z_index = -1
	alive = false
	if game_over_menu:
		game_over_menu.modulate = Color.TRANSPARENT
		game_over_menu.visible = true
		var tween = get_tree().create_tween()
		tween.tween_interval(1.5)
		tween.tween_property(game_over_menu, "modulate", Color(1,1,1,.9), 1)


func _shoot_projectile():
	shoot_on_cooldown = true
	shoot_timer.start()
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

func _handleMeleeHitAudio():
	if not has_sword:
		$MeleeAudioController.stream = bat_melee_sounds.pick_random()
	$MeleeAudioController.play()
	

func _on_hit_box_area_entered(area):
	if area.get_parent() is Enemy and !hit_enemies.has(area.get_parent()):
		hit_enemies[area.get_parent()] = true
		_handleMeleeHitAudio()
		area.get_parent().take_damage(damage, 'club' if not has_sword else 'sword')
		area.get_parent().apply_knockback(torso.global_position, 400)
		
func _on_swing_timer_timeout():
	swing_on_cooldown = false


func _on_shoot_timer_timeout():
	shoot_on_cooldown = false


func _on_hit_box_body_entered(body):
	if body.is_in_group("barricades"):
		if body.glass_intact == true:
			body.take_damage(damage, 'test')
			hit_enemies[body] = true
