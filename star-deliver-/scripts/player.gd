extends CharacterBody2D
@onready var hotbar: HBoxContainer = $UI/Hotbar
@onready var player: AnimatedSprite2D = $player
@onready var slots = $UI/Hotbar.get_children()
@export var speed = 400
var last_direction =  "right up"


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

	elif input_direction.x > 0:
		# Moving right only
		if selected_slot == 1:
			player.play("spear walk right down")
		elif  selected_slot == 2:
			player.play("run gun right down")
		else:
			player.play("walk right down")#
		last_direction = "right down"

	elif input_direction.x < 0:
		# Moving left only
		if selected_slot == 1:
			player.play("spear walk left down")
		elif  selected_slot == 2:
			player.play("run gun left down")
		else:
			player.play("walk left down")#
		last_direction = "left down"

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



func _physics_process(delta: float) -> void:
	get_input()
	move_and_slide()

func add_items(stats):
	hotbar.add_item(stats)
