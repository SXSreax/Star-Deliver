extends CharacterBody2D
@onready var hotbar: HBoxContainer = $UI/Hotbar
@onready var player: AnimatedSprite2D = $player
@onready var slots = $UI/Hotbar.get_children()
@export var speed = 400
var last_direction =  "right up"
var bullet = preload("res://prefabs/bullet.tscn")


func get_input():
	var input_direction = Input.get_vector("left","right","up","down")
	var selected_slot = hotbar.current_index
	print(selected_slot)
	# Get the number , pass that into movement , depende on that change the animation, and add a colide area detection detect detect enemeues and if there are enmeies, print out
	velocity = input_direction * speed
	if input_direction == Vector2.ZERO:
		if last_direction == "right up":
			if selected_slot == 1:
				player.play("idle spear right up")
			else:
				player.play("idle right up")
		elif last_direction == "right down":
			if selected_slot == 1:
				player.play("idle spear right down")
			else:
				player.play("idle right down")
		elif last_direction == "left up":
			if selected_slot == 1:
				player.play("idle spear left up")
			else:
				player.play("idle left up")
		elif last_direction == "left down":
			if selected_slot == 1:
				player.play("idle spear left down")
			else:
				player.play("idle left down")
		elif last_direction == "right down":
			if selected_slot == 1:
				player.play("idle spear right down")
			else:
				player.play("idle right down")
		elif last_direction == "up":
			if selected_slot == 1:
				player.play("idle spear up")
			else:
				player.play("idle up")
		else:
			if selected_slot == 1:
				player.play("idle spear down")
			else:
				player.play("idle down")
	elif input_direction.x > 0 and input_direction.y < 0:
		if selected_slot == 1:
			player.play("spear walk right up")
		else:
			player.play("walk right up")
			#pass
		last_direction = "right up"
	elif input_direction.x > 0 and input_direction.y > 0:
		if selected_slot == 1:
			player.play("spear walk right down")
		else:
			player.play("walk right down")
		
		last_direction = "right down"
	elif input_direction.x < 0 and input_direction.y < 0:
		if selected_slot == 1:
			player.play("spear walk left up")
		else:
			player.play("walk left up")#
		last_direction = "left up"
	elif input_direction.x < 0 and input_direction.y > 0:
		if selected_slot == 1:
			player.play("spear walk left down")
		else:
			player.play("walk left down")#
		last_direction = "left down"
	elif input_direction.x > 0 and input_direction.y == 0:
		if selected_slot == 1:
			player.play("spear walk right down")
		else:
			player.play("walk right down")
		last_direction = "right"
	elif input_direction.x < 0 and input_direction.y == 0:
		if selected_slot == 1:
			player.play("spear walk left down")
		else:
			player.play("walk left down")
		last_direction = "left"
	elif input_direction.y > 0:
		if selected_slot == 1:
			player.play("spear walk down")
		else:
			player.play("walk down")
		last_direction = "down"
		
	elif input_direction.y < 0:
		if selected_slot == 1:
			player.play("spear walk up")
		else:
			player.play("walk up")
		last_direction = "up"
		
	if Input.is_action_just_pressed("attack"):
		if selected_slot == 2:
			shoot()


func _physics_process(delta: float) -> void:
	get_input()
	move_and_slide()

func add_items(stats):
	hotbar.add_item(stats)

func shoot():
	var bullet_1 = bullet.instantiate()
	
	# Determine direction vector based on last_direction
	var dir_vec = Vector2.RIGHT
	match last_direction:
		"right up":
			dir_vec = Vector2(1, -1).normalized()
		"right down":
			dir_vec = Vector2(1, 1).normalized()
		"left up":
			dir_vec = Vector2(-1, -1).normalized()
		"left down":
			dir_vec = Vector2(-1, 1).normalized()
		"right":
			dir_vec = Vector2(1, 0)
		"left":
			dir_vec = Vector2(-1, 0)
		"up":
			dir_vec = Vector2(0, -1)
		"down":
			dir_vec = Vector2(0, 1)
	
	# Spawn bullet in front of player
	var spawn_offset = dir_vec * 32 # 32 pixels in front, adjust as needed
	bullet_1.pos = global_position + spawn_offset
	bullet_1.dir = dir_vec.angle()
	bullet_1.rota = bullet_1.dir
	get_parent().add_child(bullet_1)
