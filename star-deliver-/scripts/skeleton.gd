extends CharacterBody2D

# Enemy movement speed
const SPEED: float = 100.0

# References to necessary nodes
@onready var player: CharacterBody2D         = $"../Player"
@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D
@onready var sprite: AnimatedSprite2D        = $AnimatedSprite2D
@onready var health_bar: ProgressBar         = $HealthBar

# Enemy stats/state
var hp: int = 75
var follow: bool = false
var threshold: float = 2.0       # Min distance to path target before stopping
var attacking: bool = false
var death: bool = false

# Blood FX
@export var blood_fx_scene: PackedScene = preload("res://prefabs/fx/blood_burst.tscn")
var last_hit_from: Vector2 = Vector2.ZERO


func _ready() -> void:
	# Set initial path target and join group for collision tracking
	navigation_agent_2d.target_position = player.global_position
	add_to_group("bullets")


func make_path() -> void:
	# Refresh path to player's current location
	navigation_agent_2d.target_position = player.global_position


func _physics_process(delta: float) -> void:
	health_bar.value = hp

	# Freeze while attacking
	if attacking:
		velocity = Vector2.ZERO
		return

	# Follow only when detected
	if follow:
		var next_pos: Vector2 = navigation_agent_2d.get_next_path_position()
		var direction: Vector2 = next_pos - global_position

		if direction.length() > threshold:
			var move_dir: Vector2 = direction.normalized()
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
	# Avoid switches while attacking or dead
	if attacking or death:
		return

	if sprite.animation != "walk":
		sprite.play("walk")

	# Face left/right based on dominant X movement
	if abs(move_dir.x) > abs(move_dir.y):
		sprite.flip_h = move_dir.x < 0.0
	else:
		sprite.flip_h = false


func _on_timer_timeout() -> void:
	# Periodically update path
	make_path()


func _on_attack_area_body_entered(body: Node2D) -> void:
	# Begin attack when player enters range
	if body.name == "Player" and not attacking:
		attacking = true
		sprite.play("attack")


func _on_animated_sprite_2d_animation_finished() -> void:
	# After attack, resume chase immediately
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
	# Stop attack state when player leaves
	if body.name == "Player":
		attacking = false


func die() -> void:
	if death:
		# Spawn blood just before death animation
		var hit_from: Vector2 = (
			last_hit_from if last_hit_from != Vector2.ZERO
			else (player.global_position if is_instance_valid(player) else global_position)
		)
		_spawn_blood(hit_from)

		sprite.play("death")
		await sprite.animation_finished
		queue_free()  # Remove enemy after death


func detect_death() -> void:
	if hp <= 0:
		print("Enemy dead")
		death = true
		die()


func _on_hurt_box_body_entered(body: Node2D) -> void:
	# Bullet collision → take damage and check death
	if body.is_in_group("bullets"):
		last_hit_from = body.global_position
		hp -= 10
		print("Hit! HP:", hp)
		detect_death()
		Global.add_score(10)


func take_damage(amount: int) -> void:
	# External damage hook
	hp -= amount
	detect_death()
	Global.add_score(10)


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

	var fx: Node = blood_fx_scene.instantiate()
	get_parent().add_child(fx)             # Same layer/YSort as enemy
	(fx as Node2D).global_position = global_position

	var away: Vector2 = (global_position - hit_from).normalized()

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

	# Root is Node2D with child "Particles" (GPUParticles2D)
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
