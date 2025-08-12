extends CharacterBody2D

# Enemy movement speed
const SPEED = 100

# References to necessary nodes
@onready var player: CharacterBody2D = $"../Player"
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Enemy health
var hp = 75
var follow = false

# Minimum distance to path target before stopping
var threshold = 2.0

# State flags
var attacking = false
var death = false

func _ready() -> void:
	# Set initial path target and assign to bullet group for collision tracking
	navigation_agent_2d.target_position = player.global_position
	add_to_group("bullets")

func make_path() -> void:
	# Refresh path to player's current location
	navigation_agent_2d.target_position = player.global_position

func _physics_process(delta: float) -> void:
	# Stop movement if attacking
	if attacking:
		velocity = Vector2.ZERO
		return

	# Only follow the player if detected
	if follow:
		var next_pos = navigation_agent_2d.get_next_path_position()
		var direction = next_pos - global_position

		if direction.length() > threshold:
			var move_dir = direction.normalized()
			velocity = move_dir * SPEED
			move_and_slide()
			update_animation(player.global_position - global_position)
		else:
			velocity = Vector2.ZERO
			sprite.play("idle")
	else:
		velocity = Vector2.ZERO
		sprite.play("idle")

func update_animation(move_dir: Vector2) -> void:
	# Avoid changing animation while attacking or dead
	if attacking or death:
		return

	if sprite.animation != "walk":
		sprite.play("walk")

	# Flip based on horizontal movement for visual direction
	if abs(move_dir.x) > abs(move_dir.y):
		sprite.flip_h = move_dir.x < 0
	else:
		sprite.flip_h = false

func _on_timer_timeout() -> void:
	# Periodically update path to follow the player
	make_path()

func _on_attack_area_body_entered(body: Node2D) -> void:
	# Trigger attack animation only if colliding with player and not already attacking
	if body.name == "Player" and not attacking:
		attacking = true
		sprite.play("attack")

func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation == "attack":
		attacking = false
		# Resume chasing immediately after attack
		make_path()
		var next_pos = navigation_agent_2d.get_next_path_position()
		var direction = (next_pos - global_position)

		if direction.length() > threshold:
			var move_dir = direction.normalized()
			velocity = move_dir * SPEED
			update_animation(move_dir)

func _on_attack_area_body_exited(body: Node2D) -> void:
	# Stop attack state when player exits attack area
	if body.name == "Player":
		attacking = false

func die() -> void:
	if death:
		sprite.play("death")
		await sprite.animation_finished
		queue_free()  # Clean up the enemy after death animation

func detect_death():
	if hp <= 0:
		print("Enemy dead")
		death = true
		die()

func _on_hurt_box_body_entered(body: Node2D) -> void:
	# React to bullet collision by reducing health and checking for death
	if body.is_in_group("bullets"):
		hp -= 10
		print("Hit! HP:", hp)
		detect_death()

func take_damage(amount):
	# Generic damage function (can be called externally)
	hp -= amount
	detect_death()


func _on_detection_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		follow = true


func _on_detection_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		follow = false
