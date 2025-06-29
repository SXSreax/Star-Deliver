extends CharacterBody2D

@onready var player = $"../Player"
@onready var raycast: RayCast2D = $AnimatedSprite2D/RayCast2D

var speed = 75
var hp = 50 

func _physics_process(delta: float) -> void:
	if hp == 0:
		queue_free()
	
	var direction = (player.global_position - raycast.global_position).normalized()
	var length = 500  # Set your desired ray length here
	raycast.target_position = direction * length

	
	if raycast.is_colliding(): 
		var collider = raycast.get_collider()
		if collider != null:
			var collider_name = collider.name
			if collider_name == "Player":
				velocity = direction * speed
				move_and_slide()
			
func _on_hurt_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("bullets"):
		hp -= 10
	
	
	# Replace with function body.
	#else:
		#print("dont chase")
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
