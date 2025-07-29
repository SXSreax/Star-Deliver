extends CharacterBody2D

# Enemy movement speed
const SPEED = 100

# References to necessary nodes
@onready var player: CharacterBody2D = $"../Player"
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

# Enemy health
var hp = 75

# Distance threshold to decide when to move
# Prevents jittery movement when near the target point
var threshold = 2.0

# Flag to indicate if enemy is attacking
var attacking = false


func _ready() -> void:
	# Set initial path to the player's position
	navigation_agent_2d.target_position = player.global_position
	add_to_group("bullets")

func make_path() -> void:
	# Update the navigation path to follow the player's position
	navigation_agent_2d.target_position = player.global_position


func _physics_process(delta: float) -> void:
	# Do not move while attacking
	if attacking:
		velocity = Vector2.ZERO
		return

	# Calculate direction to next navigation point
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


func update_animation(move_dir: Vector2) -> void:
	# Don't play walk animation if attacking
	if attacking:
		return

	if sprite.animation != "walk":
		sprite.play("walk")

	# Flip sprite horizontally based on movement
	if abs(move_dir.x) > abs(move_dir.y):
		sprite.flip_h = move_dir.x < 0
	else:
		sprite.flip_h = false


func _on_timer_timeout() -> void:
	make_path()


func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not attacking:
		attacking = true
		sprite.play("attack")


func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation == "attack":
		attacking = false

		# Force new path + immediate velocity
		make_path()

		var next_pos = navigation_agent_2d.get_next_path_position()
		var direction = (next_pos - global_position)

		if direction.length() > threshold:
			var move_dir = direction.normalized()
			velocity = move_dir * SPEED
			update_animation(move_dir)


func _on_attack_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		attacking = false


func die() -> void:
	sprite.play("death")
	await sprite.animation_finished
	queue_free()


func _on_hurt_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("bullets"):
		hp -= 10
		print("Hit! HP:", hp)

		if hp <= 0:
			print("Enemy dead")
			die()
