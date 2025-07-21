extends CharacterBody2D

# Get reference to the player
@onready var player = $"../Player"

# RayCast2D used to check line-of-sight toward player
@onready var raycast: RayCast2D = $AnimatedSprite2D/RayCast2D

# Enemy's sprite node to play animations
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Movement speed and health
var speed = 75
var hp = 50

# Direction of movement and dying status
var direction: Vector2 = Vector2.ZERO
var is_dying = false


func _physics_process(delta: float) -> void:
	# Skip all logic if enemy is already dying
	if is_dying:
		return

	# If health drops to 0 or below, start death sequence
	if hp <= 0:
		is_dying = true
		velocity = Vector2.ZERO  # Stop moving
		sprite.play("death")     # Play death animation
		return  # Exit now so animation can start

	# Calculate direction to player for raycast and movement
	direction = (player.global_position - raycast.global_position).normalized()
	var length = 500
	raycast.target_position = direction * length

	# If player is in line of sight, move toward them
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider != null and collider.name == "Player":
			velocity = direction * speed
			move_and_slide()
			update_animation(direction)


# Handle when enemy is hit by bullet
func _on_hurt_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("bullets"):
		hp -= 10  # Reduce health when hit


# Optional external damage function
func take_damage(amount):
	hp -= amount


# Play walk animation based on direction
func update_animation(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		# Side movement (left or right)
		sprite.play("walk")
		sprite.flip_h = dir.x < 0  # Flip horizontally if moving left
	elif dir.y < 0:
		# Moving up
		sprite.play("walk_up")
		sprite.flip_h = false
	elif dir.y > 0:
		# Moving down
		sprite.play("walk_down")
		sprite.flip_h = false


# Triggered when any animation finishes
func _on_AnimatedSprite2D_animation_finished():
	# Only queue_free after death animation ends
	if is_dying and sprite.animation == "death":
		queue_free()  # Safely remove enemy from scene
