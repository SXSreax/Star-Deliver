extends CharacterBody2D

# Base and dash movement speeds
const SPEED = 150
const DASH_SPEED = 350
const DASH_DURATION = 0.3  # Duration for dash boost

# Enemy stats
var hp = 50
var threshold = 2.0  # Distance to target before stopping
var follow = false

# State flags
var death = false
var dashing = false
var dash_ready = true  # Controls dash re-triggering when player exits/re-enters detection area

# Node references
@onready var player: CharacterBody2D = $"../Player"
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	navigation_agent_2d.target_position = player.global_position
	add_to_group("bullets")  # For collision/damage handling

func make_path() -> void:
	# Updates the path to track player's current position
	navigation_agent_2d.target_position = player.global_position

func _physics_process(delta: float) -> void:
	# Prevent movement during after death
	if death:
		velocity = Vector2.ZERO
		return

	# Only follow the player if detected
	if follow:
		var next_pos = navigation_agent_2d.get_next_path_position()
		var direction = next_pos - global_position

		if direction.length() > threshold:
			var move_dir = direction.normalized()
			var current_speed: float = DASH_SPEED if dashing else SPEED
			velocity = move_dir * current_speed
			move_and_slide()
			update_animation(player.global_position - global_position)

			if dashing:
				print("DASHING at speed:", current_speed)
		else:
			# Stop if close enough to target
			velocity = Vector2.ZERO
			sprite.play("walk")
	else:
		velocity = Vector2.ZERO
		sprite.play("walk")

func update_animation(move_dir: Vector2) -> void:
	if  death:
		return

	if sprite.animation != "walk":
		sprite.play("walk")

	# Flip sprite based on movement direction (right vs left)
	if abs(move_dir.x) > abs(move_dir.y):
		sprite.flip_h = move_dir.x < 0
	else:
		sprite.flip_h = false

func _on_timer_timeout() -> void:
	# Refresh navigation path periodically
	make_path()

func _on_dash_detect_area_body_entered(body: Node2D) -> void:
	# Begin dash if player enters detection zone and dash is ready
	if body.name == "Player" and dash_ready:
		print("Player ENTERED dash area → starting dash")
		dash_ready = false
		start_dash()

func _on_dash_detect_area_body_exited(body: Node2D) -> void:
	# Reset dash readiness once player leaves detection zone
	if body.name == "Player":
		print("Player EXITED dash area → dash ready again")
		dash_ready = true

func start_dash():
	# Temporarily increase movement speed
	dashing = true
	await get_tree().create_timer(DASH_DURATION).timeout
	dashing = false
	print("Dash ended")

func _on_hurt_box_body_entered(body: Node2D) -> void:
	# Take damage when hit by bullets or other projectiles
	if body.is_in_group("bullets"):
		hp -= 10
		print("Hit! HP:", hp)
		detect_death()

func take_damage(amount):
	# Directly reduce HP and check for death
	hp -= amount
	detect_death()

func detect_death():
	if hp <= 0:
		print("Enemy dead")
		death = true
		die()

func die() -> void:
	# Play death animation and remove enemy from scene
	if death:
		sprite.play("death")
		await sprite.animation_finished
		queue_free()


func _on_detection_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		follow = true


func _on_detection_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		follow = false
