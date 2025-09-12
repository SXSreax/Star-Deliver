extends CharacterBody2D

# --- constants --------------------------------------------------------------
const RAY_LENGTH: float = 500.0

# --- editor config ----------------------------------------------------------
@export var move_speed: float = 75.0
@export var max_hp: int = 30
@export var blood_fx_scene: PackedScene = preload("res://prefabs/fx/blood_burst.tscn")

# --- node refs --------------------------------------------------------------
@onready var player: Node2D = $"../Player"
@onready var raycast: RayCast2D = $AnimatedSprite2D/RayCast2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar

# --- state ------------------------------------------------------------------
var hp: int
var is_dead: bool = false
var last_hit_from: Vector2 = Vector2.ZERO

# --- lifecycle --------------------------------------------------------------
func _ready() -> void:
	hp = max_hp
	health_bar.max_value = max_hp
	health_bar.value = hp

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	health_bar.value = hp

	# death gate — spawns FX then frees
	if hp <= 0:
		_die()
		return

	# LOS + chase
	var direction: Vector2 = (player.global_position - raycast.global_position).normalized()
	raycast.target_position = direction * RAY_LENGTH
	update_animation(direction)

	if raycast.is_colliding():
		var collider := raycast.get_collider()
		if collider != null and collider.name == "Player":
			velocity = direction * move_speed
			move_and_slide()
		else:
			velocity = Vector2.ZERO
			move_and_slide()
	else:
		velocity = Vector2.ZERO
		move_and_slide()

# --- damage / death ---------------------------------------------------------
func _on_hurt_box_body_entered(body: Node2D) -> void:
	if is_dead:
		return
	if body.is_in_group("bullets"):
		last_hit_from = body.global_position
		hp -= 10
		Global.add_score(5)

func take_damage(amount: int, hit_from: Vector2 = Vector2.ZERO) -> void:
	if is_dead:
		return
	if hit_from != Vector2.ZERO:
		last_hit_from = hit_from
	hp -= amount
	Global.add_score(5)

func _die() -> void:
	if is_dead:
		return
	is_dead = true

	# Choose spray direction: last hit → player → self
	var hit_from: Vector2 = last_hit_from if last_hit_from != Vector2.ZERO \
		else (player.global_position if is_instance_valid(player) else global_position)
	_spawn_blood(hit_from)

	# If you have a death anim, play it here; else free immediately
	# sprite.play("Death"); await sprite.animation_finished
	queue_free()

# --- fx ---------------------------------------------------------------------
func _spawn_blood(hit_from: Vector2) -> void:
	if blood_fx_scene == null:
		push_warning("blood_fx_scene is null – assign BloodBurst.tscn in the Inspector.")
		return

	var fx := blood_fx_scene.instantiate()
	get_parent().add_child(fx)              # same layer/YSort as enemy
	fx.global_position = global_position

	var away: Vector2 = (global_position - hit_from).normalized()

	# Case A: FX root is GPUParticles2D
	if fx is GPUParticles2D:
		var p: GPUParticles2D = fx
		p.z_as_relative = false
		p.z_index = max(sprite.z_index + 1, 1)  # render above
		p.rotation = away.angle()
		p.emitting = false
		p.emitting = true
		p.finished.connect(fx.queue_free, CONNECT_ONE_SHOT)
		return

	# Case B: FX root is Node2D with child "Particles" (GPUParticles2D)
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

# --- animation --------------------------------------------------------------
func update_animation(dir: Vector2) -> void:
	# Uses a single "Running" anim, flipped for left/right.
	if abs(dir.x) > abs(dir.y):
		sprite.play("Running")
		sprite.flip_h = dir.x < 0
	elif dir.y < 0:
		sprite.play("Running")
		sprite.flip_h = false
	elif dir.y > 0:
		sprite.play("Running")
		sprite.flip_h = false
