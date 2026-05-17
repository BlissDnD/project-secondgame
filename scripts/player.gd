extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $FlipContainer/AnimatedSprite2D
@onready var jump_sound: AudioStreamPlayer2D = $JumpSound
@onready var flip_container: Node2D = $FlipContainer

@export var noclip_speed: float = 600.0

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var godmode_enabled: bool = false


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_godmode"):
		godmode_enabled = !godmode_enabled

		set_collision_layer_value(1, not godmode_enabled)
		set_collision_mask_value(1, not godmode_enabled)

		velocity = Vector2.ZERO

		LoggerConsole.log("Godmode: " + str(godmode_enabled))


func _physics_process(delta: float) -> void:
	if godmode_enabled:
		handle_noclip(delta)
		return

	handle_normal_movement(delta)


func handle_noclip(delta: float) -> void:
	var direction := Input.get_vector(
		"ui_left",
		"ui_right",
		"ui_up",
		"ui_down"
	)

	global_position += direction * noclip_speed * delta
	velocity = Vector2.ZERO

	if direction.x > 0:
		flip_container.scale.x = 1
	elif direction.x < 0:
		flip_container.scale.x = -1

	animated_sprite_2d.animation = "idle"


func handle_normal_movement(delta: float) -> void:
	if velocity.x > 1 or velocity.x < -1:
		animated_sprite_2d.animation = "running"
	else:
		animated_sprite_2d.animation = "idle"

	if not is_on_floor():
		velocity += get_gravity() * delta
		animated_sprite_2d.animation = "jump"

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		jump_sound.play()

	var direction := Input.get_axis("ui_left", "ui_right")

	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

	if direction > 0:
		flip_container.scale.x = 1
	elif direction < 0:
		flip_container.scale.x = -1
