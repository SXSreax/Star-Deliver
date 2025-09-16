extends CharacterBody2D

# --- Node references ---
@onready var hotbar: HBoxContainer = $UI/Hotbar        # Hotbar UI (holds equipped items)
@onready var player: AnimatedSprite2D = $player        # Player sprite controller
@onready var slots = $UI/Hotbar.get_children()         # All hotbar slots (items)
@onready var spear_sprite: Sprite2D = $SpearSprite     # Spear visual sprite
@onready var spear_hitbox: Area2D = $SpearHitbox       # Spear attack hitbox

# --- Config / stats ---
@export var speed = 200                                # Player movement speed
var last_direction = "right up"                        # Remember last facing direction
var bullet = preload("res://prefabs/bullet.tscn")      # Preload bullet scene
var hp = 99.5                                          # Player health
var cd = true                                          # Gun cooldown flag
var cd_heal = false                                    # Heal cooldown flag
var is_attacking = false                               # True when spear is swinging
var hurt_tem = hp                                      # To detect HP change for hurt SFX
var can_heal = true                                    # Can player heal?
var is_shooting = false
var can_play_shoot_anim = true
@onready var compass_arrow = $UI/CompassContainer/CompassArrowContainer/CompassArrow  # Compass pointer
@onready var receiver: CharacterBody2D = $"../Receiver"  # Target to track with compass
@onready var camera: Camera2D = get_tree().get_first_node_in_group("camera") # Main camera (for screen shake)
@onready var health_bar: ProgressBar = $health_bar     # UI health bar
var last_selected_slot = -1                            # Remember previously selected hotbar slot

# --- Game state ---
var score = 0
var was_moving = false                                 # Track movement state for walking SFX
var walking_stream: AudioStreamPlayer = null           # Walking sound player
var walking_position: float = 0.0                      # Resume walking SFX from last pos


func _ready() -> void:
	# Initialize health bar
	health_bar.value = hp

	# Hide compass arrow in hub/home scene
	var current_scene = get_tree().current_scene
	if current_scene.scene_file_path == "res://prefabs/Maps/home.tscn":
		compass_arrow.visible = false
	else:
		compass_arrow.visible = true


func _physics_process(delta: float) -> void:
	# Always update health bar UI
	health_bar.value = hp
	
	# If HP dropped → play hurt SFX
	if hurt_tem > hp:
		AudioManager.play_sfx("hurt")
		hurt_tem = hp
		
	# Heal check: press interact when not at max HP, if heal not on cooldown
	if cd_heal == false:
		if Input.is_action_just_pressed("interact") and hp < 99.5:
			med_kit()
	
	# Death check
	if hp <= 0: 
		AudioManager.play_sfx("dying")
		queue_free()
		get_tree().change_scene_to_file("res://prefabs/losing.tscn")
	
	# Cursor updates only when slot changes (optimisation)
	var selected_slot = hotbar.current_index
	if selected_slot != last_selected_slot:
		match selected_slot:
			1: Global._set_custom_cursor("res://assets/cursor/spear_cursor.png", 0.08)
			2: Global._set_custom_cursor("res://assets/cursor/gun_cursor_blue.png", 0.08)
			3: Global._set_custom_cursor("res://assets/cursor/medicine.png", 0.08)
			_: Global._set_custom_cursor("res://assets/cursor/package_new.png", 0.08)
		last_selected_slot = selected_slot
	
	# Core player controls
	get_input()
	move_and_slide()
	spear_attack()


