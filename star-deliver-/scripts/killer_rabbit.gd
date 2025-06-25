extends CharacterBody2D

@onready var player = $"../Player"
@onready var raycast: RayCast2D = $AnimatedSprite2D/RayCast2D

var speed = 75
var hp = 30

func _physics_process(delta: float) -> void:
	if hp == 0:
		queue_free()
	
	var direction = (player.global_position - raycast.global_position).normalized()
	var length = 500  # Set your desired ray length here
	raycast.target_position = direction * length 
	
	if raycast.is_colliding(): 
		var collider = raycast.get_collider()
		if collider != null:
			var collider_name = collider.name # Gets the collider name
			# If the collider name is equal to the player, moves
			if collider_name == "Player":
				velocity = direction * speed
				move_and_slide()


func _on_hurt_box_body_entered(body: Node2D) -> void:
	if body.is_in_group("bullets"):
		hp -= 10
