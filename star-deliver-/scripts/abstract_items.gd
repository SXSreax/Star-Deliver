extends Sprite2D

@onready var collision: CollisionShape2D = $Area2D/CollisionShape2D

@export var stats : Item

func _ready() -> void:
	if stats != null:
		texture = stats.icon


func _on_player_entered(body: Node2D) -> void:
	call_deferred("reparent", body.find_child("Weapons"))
	position = body.position
	body.add_items(stats)
	collision.call_deferred("set_disabled", true)
