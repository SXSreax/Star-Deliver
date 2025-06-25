extends CharacterBody2D
@onready var hotbar: HBoxContainer = $UI/Hotbar
@onready var player: AnimatedSprite2D = $player
@onready var slots = $UI/Hotbar.get_children()
@export var speed = 200
var last_direction =  "right up"
var bullet = preload("res://prefabs/bullet.tscn")
var hp = 100 
var cd = true


func _physics_process(delta: float) -> void:
	if hp == 0: 
		queue_free()
		get_tree().change_scene_to_file("res://prefabs/losing.tscn")
	get_input()
	move_and_slide()


func get_input():
	# Get directional input from keyboard: left/right/up/down
	var input_direction = Input.get_vector("left","right","up","down")
	
	# Get the currently selected item slot from the hotbar (e.g., sword, gun)
	var selected_slot = hotbar.current_index
	
	# Set player velocity based on input direction and movement speed
	# This will later be used to move the player
	velocity = input_direction * speed

	# If there's no input, play an idle animation depending on last direction faced
	if input_direction == Vector2.ZERO:
		# Check what the last direction was to decide which idle animation to play
		if last_direction == "right up":
			# Play idle animations based on item equipped (spear/gun/empty)
			if selected_slot == 1:
				player.play("idle spear right up")
			elif  selected_slot == 2:
				player.play("idle gun up")
			else:
				player.play("idle right up")
		elif last_direction == "left up":
			if selected_slot == 1:
				player.play("idle spear left up")
			elif  selected_slot == 2:
				player.play("idle gun left up")
			else:
				player.play("idle left up")
		elif last_direction == "left down":
			if selected_slot == 1:
				player.play("idle spear left down")
			elif  selected_slot == 2:
				player.play("idle gun left")
			else:
				player.play("idle left down")
		elif last_direction == "right down":
			if selected_slot == 1:
				player.play("idle spear right down")
			elif  selected_slot == 2:
				player.play("idle gun right down")
			else:
				player.play("idle right down")
		elif last_direction == "up":
			if selected_slot == 1:
				player.play("idle spear up")
			elif  selected_slot == 2:
				player.play("idle gun up")
			else:
				player.play("idle up")
		else:
			# Default fallback for when facing down or direction is not tracked
			if selected_slot == 1:
				player.play("idle spear down")
			elif  selected_slot == 2:
				player.play("idle gun down")
			else:
				player.play("idle down")
	
	# The following conditions handle moving input + selected item = correct animation
	elif input_direction.x > 0 and input_direction.y < 0:
		# Moving diagonally right and up
		if selected_slot == 1:
			player.play("spear walk right up")
		elif  selected_slot == 2:
			player.play("run gun right up")
		else:
			player.play("walk right up")
		# Update last_direction for future idle animation reference
		last_direction = "right up"

	elif input_direction.x > 0 and input_direction.y > 0:
		# Moving diagonally right and down
		if selected_slot == 1:
			player.play("spear walk right down")
		elif  selected_slot == 2:
			player.play("run gun right down")
		else:
			player.play("walk right down")
		
		last_direction = "right down"

	elif input_direction.x < 0 and input_direction.y < 0:
		# Moving diagonally left and up
		if selected_slot == 1:
			player.play("spear walk left up")
		elif  selected_slot == 2:
			player.play("run gun left up")
		else:
			player.play("walk left up")#
		last_direction = "left up"

	elif input_direction.x < 0 and input_direction.y > 0:
		# Moving diagonally left and down
		if selected_slot == 1:
			player.play("spear walk left down")
		elif  selected_slot == 2:
			player.play("run gun left down")
		else:
			player.play("walk left down")#
		last_direction = "left down"
	elif input_direction.x > 0 and input_direction.y == 0:

		if selected_slot == 1:
			player.play("spear walk right down")
		elif  selected_slot == 2:
			player.play("run gun right down")
		else:

			player.play("walk right down")
		last_direction = "right"
	elif input_direction.x < 0 and input_direction.y == 0:

		if selected_slot == 1:
			player.play("spear walk left down")
		elif  selected_slot == 2:
			player.play("run gun left down")
		else:

			player.play("walk left down")
		last_direction = "left"

	elif input_direction.y > 0:
		# Moving down only
		if selected_slot == 1:
			player.play("spear walk down")
		elif  selected_slot == 2:
			player.play("run gun down")
		else:
			player.play("walk down")
		last_direction = "down"

	elif input_direction.y < 0:
		# Moving up only
		if selected_slot == 1:
			player.play("spear walk up")
		else:
			player.play("walk up")
		last_direction = "up"
		
	if Input.is_action_just_pressed("attack") or Input.is_action_pressed("attack"):
		if selected_slot == 2:
			shoot()


func add_items(stats):
	hotbar.add_item(stats)

func shoot():
	if cd:
		var bullet_1 = bullet.instantiate()
		cd = false

		# Get mouse position in world coordinates
		var mouse_pos = get_global_mouse_position()
		var to_mouse = (mouse_pos - global_position).normalized()
		var angle = to_mouse.angle()

		# Map angle to 8 directions for player animation only
		var dir_vec = Vector2.RIGHT
		var direction = angle_to_direction(angle)
		match direction:
			"right":
				dir_vec = Vector2(1, 0)
			"right down":
				dir_vec = Vector2(0.707, 0.707)
			"down":
				dir_vec = Vector2(0, 1)
			"left down":
				dir_vec = Vector2(-0.707, 0.707)
			"left":
				dir_vec = Vector2(-1, 0)
			"left up":
				dir_vec = Vector2(-0.707, -0.707) 
			"up":
				dir_vec = Vector2(0, -1)
			"right up":
				dir_vec = Vector2(0.707, -0.707)

		last_direction = direction

		# Spawn bullet in front of player (use mouse direction for offset)
		var spawn_offset = to_mouse * 32
		bullet_1.pos = global_position + spawn_offset
		bullet_1.dir = to_mouse.angle() # exact angle to mouse
		bullet_1.rota = bullet_1.dir
		get_parent().add_child(bullet_1)
		cd_gun()

func angle_to_direction(angle: float) -> String:
	# 8 directions, each 45 degrees (PI/4 radians)
	var directions = [
		"right",        # -22.5 to 22.5 deg
		"right down",   # 22.5 to 67.5 deg
		"down",         # 67.5 to 112.5 deg
		"left down",    # 112.5 to 157.5 deg
		"left",         # 157.5 to -157.5 deg
		"left up",      # -157.5 to -112.5 deg
		"up",           # -112.5 to -67.5 deg
		"right up"      # -67.5 to -22.5 deg
	]
	var deg = rad_to_deg(angle)
	if deg < 0:
		deg += 360
	var index = int(round(deg / 45.0)) % 8
	return directions[index]

func cd_gun():
	await get_tree().create_timer(0.05).timeout
	cd = true


func _on_hurt_box_body_entered(body: Node2D) -> void:
	print(body.name)


func _on_hurt_box_body_exited(body: Node2D) -> void:
	pass # Replace with function body.