func get_input():
	# Get directional input from keyboard
	var input_direction = Input.get_vector("left","right","up","down")
	
	# Currently selected hotbar slot
	var selected_slot = hotbar.current_index
	
	# Apply movement
	velocity = input_direction * speed

	# Prevent idle/walk animation override if mid-spear attack
	if is_attacking:
		return

	# --- Animation handling for shooting ---
	if is_shooting and selected_slot == 2:
		if input_direction == Vector2.ZERO:
			# Play idle shoot animation based on last_direction
			match last_direction:
				"right":
					player.play("idle shoot right")
				"right down":
					player.play("idle shoot right down")
				"down":
					player.play("idle shoot down")
				"left down":
					player.play("idle shoot left down")
				"left":
					player.play("idle shoot left")
				"left up":
					player.play("idle shoot left up")
				"up":
					player.play("idle shoot up")
				"right up":
					player.play("idle shoot right up")
		else:
			# Play run shoot animation based on last_direction
			match last_direction:
				"right":
					player.play("run shoot right")
				"right down":
					player.play("run shoot right down")
				"down":
					player.play("run shoot down")
				"left down":
					player.play("run shoot left down")
				"left":
					player.play("run shoot left")
				"left up":
					player.play("run shoot left up")
				"up":
					player.play("run shoot up")
				"right up":
					player.play("run shoot right up")
		return
	
	# --- Animation handling ---
	# If no movement → idle animation (depends on last direction + equipped item)
	if input_direction == Vector2.ZERO:
		if not is_attacking:
			if selected_slot == 2 and is_shooting:
				# Play idle shoot animation based on last_direction
				match last_direction:
					"right":
						player.play("idle shoot right")
					"right down":
						player.play("idle shoot right down")
					"down":
						player.play("idle shoot down")
					"left down":
						player.play("idle shoot left down")
					"left":
						player.play("idle shoot left")
					"left up":
						player.play("idle shoot left up")
					"up":
						player.play("idle shoot up")
					"right up":
						player.play("idle shoot right up")
			else:
				# Normal idle animation logic
				match last_direction:
					"right up":
						if selected_slot == 1: player.play("idle spear right up")
						elif selected_slot == 2: player.play("idle gun up")
						else: player.play("idle right up")
					"left up":
						if selected_slot == 1: player.play("idle spear left up")
						elif selected_slot == 2: player.play("idle gun left up")
						else: player.play("idle left up")
					"left down":
						if selected_slot == 1: player.play("idle spear left down")
						elif selected_slot == 2: player.play("idle gun left")
						else: player.play("idle left down")
					"right down":
						if selected_slot == 1: player.play("idle spear right down")
						elif selected_slot == 2: player.play("idle gun right down")
						else: player.play("idle right down")
					"right":
						if selected_slot == 1: player.play("idle spear right down")
						elif selected_slot == 2: player.play("idle gun right down")
						else: player.play("idle right down")
					"left":
						if selected_slot == 1: player.play("idle spear left down")
						elif selected_slot == 2: player.play("idle gun left")
						else: player.play("idle left down")
					"up":
						if selected_slot == 1: player.play("idle spear up")
						elif selected_slot == 2: player.play("idle gun up")
						else: player.play("idle up")
					_:
						if selected_slot == 1: player.play("idle spear down")
						elif selected_slot == 2: player.play("idle gun down")
						else: player.play("idle down")
	
	# If moving → play movement animation based on direction + slot
	elif input_direction.x > 0 and input_direction.y < 0:
		if selected_slot == 1: player.play("spear walk right up")
		elif selected_slot == 2: player.play("run gun right up")
		else: player.play("walk right up")
		last_direction = "right up"

	elif input_direction.x > 0 and input_direction.y > 0:
		if selected_slot == 1: player.play("spear walk right down")
		elif selected_slot == 2: player.play("run gun right down")
		else: player.play("walk right down")
		last_direction = "right down"

	elif input_direction.x < 0 and input_direction.y < 0:
		if selected_slot == 1: player.play("spear walk left up")
		elif selected_slot == 2: player.play("run gun left up")
		else: player.play("walk left up")
		last_direction = "left up"

	elif input_direction.x < 0 and input_direction.y > 0:
		if selected_slot == 1: player.play("spear walk left down")
		elif selected_slot == 2: player.play("run gun left down")
		else: player.play("walk left down")
		last_direction = "left down"

	elif input_direction.x > 0 and input_direction.y == 0:
		if selected_slot == 1: player.play("spear walk right down")
		elif selected_slot == 2: player.play("run gun right down")
		else: player.play("walk right down")
		last_direction = "right"

	elif input_direction.x < 0 and input_direction.y == 0:
		if selected_slot == 1: player.play("spear walk left down")
		elif selected_slot == 2: player.play("run gun left down")
		else: player.play("walk left down")
		last_direction = "left"

	elif input_direction.y > 0:
		if selected_slot == 1: player.play("spear walk down")
		elif selected_slot == 2: player.play("run gun down")
		else: player.play("walk down")
		last_direction = "down"

	elif input_direction.y < 0:
		if selected_slot == 1: player.play("spear walk up")
		elif selected_slot == 2: player.play("run gun up")
		else: player.play("walk up")
		last_direction = "up"
		
	# Attack input → shoot gun if slot 2 selected
	if Input.is_action_just_pressed("attack") or Input.is_action_pressed("attack"):
		if selected_slot == 2:
			shoot()


func add_items(stats):
	# Adds item into hotbar
	hotbar.add_item(stats)


func shoot():
	# Fire a bullet if gun is not on cooldown
	if cd:
		is_shooting = true
		var bullet_1 = bullet.instantiate()
		cd = false

		AudioManager.play_sfx("gun")

		var mouse_pos = get_global_mouse_position()
		var to_mouse = (mouse_pos - global_position).normalized()
		var angle = to_mouse.angle()

		var dir_vec = Vector2.RIGHT
		var direction = angle_to_direction(angle)
		match direction:
			"right": dir_vec = Vector2(1, 0)
			"right down": dir_vec = Vector2(0.707, 0.707)
			"down": dir_vec = Vector2(0, 1)
			"left down": dir_vec = Vector2(-0.707, 0.707)
			"left": dir_vec = Vector2(-1, 0)
			"left up": dir_vec = Vector2(-0.707, -0.707) 
			"up": dir_vec = Vector2(0, -1)
			"right up": dir_vec = Vector2(0.707, -0.707)

		last_direction = direction

		# --- Only play run shoot animation if moving ---
		if velocity.length() > 0.1:
			var anim_name = ""
			match direction:
				"right":
					anim_name = "run shoot right"
				"right down":
					anim_name = "run shoot right down"
				"down":
					anim_name = "run shoot down"
				"left down":
					anim_name = "run shoot left down"
				"left":
					anim_name = "run shoot left"
				"left up":
					anim_name = "run shoot left up"
				"up":
					anim_name = "run shoot up"
				"right up":
					anim_name = "run shoot right up"

			if player.animation != anim_name and can_play_shoot_anim:
				player.play(anim_name)
		# If not moving, do NOT play any animation here; let get_input() handle idle shoot

		# Spawn bullet a little in front of player, toward mouse
		var spawn_offset = to_mouse * 32
		bullet_1.pos = global_position + spawn_offset
		bullet_1.dir = to_mouse.angle()
		bullet_1.rota = bullet_1.dir
		get_parent().add_child(bullet_1)

		camera.trigger_shake(1)
		await cd_gun()
		is_shooting = false


