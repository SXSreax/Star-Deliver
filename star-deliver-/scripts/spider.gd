extends CharacterBody2D

# Base and dash movement speeds
const SPEED = 150
const DASH_SPEED = 350
const DASH_DURATION = 0.3  # Duration for dash boost

# Enemy stats
var hp = 50
var threshold = 2.0  # Distance to target before stopping

# State flags
var attacking = false
var death = false
var dashing = false
var dash_ready = true  # Controls dash re-triggering when player exits/re-enters detection area

# Tracks the last direction for idle animation
var last_direction: Vector2 = Vector2.DOWN

# Node references
@onready var player: CharacterBody2D = $"../Player"
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	navigation_agent_2d.target_position = player.global_position
	add_to_group("bullets")  # For collision/damage handling

func make_path() -> void:
	navigation_agent_2d.target_position = player.global_position

func _physics_process(delta: float) -> void:
	if attacking or death:
		velocity = Vector2.ZERO
		return

	var next_pos = navigation_agent_2d.get_next_path_position()
	var direction = next_pos - global_position

	if direction.length() > threshold:
		var move_dir = direction.normalized()
		last_direction = move_dir  # store last direction when moving

		var current_speed: float = DASH_SPEED if dashing else SPEED
		velocity = move_dir * current_speed
		move_and_slide()
		update_animation(move_dir)

		if dashing:
			print("DASHING at speed:", current_speed)
	else:
		velocity = Vector2.ZERO
		update_animation(Vector2.ZERO)

func update_animation(move_dir: Vector2) -> void:
	if attacking or death:
		return

	var is_moving = move_dir.length() > 0.1
	var animation_prefix = "walk" if is_moving else "idle"

	var dir = move_dir if is_moving else last_direction

	if abs(dir.x) > abs(dir.y):
		# Horizontal
		if dir.x > 0:
			sprite.play(animation_prefix + "_right")
			sprite.flip_h = false
		else:
			sprite.play(animation_prefix + "_right")
			sprite.flip_h = true
	else:
		# Vertical
		sprite.flip_h = false
		if dir.y > 0:
			sprite.play(animation_prefix + "_down")
		else:
			sprite.play(animation_prefix + "_up")

func _on_timer_timeout() -> void:
	make_path()

func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not attacking:
		attacking = true
		sprite.play("attack")  # This is placeholder until attack animation is added

func _on_animated_sprite_2d_animation_finished() -> void:
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
	if body.name == "Player":
		attacking = false

func _on_dash_detect_area_body_entered(body: Node2D) -> void:
	if body.name == "Player" and dash_ready:
		print("Player ENTERED dash area → starting dash")
		dash_ready = false
		start_dash()

func _on_dash_detect_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		print("Player EXITED dash area → dash ready again")
		dash_ready = true

func start_dash():
	dashing = true
	await get_tree().create_timer(DASH_DURATION).timeout
	dashing = false
	print("Dash ended")

func _on_hurt_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("bullets"):
		hp -= 10
		print("Hit! HP:", hp)
		detect_death()

func take_damage(amount):
	hp -= amount
	detect_death()

func detect_death():
	if hp <= 0:
		print("Enemy dead")
		death = true
		die()

func die() -> void:
	if death:
		queue_free()
