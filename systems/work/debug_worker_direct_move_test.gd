extends CharacterBody2D

@export var move_speed: float = 60.0
@export var gravity: float = 980.0
@export var direction: int = 1

func _ready() -> void:
	print("DIRECT MOVE TEST READY on: ", name)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta

	velocity.x = direction * move_speed
	move_and_slide()

	print("moving test velocity=", velocity, " pos=", global_position)
