extends CharacterBody2D

# --- Constants --------------------------------------------------------------
const SPEED: float = 150.0
const DASH_SPEED: float = 350.0
const DASH_DURATION: float = 0.3   # Dash boost duration (seconds)

# --- Enemy stats ------------------------------------------------------------
var hp: int = 50
var threshold: float = 2.0   # Stop moving if closer than this
var follow: bool = false

# --- State flags ------------------------------------------------------------
var attacking: bool = false
var death: bool = false
var dashing: bool = false
var dash_ready: bool = true   # Reset when player exits/re-enters dash zone

# Remember the last facing direction → used for idle animation
var last_direction: Vector2 = Vector2.DOWN

# --- Node references --------------------------------------------------------
@onready var player: CharacterBody2D = $"../Player"
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar

# --- Blood FX ---------------------------------------------------------------
@export var blood_fx_scene: PackedScene = preload("res://prefabs/fx/blood_burst.tscn")
var last_hit_from: Vector2 = Vector2.ZERO


# --- Setup ------------------------------------------------------------------
func _ready() -> void:
	navigation_agent_2d.target_position = player.global_position
	add_to_group("bullets")   # For collision/damage tracking


func make_path() -> void:
	# Refresh navigation path to player
	navigation_agent_2d.target_position = player.global_position


# --- Main loop --------------------------------------------------------------
func _physics_process(_delta: float) -> void:
	health_bar.value = hp

	# Stop movement if attacking or already dead
	if attacking or death:
		velocity = Vector2.ZERO
		return

	if follow:
		var next_pos: Vector2 = navigation_agent_2d.get_next_path_position()
		var direction: Vector2 = next_pos - global_position

		if direction.length() > threshold:
			var move_dir: Vector2 = direction.normalized()
			last_direction = move_dir   # Save direction for idle anim

			var current_speed: float = DASH_SPEED if dashing else SPEED
			velocity = move_dir * current_speed
			move_and_slide()
			update_animation(move_dir)

			if dashing:
				print("DASHING at speed:", current_speed)
		else:
			velocity = Vector2.ZERO
			update_animation(Vector2.ZERO)
	else:
		velocity = Vector2.ZERO
		update_animation(Vector2.ZERO)


# --- Animation handling -----------------------------------------------------
func update_animation(move_dir: Vector2) -> void:
	if attacking or death:
		return

	var is_moving: bool = move_dir.length() > 0.1
	var anim_prefix: String = "walk" if is_moving else "idle"
	var dir: Vector2 = move_dir if is_moving else last_direction

	if abs(dir.x) > abs(dir.y):
		# Horizontal
		if dir.x > 0:
			sprite.play(anim_prefix + "_right")
			sprite.flip_h = false
		else:
			sprite.play(anim_prefix + "_right")
			sprite.flip_h = true
	else:
		# Vertical
		sprite.flip_h = false
		if dir.y > 0:
			sprite.play(anim_prefix + "_down")
		else:
			sprite.play(anim_prefix + "_up")


# --- Timer + Attack ---------------------------------------------------------
func _on_timer_timeout() -> void:
	make_path()


func _on_attack_area_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not attacking:
		attacking = true
		sprite.play("attack")   # Placeholder until proper attack anim added


func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation == "attack":
		attacking = false
		make_path()

		var next_pos: Vector2 = navigation_agent_2d.get_next_path_position()
		var direction: Vector2 = next_pos - global_position

		if direction.length() > threshold:
			var move_dir: Vector2 = direction.normalized()
			velocity = move_dir * SPEED
			update_animation(move_dir)


func _on_attack_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		attacking = false


# --- Dash behavior ----------------------------------------------------------
func _on_dash_detect_area_body_entered(body: Node2D) -> void:
	if body.name == "Player" and dash_ready:
		print("Player ENTERED dash area → starting dash")
		dash_ready = false
		start_dash()


func _on_dash_detect_area_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		print("Player EXITED dash area → dash ready again")
		dash_ready = true


func start_dash() -> void:
	dashing = true
	await get_tree().create_timer(DASH_DURATION).timeout
	dashing = false
	print("Dash ended")


# --- Damage + Death ---------------------------------------------------------
func _on_hurt_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("bullets"):
		last_hit_from = body.global_position
		hp -= 10
		print("Hit! HP:", hp)
		detect_death()
		Global.add_score(20)


func take_damage(amount: int) -> void:
	hp -= amount
	detect_death()
	Global.add_score(20)


func detect_death() -> void:
	if hp <= 0:
		print("Enemy dead")
		death = true
		die()


func die() -> void:
	if death:
		# Spawn blood effect before removing enemy
		var hit_from: Vector2 = (
			last_hit_from if last_hit_from != Vector2.ZERO
			else (player.global_position if is_instance_valid(player) else global_position)
		)
		_spawn_blood(hit_from)
		queue_free()


# --- Detection triggers -----------------------------------------------------
func _on_detection_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		follow = true


func _on_detection_body_exited(body: Node2D) -> void:
	if body.name == "Player":
		follow = false


# --- Blood FX helper --------------------------------------------------------
func _spawn_blood(hit_from: Vector2) -> void:
	if blood_fx_scene == null:
		push_warning("blood_fx_scene is null – assign BloodBurst.tscn in the Inspector.")
		return

	var fx: Node = blood_fx_scene.instantiate()
	get_parent().add_child(fx)      # Same YSort/layer as enemy
	(fx as Node2D).global_position = global_position

	var away: Vector2 = (global_position - hit_from).normalized()

	# Case A: FX is GPUParticles2D
	if fx is GPUParticles2D:
		var p: GPUParticles2D = fx
		p.z_as_relative = false
		p.z_index = 100
		p.rotation = away.angle()
		p.emitting = false
		p.emitting = true
		p.finished.connect(fx.queue_free, CONNECT_ONE_SHOT)
		return

	# Case B: FX is Node2D with child "Particles"
	var p2: GPUParticles2D = fx.get_node_or_null("Particles") as GPUParticles2D
	if p2:
		(fx as Node2D).rotation = away.angle()
		p2.z_as_relative = false
		p2.z_index = 100
		p2.emitting = false
		p2.emitting = true
		p2.finished.connect(fx.queue_free, CONNECT_ONE_SHOT)
	else:
		push_warning("Blood FX scene has no GPUParticles2D at root or child named 'Particles'.")
