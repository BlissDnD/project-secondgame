extends CharacterBody2D

# Fix: Path updated to look INSIDE the FlipContainer
@onready var animated_sprite_2d: AnimatedSprite2D = $FlipContainer/AnimatedSprite2D
@onready var jump_sound: AudioStreamPlayer2D = $JumpSound
# Fix: Type changed from Node to Node2D so we can use scale
@onready var flip_container: Node2D = $FlipContainer

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

func _physics_process(delta: float) -> void:
	# Add animations.
	if velocity.x > 1 or velocity.x < -1:
		animated_sprite_2d.animation = "running"
	else:
		animated_sprite_2d.animation = "idle"

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		animated_sprite_2d.animation = "jump"

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		jump_sound.play()

	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
	
	# Fix: Removed flip_h entirely. Scaling the container flips everything inside it at once.
	if direction > 0:
		flip_container.scale.x = 1   # Faces right
	elif direction < 0:
		flip_container.scale.x = -1  # Faces left
