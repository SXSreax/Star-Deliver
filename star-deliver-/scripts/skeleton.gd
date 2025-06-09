extends CharacterBody2D

const speed = 200
@onready var player: CharacterBody2D = $"../Player"

@onready var navigation_agent_2d: NavigationAgent2D = $NavigationAgent2D

func makepath() -> void:
	navigation_agent_2d.target_position = player.global_position

func _ready() -> void:
	makepath()

func _physics_process(delta: float) -> void:
	var direction = to_local(navigation_agent_2d.get_next_path_position().normalized())
	velocity = direction * speed
	move_and_slide()


func _on_timer_timeout() -> void:
	makepath() 
