extends CharacterBody2D

# Movement tuning.
const SPEED: float = 150.0                    # Enemy move speed (px/s).
var threshold: float = 2.0                    # Stop distance to next nav point.

# Simple stats/state.
var hp: int = 50
var follow: bool = false
var attacking: bool = false
var death: bool = false

# Scene references (cached for performance/readability).
@onready var player: CharacterBody2D = $"../Player"
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar

# Blood FX configuration.
@export var blood_fx_scene: PackedScene = preload("res://prefabs/fx/blood_burst.tscn")
var last_hit_from: Vector2 = Vector2.ZERO


func _ready() -> void:
	# Start by targeting the player; optionally tag this node for group ops.
	navigation_agent_2d.target_position = player.global_position
	add_to_group("bullets")  # Keep only if you really want enemies in this group.


func make_path() -> void:
	# Recompute the path toward the player’s current position.
	navigation_agent_2d.target_position = player.global_position


func _physics_process(delta: float) -> void:
	# Keep UI in sync with health.
	health_bar.value = hp

	# Lock movement while attacking or dying.
	if attacking or death:
		velocity = Vector2.ZERO
		return

	if follow:
		var next_pos: Vector2 = navigation_agent_2d.get_next_path_position()
		var to_next: Vector2 = next_pos - global_position

		if to_next.length() > threshold:
			var move_dir: Vector2 = to_next.normalized()
			velocity = move_dir * SPEED
			move_and_slide()
			# Use relative vector to face the player as you walk.
			update_animation(player.global_position - global_position)
		else:
			velocity = Vector2.ZERO
			sprite.play("idle")
	else:
		velocity = Vector2.ZERO
		sprite.play("idle")


func update_animation(move_dir: Vector2) -> void:
	# Avoid animation swaps while busy with attack/death.
	if attacking or death:
		return

	if sprite.animation != "walk":
		sprite.play("walk")

	# Flip horizontally when X motion dominates (simple facing logic).
	if abs(move_dir.x) > abs(move_dir.y):
		sprite.flip_h = move_dir.x < 0.0
	else:
		sprite.flip_h = false


func _on_timer_timeout() -> void:
	# Periodic path refresh (via a Timer).
	make_path()


func _on_attack_area_body_entered(body: Node2D) -> void:
	# Entered melee range—begin the attack sequence.
	if body.name == "Player" and not attacking:
		attacking = true
		sprite.play("attack")


func _on_animated_sprite_2d_animation_finished() -> void:
	# After attack, resume pursuit smoothly.
	if sprite.animation == "attack":
		attacking = false
		make_path()

		var next_pos: Vector2 = navigation_agent_2d.get_next_path_position()
		var to_next: Vector2 = next_pos - global_position
		if to_next.length() > threshold:
			var move_dir: Vector2 = to_next.normalized()
			velocity = move_dir * SPEED
			update_animation(move_dir)


func _on_attack_area_body_exited(body: Node2D) -> void:
	# Left melee range—stop attacking.
	if body.name == "Player":
		attacking = false


func die() -> void:
	# Death sequence: spawn FX, play anim, free.
	if death:
		# Choose a reasonable origin for the blood spray:
		# 1) Last bullet hit position if known, else
		# 2) Player position if valid, else
		# 3) Self position as a fallback.
		var hit_from: Vector2 = (
			last_hit_from
			if last_hit_from != Vector2.ZERO
			else (player.global_position if is_instance_valid(player) else global_position)
		)

		_spawn_blood(hit_from)

		sprite.play("dying")
		await sprite.animation_finished
		queue_free()


func detect_death() -> void:
	# Centralized death check so all damage paths behave the same.
	if hp <= 0 and not death:
		print("Enemy dead")
		death = true
		die()


func _on_hurt_box_body_entered(body: Node2D) -> void:
	# Bullet collision → apply damage and score once per hit.
	if body.is_in_group("bullets"):
		last_hit_from = body.global_position
		hp -= 10
		Global.add_score(10)
		print("Hit! HP:", hp)
		detect_death()


func take_damage(amount: int) -> void:
	# Generic damage hook for melee/projectiles/spells.
	hp -= amount
	detect_death()
	Global.add_score(10)


func _on_detection_body_entered(body: Node2D) -> void:
	# Player seen—begin following.
	if body.name == "Player":
		follow = true


func _on_detection_body_exited(body: Node2D) -> void:
	# Player lost—stop following.
	if body.name == "Player":
		follow = false


func _spawn_blood(hit_from: Vector2) -> void:
	# Spawns a one-shot particle burst, angled away from the hit origin.
	if blood_fx_scene == null:
		push_warning("blood_fx_scene is null – assign BloodBurst.tscn in the Inspector.")
		return

	var fx: Node = blood_fx_scene.instantiate()
	get_parent().add_child(fx)  # Keep layering consistent with enemy’s parent.
	(fx as Node2D).global_position = global_position

	var away: Vector2 = (global_position - hit_from).normalized()

	# Root is GPUParticles2D.
	if fx is GPUParticles2D:
		var p := fx as GPUParticles2D
		p.z_as_relative = false
		p.z_index = max(sprite.z_index + 1, 1)
		p.rotation = away.angle()
		p.emitting = false
		p.emitting = true
		p.finished.connect(fx.queue_free, CONNECT_ONE_SHOT)
		return

	# Root is Node2D with child "Particles" (GPUParticles2D).
	var p2: GPUParticles2D = fx.get_node_or_null("Particles") as GPUParticles2D
	if p2:
		(fx as Node2D).rotation = away.angle()
		p2.z_as_relative = false
		p2.z_index = max(sprite.z_index + 1, 1)
		p2.emitting = false
		p2.emitting = true
		p2.finished.connect(fx.queue_free, CONNECT_ONE_SHOT)
	else:
		push_warning("Blood FX scene has no GPUParticles2D at root or child named 'Particles'.")
