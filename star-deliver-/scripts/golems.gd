extends CharacterBody2D

# ---------- Config ----------
const SPEED := 180.0
@export var hp: int = 50
@export var chase_radius: float = 420.0
@export var attack_range: float = 56.0
@export var repath_interval: float = 0.15
@export var attack_offset_x: float = 26.0
@export var attack_damage: int = 12
@export var attack_hit_time: float = 0.20     # active hitbox window

# ---------- Nodes ----------
@onready var player: CharacterBody2D        = $"../Player"
@onready var agent: NavigationAgent2D       = $NavigationAgent2D
@onready var timer: Timer                   = $Timer
@onready var attack_area: Area2D            = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var hurtbox: Area2D                = $HurtBox
@onready var anim: AnimatedSprite2D         = $Anim

# ---------- State ----------
var attacking := false
var dead := false
var _repath_acc := 0.0
var _facing_left := false
var _threshold := 2.0

# ---------- Blood FX (ADDED) ----------
@export var blood_fx_scene: PackedScene = preload("res://prefabs/fx/blood_burst.tscn")
var _last_hit_from: Vector2 = Vector2.ZERO
# -------------------------------------

func _ready() -> void:
	# Fallback to group if the path doesn't find the player
	if player == null:
		var p := get_tree().get_first_node_in_group("player")
		if p:
			player = p

	# Ensure animation loop flags (important!)
	if anim.sprite_frames.has_animation("idle"):
		anim.sprite_frames.set_animation_loop("idle", true)
	if anim.sprite_frames.has_animation("walk"):
		anim.sprite_frames.set_animation_loop("walk", true)
	if anim.sprite_frames.has_animation("attack"):
		anim.sprite_frames.set_animation_loop("attack", false)
	if anim.sprite_frames.has_animation("death"):
		anim.sprite_frames.set_animation_loop("death", false)

	# Hitbox setup
	attack_shape.disabled = true
	attack_area.monitoring = true
	attack_area.position.x = attack_offset_x

	# Agent defaults
	agent.avoidance_enabled = false
	agent.path_max_distance = 5000.0
	agent.target_desired_distance = 16.0
	agent.path_desired_distance = 8.0
	if is_instance_valid(player):
		agent.target_position = player.global_position

	# Signals
	timer.wait_time = repath_interval
	timer.start()
	if hurtbox.has_signal("body_entered"):
		hurtbox.body_entered.connect(Callable(self, "_on_hurt_box_body_entered"))
	attack_area.body_entered.connect(Callable(self, "_on_attack_area_body_entered"))
	timer.timeout.connect(Callable(self, "_on_timer_timeout"))

	_play_idle()

func _physics_process(delta: float) -> void:
	if dead: return

	_repath_acc += delta
	if _repath_acc >= repath_interval and is_instance_valid(player):
		_repath_acc = 0.0
		agent.target_position = player.global_position

	if attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		_play_idle()
		return

	var dist := global_position.distance_to(player.global_position)

	# Start attack in range
	if dist <= attack_range and not attacking:
		var to_player := (player.global_position - global_position).normalized()
		_set_facing_from_vector(to_player)
		_start_attack()
		return

	# Chase
	if dist <= chase_radius:
		var next_pos := agent.get_next_path_position()
		var dir := next_pos - global_position
		if agent.is_navigation_finished() or dir.length() <= _threshold:
			dir = player.global_position - global_position

		if dir.length() > _threshold:
			var move_dir := dir.normalized()
			velocity = move_dir * SPEED
			move_and_slide()
			_set_facing_from_vector(move_dir)
			_play_run()
		else:
			velocity = Vector2.ZERO
			_play_idle()
	else:
		velocity = Vector2.ZERO
		_play_idle()

# ---------- Facing & Anim ----------
func _set_facing_from_vector(dir: Vector2) -> void:
	if abs(dir.x) < 0.001: return
	var want_left := dir.x < 0.0
	if want_left != _facing_left:
		_facing_left = want_left
		anim.flip_h = _facing_left
		attack_area.position.x = (-attack_offset_x) if _facing_left else attack_offset_x

func _play_run() -> void:
	if attacking or dead: return
	if anim.animation != "walk":
		anim.play("walk")

