extends CharacterBody2D

@onready var player = $"../Player"
@onready var raycast: RayCast2D = $AnimatedSprite2D/RayCast2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var health_bar: ProgressBar = $HealthBar

var speed = 75
var hp = 30

func _physics_process(delta: float) -> void:
	health_bar.value = hp
	if hp == 0 or hp < 0:
		queue_free()  # Remove the enemy if health reaches zero
	
	var direction = (player.global_position - raycast.global_position).normalized()
	var length = 500
	raycast.target_position = direction * length 
	update_animation(direction)

	if raycast.is_colliding(): 
		var collider = raycast.get_collider()
		if collider != null:
			var collider_name = collider.name
			if collider_name == "Player":
				velocity = direction * speed
				move_and_slide()


func _on_hurt_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("bullets"):
		hp -= 10  # Reduce health when hit by a bullet
		Global.add_score(5)
		
func take_damage(amount):
	hp -= amount  # Custom damage function
	Global.add_score(5)

# Play walking animation based on movement direction
func update_animation(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		# Moving left or right → side animation
		sprite.play("Running")
		sprite.flip_h = dir.x < 0  # Excellence: horizontal flip based on direction
	elif dir.y < 0:
		# Moving upward
		sprite.play("Running")
		sprite.flip_h = false
	elif dir.y > 0:
		# Moving downward
		sprite.play("Running")
		sprite.flip_h = false
