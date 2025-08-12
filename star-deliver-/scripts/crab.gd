extends CharacterBody2D

# Enemy movement speed
const SPEED = 150

# References to necessary nodes
@onready var player: CharacterBody2D = $"../Player"
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Enemy health
var hp = 50
var follow = false

# Pathfinding stop threshold
var threshold = 2.0

# State flags
var attacking = false
var death = false

func _ready() -> void:
	# Set initial path target to player and join bullets group for interaction
	navigation_agent_2d.target_position = player.global_position
	add_to_group("bullets")

func make_path() -> void:
	# Update navigation path to follow player
	navigation_agent_2d.target_position = player.global_position

func _physics_process(delta: float) -> void:
	# Prevent movement during attack or death
	if attacking or death:
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
	# Avoid animation change when attacking or dead
	if attacking or death:
		return

	if sprite.animation != "walk":
		sprite.play("walk")

	# Flip horizontally based on direction
	if abs(move_dir.x) > abs(move_dir.y):
		sprite.flip_h = move_dir.x < 0
	else:
		sprite.flip_h = false

func _on_timer_timeout() -> void:
	# Regularly update the path
	make_path()

func _on_attack_area_body_entered(body: Node2D) -> void:
	# Start attacking if player enters attack range
	if body.name == "Player" and not attacking:
		attacking = true
		sprite.play("attack")

func _on_animated_sprite_2d_animation_finished() -> void:
	# Resume movement after attack
	if sprite.animation == "attack":
		attacking = false
		make_path()

		var next_pos = navigation_agent_2d.get_next_path_position()
		var direction = next_pos - global_position

		if direction.length() > threshold:
			var move_dir = direction.normalized()
			velocity = move_dir * SPEED
			update_animation(move_dir)

func _on_attack_area_body_exited(body: Node2D) -> void:
	# Cancel attack state if player leaves attack area
	if body.name == "Player":
		attacking = false

func die() -> void:
	if death:
		sprite.play("dying")
		await sprite.animation_finished
		queue_free()

func detect_death():
	if hp <= 0:
		print("Enemy dead")
		death = true
		die()

func _on_hurt_box_body_entered(body: Node2D) -> void:
	# Take damage on bullet collision
	if body.is_in_group("bullets"):
		hp -= 10
		print("Hit! HP:", hp)
		detect_death()

func take_damage(amount):
	# Generic damage handler
	hp -= amount
	detect_death()


func _on_detection_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		follow = true


func _on_detection_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		follow = false