func _play_idle() -> void:
	if attacking or dead: return
	if anim.animation != "idle":
		anim.play("idle")

# ---------- Attacking ----------
func _start_attack() -> void:
	if attacking or dead: return
	attacking = true
	velocity = Vector2.ZERO

	# start attack anim
	anim.play("attack")

	# enable hitbox during active window
	_attack_hit_on()
	var off_timer := get_tree().create_timer(attack_hit_time)
	off_timer.timeout.connect(Callable(self, "_attack_hit_off"))

	# end-of-anim -> exit attack
	anim.animation_finished.connect(Callable(self, "_on_attack_anim_finished"), CONNECT_ONE_SHOT)

	# SAFETY: fallback in case the attack clip is (accidentally) looping
	var total := _anim_duration("attack")
	if total <= 0.0:
		total = attack_hit_time + 0.15
	var fallback := get_tree().create_timer(total + 0.05)
	fallback.timeout.connect(Callable(self, "_attack_finish_fallback"), CONNECT_ONE_SHOT)

func _anim_duration(name: String) -> float:
	if not anim.sprite_frames.has_animation(name):
		return 0.0
	var frames := anim.sprite_frames.get_frame_count(name)
	var fps := float(anim.sprite_frames.get_animation_speed(name))
	if fps <= 0.0:
		fps = 10.0
	return frames / (fps * max(anim.speed_scale, 0.001))

func _attack_finish_fallback() -> void:
	if attacking:
		_on_attack_anim_finished()

func _on_attack_anim_finished() -> void:
	attacking = false
	_play_idle()

func _attack_hit_on() -> void:
	attack_shape.disabled = false
	for b in attack_area.get_overlapping_bodies():
		_try_damage_player(b)

func _attack_hit_off() -> void:
	attack_shape.disabled = true

func _on_attack_area_body_entered(body: Node2D) -> void:
	if not attack_shape.disabled:
		_try_damage_player(body)

func _try_damage_player(body: Node2D) -> void:
	if body.name == "Player" or body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.call("take_damage", attack_damage)

# ---------- Timer ----------
func _on_timer_timeout() -> void:
	if is_instance_valid(player):
		agent.target_position = player.global_position

# ---------- Damage / Death ----------
func take_damage(amount: int) -> void:
	if dead: return
	hp -= amount
	Global.add_score(30)
	if hp <= 0:
		_die()

func _on_hurt_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("bullets"):
		_last_hit_from = body.global_position  # (ADDED) remember last impact source
		take_damage(10)
		Global.add_score(30)

func _die() -> void:
	dead = true
	attacking = false
	velocity = Vector2.ZERO

	# --- spawn blood once, just before death anim (ADDED) ---
	var hit_from := _last_hit_from if _last_hit_from != Vector2.ZERO \
		else (player.global_position if is_instance_valid(player) else global_position)
	_spawn_blood(hit_from)
	# --------------------------------------------------------

	anim.play("death")
	await anim.animation_finished
	queue_free()

# ---------- Blood FX helper (ADDED) ----------
func _spawn_blood(hit_from: Vector2) -> void:
	if blood_fx_scene == null:
		push_warning("blood_fx_scene is null – assign BloodBurst.tscn in the Inspector.")
		return

	var fx := blood_fx_scene.instantiate()
	get_parent().add_child(fx)                 # same layer/YSort as enemy
	fx.global_position = global_position

	var away := (global_position - hit_from).normalized()

	# Root is GPUParticles2D?
	if fx is GPUParticles2D:
		var p := fx as GPUParticles2D
		p.z_as_relative = false
		p.z_index = 100
		p.rotation = away.angle()
		p.emitting = false
		p.emitting = true
		p.finished.connect(fx.queue_free, CONNECT_ONE_SHOT)
		return

	# Root is Node2D with child "Particles" (GPUParticles2D)?
	var p2 := fx.get_node_or_null("Particles") as GPUParticles2D
	if p2:
		fx.rotation = away.angle()
		p2.z_as_relative = false
		p2.z_index = 100
		p2.emitting = false
		p2.emitting = true
		p2.finished.connect(fx.queue_free, CONNECT_ONE_SHOT)
	else:
		push_warning("Blood FX scene has no GPUParticles2D at root or child named 'Particles'.")
