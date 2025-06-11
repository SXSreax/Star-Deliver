#extends CharacterBody2D
#
#
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

extends CharacterBody2D

const speed = 200
@onready var player: CharacterBody2D = $"../Player"
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D

func makepath() -> void:
	navigation_agent_2d.target_position = player.global_position
	print("made path {player}".format([navigation_agent_2d.target_position]))

func _ready() -> void:
	makepath()

func _physics_process(delta: float) -> void:
	var direction = (navigation_agent_2d.get_next_path_position() - global_position).normalized()
	velocity = direction * speed
	move_and_slide()


func _on_timer_timeout() -> void:
	makepath() # Replace with function body.
