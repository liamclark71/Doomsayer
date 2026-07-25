class_name Character extends CharacterBody2D

@export var speed = 400
@export var arrow_scene: PackedScene
@export var rock_scene: PackedScene
@export var hitpoints = 5
@export var dodge_speed = 1500
@export var dodge_duration = 0.1
@export var dodge_cooldown = 0.5
@export var camera_lookahead = 0.15

@export var has_bow = false
@export var has_dodge = false
@export var has_revive = false

@onready var legs = $Legs
@onready var torso = $Torso
@onready var anim_tree = $AnimationTree
@onready var anim_player = $AnimationPlayer
@onready var proj_spawn = $Torso/ProjectileSpawn
@onready var hitbox = $Torso/HitBox/CollisionShape2D
@onready var swing_timer = $SwingTimer
@onready var shoot_timer = $ShootTimer
@onready var potion_label = $PotionLabel
@onready var game_over_menu = get_node("/root/defense/CanvasLayer/GameOverBox")
@onready var ranged_charge_sound = load("res://sound_assets/ranged_charge.wav")
@onready var bow_ranged_release_sound = load("res://sound_assets/arrow_release.wav")
@onready var slingshot_release_sound = load('res://sound_assets/slingshot_release.wav')
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
@onready var slash_sound = load("res://sound_assets/stabbed.wav")
@onready var sword_wall_hit_sound = load("res://sound_assets/sword_hit_wall.wav") 
@onready var bat_wall_hit_sound = load("res://sound_assets/club_hit_wall.wav")
var camera 

var damage = 1
var drawing = false
var swinging = false
var hit_enemies := {}
var alive = true
var targetable = true

var can_dodge = true
var dodging = false
var dodge_direction = Vector2.ZERO
var last_move_direction = Vector2.DOWN
var swing_on_cooldown = false
var shoot_on_cooldown = false
var interact_object = null
var max_hitpoints = 8
var showing_blocked_message = false

var interact_scene = preload("res://interact_text.tscn")
var interact_label = null  # track the current instance

var has_sword: bool = false:
	set(value):
		has_sword = value
		damage = 2 if value else 1


func _ready():
	max_hitpoints = hitpoints
	camera = $Camera
	legs.play("stand")
	anim_tree.active = true
	z_index = 1
	hitbox.disabled = true


func walking_audio_on():
	$WalkingAudioController.volume_db = 0

func walking_audio_off():
	$WalkingAudioController.volume_db = -999

func _physics_process(_delta):
	if alive:
		get_input()
		if dodging:
			velocity = dodge_direction * dodge_speed
		else:
			if velocity != Vector2(0, 0):
				legs.play("walk")
				walking_audio_on()
			else:
				walking_audio_off()
				legs.play("stand")
		legs.rotation = velocity.angle() + PI / 2
		torso.look_at(get_global_mouse_position())
		torso.rotation += deg_to_rad(90)
		move_and_slide()
		
		var mouse_offset = (get_global_mouse_position() - global_position) * camera_lookahead
		camera.position = mouse_offset
		
		var needs_label = interact_object != null and interact_object.is_in_group("barricades") \
			and interact_object.can_repair()

		if not showing_blocked_message:
			if needs_label and interact_label == null:
				interact_label = interact_scene.instantiate()
				interact_object.add_child(interact_label)
				interact_label.text = "Press E to repair barricade"
			elif not needs_label and interact_label:
				interact_label.queue_free()
				interact_label = null

func handle_ranged_release_audio():
	$AttackAudioController.stop()
	if has_bow:
		$AttackAudioController.stream = bow_ranged_release_sound
	else:
		$AttackAudioController.stream = slingshot_release_sound
	$AttackAudioController.play()


func get_input():
	var input_direction = Input.get_vector("left", "right", "up", "down")
	
	if input_direction != Vector2.ZERO:
		last_move_direction = input_direction
	
	if not dodging:
		velocity = input_direction * speed
	
	if Input.is_action_just_pressed("dodge") and can_dodge and not dodging and has_dodge:
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
	if Input.is_action_just_pressed("interact"):
		interact()

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
	$AttackAudioController.stream = whiff_melee_sounds.pick_random()
	$AttackAudioController.play()
	hit_enemies.clear()
	hitbox.disabled = false


func _end_swing():
	hitbox.disabled = true


func take_damage(dam, _damageType):
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
	if has_revive == true:
		has_revive = false
		hitpoints = max_hitpoints
		_show_potion_label()
		return
		
	print("Oh no! I have been defeated by the Goblins")
	walking_audio_off()
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


func _show_potion_label():
	potion_label.visible = true
	potion_label.modulate = Color.TRANSPARENT
	
	var tween = get_tree().create_tween()
	tween.tween_property(potion_label, "modulate", Color(1,1,1,1), 0.05)
	tween.tween_interval(1)
	tween.tween_property(potion_label, "modulate", Color.TRANSPARENT, 0.05)
	tween.tween_callback(func(): potion_label.visible = false)


func _shoot_projectile():
	shoot_on_cooldown = true
	shoot_timer.start()
	handle_ranged_release_audio()
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

func _handleMeleeHitAudio(hitting = 'goblin'):
	if not has_sword:
		if hitting == 'goblin':
			$AttackAudioController.stream = bat_melee_sounds.pick_random()
		else:
			$AttackAudioController.stream = bat_wall_hit_sound
	else:
		if hitting == 'goblin':
			$AttackAudioController.stream = slash_sound
		else:
			$AttackAudioController.stream = sword_wall_hit_sound
	$AttackAudioController.play()
	
func play_ranged_charge_audio():
	$AttackAudioController.stream = ranged_charge_sound
	$AttackAudioController.play()


func interact():
	if interact_object:
		if interact_object.is_in_group("barricades"):
			if interact_object.needs_repair():
				if interact_object.can_repair():
					interact_object.repair_barricade()
				else:
					_show_blocked_repair_message()


func _show_blocked_repair_message():
	if interact_label:
		interact_label.queue_free()
		interact_label = null

	showing_blocked_message = true
	interact_label = interact_scene.instantiate()
	interact_object.add_child(interact_label)
	interact_label.text = "Cannot repair: goblins nearby!"

	var tween = get_tree().create_tween()
	tween.tween_interval(1.5)
	tween.tween_callback(func():
		showing_blocked_message = false
		if interact_label:
			interact_label.queue_free()
			interact_label = null
	)


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
	elif body.is_in_group("walls"):
		_handleMeleeHitAudio('wall')


func _on_interact_box_body_entered(body):
	if body.is_in_group("barricades") or body.is_in_group("characters"):
		interact_object = body


func _on_interact_box_body_exited(body):
	if body == interact_object:
		interact_object = null
		if interact_label:
			interact_label.queue_free()
			interact_label = null
