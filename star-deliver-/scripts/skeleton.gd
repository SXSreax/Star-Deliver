extends CharacterBody2D

# Enemy movement speed
const SPEED = 100

# References to necessary nodes
@onready var player: CharacterBody2D = $"../Player"
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar

# Enemy health
var hp = 75
var follow = false

# Minimum distance to path target before stopping
var threshold = 2.0

# State flags
var attacking = false
var death = false

# --- Blood FX (ADDED) -------------------------------------------------------
@export var blood_fx_scene: PackedScene = preload("res://prefabs/fx/blood_burst.tscn")
var last_hit_from: Vector2 = Vector2.ZERO
# ---------------------------------------------------------------------------

func _ready() -> void:
	# Set initial path target and assign to bullet group for collision tracking
	navigation_agent_2d.target_position = player.global_position
	add_to_group("bullets")

func make_path() -> void:
	# Refresh path to player's current location
	navigation_agent_2d.target_position = player.global_position

func _physics_process(delta: float) -> void:
	health_bar.value = hp
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
		# --- spawn blood just before death animation (ADDED) ----------------
		var hit_from := last_hit_from if last_hit_from != Vector2.ZERO \
			else (player.global_position if is_instance_valid(player) else global_position)
		_spawn_blood(hit_from)
		# -------------------------------------------------------------------

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
		last_hit_from = body.global_position   # (ADDED) remember impact source
		hp -= 10
		print("Hit! HP:", hp)
		detect_death()
		Global.add_score(10)

func take_damage(amount):
	# Generic damage function (can be called externally)
	hp -= amount
	detect_death()
	Global.add_score(10)

func _on_detection_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		follow = true

func _on_detection_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		follow = false

# --- Blood FX helper (ADDED) -----------------------------------------------
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
		p.z_index = max(sprite.z_index + 1, 1)
		p.rotation = away.angle()
		p.emitting = false
		p.emitting = true
		p.finished.connect(fx.queue_free, CONNECT_ONE_SHOT)
		return

	# Root is Node2D with child "Particles" = GPUParticles2D
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