func angle_to_direction(angle: float) -> String:
	# Map raw angle into 1 of 8 named directions
	var directions = [
		"right", "right down", "down", "left down",
		"left", "left up", "up", "right up"
	]
	var deg = rad_to_deg(angle)
	if deg < 0:
		deg += 360
	var index = int(round(deg / 45.0)) % 8
	return directions[index]


func cd_gun():
	# Small delay before gun can shoot again
	await get_tree().create_timer(0.05).timeout
	cd = true


func _on_hurt_box_body_entered(body: Node2D) -> void:
	# Damage taken when touching enemies
	print("q")
	if body.is_in_group("enemies"):
		print("q")
		hp -= 10
		camera.trigger_shake(3)


func _on_hurt_box_body_exited(body: Node2D) -> void:
	pass # Reserved for logic when leaving enemy contact
	

func spear_attack():
	# Spear swing attack if equipped and not mid-attack
	var selected_slot = hotbar.current_index
	if Input.is_action_just_pressed("attack") and selected_slot == 1 and not is_attacking:
		is_attacking = true

		var mouse_pos = get_global_mouse_position()
		var to_mouse = (mouse_pos - global_position).normalized()
		var angle = to_mouse.angle()
		var direction = angle_to_direction(angle)

		# Activate hitbox in swing direction
		spear_hitbox.global_position = global_position + to_mouse * 2
		spear_hitbox.rotation = angle
		spear_hitbox.monitoring = true
		
		AudioManager.play_sfx("spear")

		# Play correct spear animation
		match direction:
			"right": player.play("attack spear right")
			"right down": player.play("attack spear down right")
			"down": player.play("attack spear down")
			"left down": player.play("attack spear down left")
			"left": player.play("attack spear left")
			"left up": player.play("attack spear up left")
			"up": player.play("attack spear up")
			"right up": player.play("attack spear up right")
			_: player.play("attack spear down")
		

func _on_animation_finished():
	# Reset spear attack state only if an attack animation just ended
	if player.animation.begins_with("attack spear"):
		is_attacking = false
		spear_hitbox.monitoring = false # disable hitbox
		_play_idle_animation()


func _play_idle_animation():
	# Return to idle pose depending on last direction + equipped slot
	var selected_slot = hotbar.current_index
	match last_direction:
		"right up":
			if selected_slot == 1: player.play("idle spear right up")
			elif selected_slot == 2: player.play("idle gun up")
			else: player.play("idle right up")
		"left up":
			if selected_slot == 1: player.play("idle spear left up")
			elif selected_slot == 2: player.play("idle gun left up")
			else: player.play("idle left up")
		"left down":
			if selected_slot == 1: player.play("idle spear left down")
			elif selected_slot == 2: player.play("idle gun left")
			else: player.play("idle left down")
		"right down":
			if selected_slot == 1: player.play("idle spear right down")
			elif selected_slot == 2: player.play("idle gun right down")
			else: player.play("idle right down")
		"right":
			if selected_slot == 1: player.play("idle spear right down")
			elif selected_slot == 2: player.play("idle gun right down")
			else: player.play("idle right down")
		"left":
			if selected_slot == 1: player.play("idle spear left down")
			elif selected_slot == 2: player.play("idle gun left")
			else: player.play("idle left down")
		"up":
			if selected_slot == 1: player.play("idle spear up")
			elif selected_slot == 2: player.play("idle gun up")
			else: player.play("idle up")
		_:
			if selected_slot == 1: player.play("idle spear down")
			elif selected_slot == 2: player.play("idle gun down")
			else: player.play("idle down")


func med_kit():
	# Heals the player by 5, then locks healing for 5s
	can_heal = false
	hp = hp + 5 
	cd_heal = true
	await get_tree().create_timer(5.0).timeout
	cd_heal = false


func _process(delta):
	# Update compass arrow to always point to receiver
	if receiver:
		var dir = (receiver.global_position - global_position).normalized()
		compass_arrow.rotation = dir.angle() + PI/2   # PI/2 offset fixes sprite orientation
