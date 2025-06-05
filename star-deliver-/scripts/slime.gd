extends CharacterBody2D

@onready var player = $"../Player"
@onready var raycast = $AnimatedSprite2D/RayCast2D

var speed = 150


func _physics_process(delta: float) -> void:
	var direction = (player.global_position - raycast.global_position).normalized()
	var length = 200  # Set your desired ray length here
	raycast.target_position = direction * length
	#var direction = (target.position-position).normalized()
	#velocity = direction * speed
	##look_at(target.position)
	#move_and_slide()
	print(raycast.is_colliding())
	

#const SPEED = 300.0
#const JUMP_VELOCITY = -400.0
#
#
#func _physics_process(delta: float) -> void:
	## Add the gravity.
	#if not is_on_floor():
		#velocity += get_gravity() * delta
#
	## Handle jump.
	#if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		#velocity.y = JUMP_VELOCITY
#
	## Get the input direction and handle the movement/deceleration.
	## As good practice, you should replace UI actions with custom gameplay actions.
	#var direction := Input.get_axis("ui_left", "ui_right")
	#if direction:
		#velocity.x = direction * SPEED
	#else:
		#velocity.x = move_toward(velocity.x, 0, SPEED)
#
	#move_and_slide()
	

	
@onready var timer: Timer = $Timer
@onready var target=$"../Player"



func _on_timer_timeout() -> void:
	pass # Replace with function body.
