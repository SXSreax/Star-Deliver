extends CharacterBody2D

# --- config ----------------------------------------------------------------
const SPEED := 180.0
@export var hp: int = 50
@export var chase_radius: float = 420.0      # how far the enemy will chase
@export var attack_range: float = 56.0       # how close to start attack
@export var repath_interval: float = 0.15    # how often to refresh path
@export var attack_offset_x: float = 26.0    # how far hitbox is from body
@export var attack_damage: int = 12
@export var attack_hit_time: float = 0.20    # window where hitbox is active

# --- node refs --------------------------------------------------------------
@onready var player: CharacterBody2D        = $"../Player"
@onready var agent: NavigationAgent2D       = $NavigationAgent2D
@onready var anim: AnimatedSprite2D         = $anim
@onready var timer: Timer                   = $Timer
@onready var attack_area: Area2D            = $AttackArea
@onready var attack_shape: CollisionShape2D = $AttackArea/CollisionShape2D
@onready var hurtbox: Area2D                = $HurtBox

# --- state -----------------------------------------------------------------
var attacking: bool = false
var dead: bool = false
var _repath_acc: float = 0.0
var _facing_left: bool = false
var _threshold: float = 2.0   # distance before stopping path movement

# --- lifecycle --------------------------------------------------------------
func _ready() -> void:
	# If direct player ref failed, try finding by group
	if player == null:
		var p := get_tree().get_first_node_in_group("player")
		if p:
			player = p

	# Ensure correct looping behavior for animations
	if anim.sprite_frames.has_animation("idle"):
		anim.sprite_frames.set_animation_loop("idle", true)
	if anim.sprite_frames.has_animation("run"):
		anim.sprite_frames.set_animation_loop("run", true)
	if anim.sprite_frames.has_animation("attack"):
		anim.sprite_frames.set_animation_loop("attack", false)
	if anim.sprite_frames.has_animation("death"):
		anim.sprite_frames.set_animation_loop("death", false)

	# Setup attack hitbox
	attack_shape.disabled = true
	attack_area.monitoring = true
	attack_area.position.x = attack_offset_x

	# Setup navigation defaults
	agent.avoidance_enabled = false
	agent.path_max_distance = 5000.0
	agent.target_desired_distance = 16.0
	agent.path_desired_distance = 8.0
	if is_instance_valid(player):
		agent.target_position = player.global_position

	# Connect signals
	timer.wait_time = repath_interval
	timer.start()
	if hurtbox.has_signal("body_entered"):
		hurtbox.body_entered.connect(Callable(self, "_on_hurt_box_body_entered"))
	attack_area.body_entered.connect(Callable(self, "_on_attack_area_body_entered"))
	timer.timeout.connect(Callable(self, "_on_timer_timeout"))

	_play_idle()

# --- main loop --------------------------------------------------------------
func _physics_process(delta: float) -> void:
	if dead:
		return

	# refresh path target periodically
	_repath_acc += delta
	if _repath_acc >= repath_interval and is_instance_valid(player):
		_repath_acc = 0.0
		agent.target_position = player.global_position

	# lock movement during attack
	if attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# no player found
	if not is_instance_valid(player):
		velocity = Vector2.ZERO
		_play_idle()
		return

	var dist := global_position.distance_to(player.global_position)

	# attack if in range
	if dist <= attack_range and not attacking:
		var to_player := (player.global_position - global_position).normalized()
		_set_facing_from_vector(to_player)
		_start_attack()
		return

	# otherwise chase if within radius
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

# --- facing & anim ----------------------------------------------------------
func _set_facing_from_vector(dir: Vector2) -> void:
	if abs(dir.x) < 0.001:
		return
	var want_left := dir.x < 0.0
	if want_left != _facing_left:
		_facing_left = want_left
		anim.flip_h = _facing_left
		attack_area.position.x = -attack_offset_x if _facing_left else attack_offset_x

func _play_run() -> void:
	if not (attacking or dead) and anim.animation != "run":
		anim.play("run")

func _play_idle() -> void:
	if not (attacking or dead) and anim.animation != "idle":
		anim.play("idle")

# --- attacking --------------------------------------------------------------
func _start_attack() -> void:
	if attacking or dead:
		return
	attacking = true
	velocity = Vector2.ZERO

	anim.play("attack")

	# turn hitbox on for active window
	_attack_hit_on()
	var off_timer := get_tree().create_timer(attack_hit_time)
	off_timer.timeout.connect(Callable(self, "_attack_hit_off"))

	# end attack when anim finishes
	anim.animation_finished.connect(Callable(self, "_on_attack_anim_finished"), CONNECT_ONE_SHOT)

	# fallback if anim is looped or missing
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

# --- timer -----------------------------------------------------------------
func _on_timer_timeout() -> void:
	if is_instance_valid(player):
		agent.target_position = player.global_position

# --- damage / death --------------------------------------------------------
func take_damage(amount: int) -> void:
	if dead:
		return
	hp -= amount
	Global.add_score(30)
	if hp <= 0:
		_die()

func _on_hurt_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("bullets"):
		take_damage(10)
		Global.add_score(30)

func _die() -> void:
	dead = true
	attacking = false
	velocity = Vector2.ZERO
	anim.play("death")
	await anim.animation_finished
	queue_free()
