extends CharacterBody2D

# Chases the player when in line-of-sight, takes bullet damage,
# plays a death animation, and spawns blood FX on death.

# --- Constants --------------------------------------------------------------
const RAY_LENGTH: float = 500.0

# --- Editor Config ----------------------------------------------------------
@export var move_speed: float = 75.0
@export var max_hp: int = 50
@export var blood_fx_scene: PackedScene = preload("res://prefabs/fx/blood_burst.tscn")

# --- Node Refs --------------------------------------------------------------
@onready var player: Node2D = $"../Player"
@onready var raycast: RayCast2D = $AnimatedSprite2D/RayCast2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar

# --- State ------------------------------------------------------------------
var hp: int
var is_dead: bool = false
var dir_to_player: Vector2 = Vector2.ZERO
var last_hit_from: Vector2 = Vector2.ZERO  # Remember where the last damage came from


func _ready() -> void:
	# Initialize health and UI.
	hp = max_hp
	health_bar.max_value = max_hp
	health_bar.value = hp


func _physics_process(_delta: float) -> void:
	if is_dead:
		return

	health_bar.value = hp

	# Early-out on death.
	if hp <= 0:
		_die()
		return

	# LOS aims from ray origin so movement matches what the ray sees.
	dir_to_player = (player.global_position - raycast.global_position).normalized()
	raycast.target_position = dir_to_player * RAY_LENGTH

	if raycast.is_colliding():
		var hit: Object = raycast.get_collider()
		if hit != null and hit is Node and (hit as Node).name == "Player":
			velocity = dir_to_player * move_speed
			move_and_slide()
			_update_animation(dir_to_player)
		else:
			velocity = Vector2.ZERO
			move_and_slide()
	else:
		velocity = Vector2.ZERO
		move_and_slide()


# --- Damage / Death ---------------------------------------------------------
# Connect HurtBox Area2D -> body_entered(Node2D).
func _on_hurt_box_body_entered(body: Node2D) -> void:
	if is_dead:
		return
	if body.is_in_group("bullets"):
		last_hit_from = body.global_position
		_apply_damage(10)
		# Optional: body.queue_free()


# For melee/explosions/etc.
func take_damage(amount: int, hit_from: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
	if hit_from != Vector2.ZERO:
		last_hit_from = hit_from
	_apply_damage(amount)


func _apply_damage(amount: int) -> void:
	hp = max(hp - amount, 0)
	Global.add_score(5)
	if hp <= 0:
		_die()


func _die() -> void:
	if is_dead:
		return
	is_dead = true

	# Spray direction preference: last hit → player → self.
	var hit_from: Vector2 = last_hit_from if last_hit_from != Vector2.ZERO \
		else (player.global_position if is_instance_valid(player) else global_position)
	_spawn_blood(hit_from)

	sprite.play("death")
	await sprite.animation_finished
	queue_free()


# --- FX (supports GPUParticles2D at root or Node2D->Particles) -------------
func _spawn_blood(hit_from: Vector2) -> void:
	if blood_fx_scene == null:
		push_warning("blood_fx_scene is null – assign BloodBurst.tscn in the Inspector.")
		return

	var fx: Node = blood_fx_scene.instantiate()
	get_parent().add_child(fx)                 # Same YSort/layer as enemy
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


# --- Animation --------------------------------------------------------------
func _update_animation(direction: Vector2) -> void:
	# Single walk anim, flipped for left/right.
	if abs(direction.x) >= abs(direction.y):
		if sprite.animation != "walk":
			sprite.play("walk")
		sprite.flip_h = direction.x < 0.0
	else:
		if sprite.animation != "walk":
			sprite.play("walk")
		sprite.flip_h = false
