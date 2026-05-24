extends CharacterBody2D

@onready var animated_sprite_2d: AnimatedSprite2D = $FlipContainer/AnimatedSprite2D
@onready var jump_sound: AudioStreamPlayer2D = $JumpSound
@onready var flip_container: Node2D = $FlipContainer

@export var carry_controller: PlayerCarryController
@export var noclip_speed: float = 600.0
@export_range(0.01, 10000.0, 0.01) var base_player_weight: float = 70.0

const SPEED: float = 800.0
const JUMP_VELOCITY: float = -400.0

var godmode_enabled: bool = false


func _ready() -> void:
	BarkManager.set_player(self)

	if carry_controller != null:
		carry_controller.player_base_weight = base_player_weight


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_godmode"):
		godmode_enabled = !godmode_enabled

		set_collision_layer_value(1, not godmode_enabled)
		set_collision_mask_value(1, not godmode_enabled)

		velocity = Vector2.ZERO

		LoggerConsole.log("Godmode: " + str(godmode_enabled))

	if event.is_action_pressed("throw_carried"):
		if carry_controller != null:
			var direction := Vector2(get_facing_direction(), -0.25)
			carry_controller.throw_carried(direction)


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
	var speed_multiplier := get_carry_speed_multiplier()
	var current_speed := SPEED * speed_multiplier

	if absf(velocity.x) > 1.0:
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
		velocity.x = direction * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, current_speed)

	move_and_slide()

	if direction > 0:
		flip_container.scale.x = 1
	elif direction < 0:
		flip_container.scale.x = -1


func get_facing_direction() -> float:
	if flip_container.scale.x < 0.0:
		return -1.0

	return 1.0


func get_carry_speed_multiplier() -> float:
	if carry_controller == null:
		return 1.0

	return carry_controller.get_movement_speed_multiplier()


func get_effective_weight() -> float:
	if carry_controller == null:
		return base_player_weight

	return carry_controller.get_effective_player_weight()
