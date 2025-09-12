extends CharacterBody2D

# Base and dash movement speeds
const SPEED = 150
const DASH_SPEED = 350
const DASH_DURATION = 0.3  # Duration for dash boost

# Enemy stats
var hp = 200
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
@onready var health_bar: ProgressBar = $HealthBar

# --- Blood FX (ADDED) -------------------------------------------------------
@export var blood_fx_scene: PackedScene = preload("res://prefabs/fx/blood_burst.tscn")
var last_hit_from: Vector2 = Vector2.ZERO
# ---------------------------------------------------------------------------

func _ready() -> void:
	navigation_agent_2d.target_position = player.global_position
	add_to_group("bullets")  # For collision/damage handling

func make_path() -> void:
	# Updates the path to track player's current position
	navigation_agent_2d.target_position = player.global_position

func _physics_process(delta: float) -> void:
	health_bar.value = hp
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
		last_hit_from = body.global_position  # (ADDED) remember impact source
		hp -= 10
		print("Hit! HP:", hp)
		detect_death()
		Global.add_score(20)

func take_damage(amount):
	# Directly reduce HP and check for death
	hp -= amount
	detect_death()
	Global.add_score(20)

func detect_death():
	if hp <= 0:
		print("Enemy dead")
		death = true
		die()

func die() -> void:
	# Play death animation and remove enemy from scene
	if death:
		# --- spawn blood just before dying (ADDED) ---------------------------
		var hit_from := last_hit_from if last_hit_from != Vector2.ZERO \
			else (player.global_position if is_instance_valid(player) else global_position)
		_spawn_blood(hit_from)
		# --------------------------------------------------------------------

		sprite.play("death")
		await sprite.animation_finished
		queue_free()

func _on_detection_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		follow = true

func _on_detection_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		follow = false

# Blood FX helper
func _spawn_blood(hit_from: Vector2) -> void:
	if blood_fx_scene == null:
		push_warning("blood_fx_scene is null – assign BloodBurst.tscn in the Inspector.")
		return

	var fx := blood_fx_scene.instantiate()
	get_parent().add_child(fx)           # same layer/YSort as enemy
	fx.global_position = global_position

	var away := (global_position - hit_from).normalized()

	# Root is GPUParticles2D
	if fx is GPUParticles2D:
		var p := fx as GPUParticles2D
		p.z_as_relative = false
		p.z_index = max(sprite.z_index + 1, 1)  # render above enemy
		p.rotation = away.angle()
		p.emitting = false
		p.emitting = true
		p.finished.connect(fx.queue_free, CONNECT_ONE_SHOT)
		return

	# Root is Node2D with child "Particles" (GPUParticles2D)
	var p2 := fx.get_node_or_null("Particles") as GPUParticles2D
	if p2:
		fx.rotation = away.angle()
		p2.z_as_relative = false
		p2.z_index = max(sprite.z_index + 1, 1)
		p2.emitting = false
		p2.emitting = true
		p2.finished.connect(fx.queue_free, CONNECT_ONE_SHOT)
	else:
		push_warning("Blood FX scene has no GPUParticles2D at root or child named 'Particles'.")
# ---------------------------------------------------------------------------
