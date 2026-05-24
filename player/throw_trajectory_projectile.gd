extends Line2D
class_name ThrowTrajectoryPreview

@export var player: CharacterBody2D
@export var carry_controller: PlayerCarryController

@export_range(8, 256, 1) var simulation_steps: int = 64
@export_range(0.001, 0.1, 0.001) var simulation_step_time: float = 0.03
@export_range(0.0, 10000.0, 1.0) var max_draw_distance: float = 4000.0

@export var show_only_while_carrying: bool = true

@export_group("Visual")
@export var line_width: float = 3.0
@export var min_charge_color: Color = Color(1.0, 1.0, 1.0, 0.75)
@export var max_charge_color: Color = Color(1.0, 0.05, 0.02, 0.95)

@export_group("Collision")
@export var stop_on_collision: bool = true
@export_flags_2d_physics var collision_mask: int = 1

var _space_state: PhysicsDirectSpaceState2D


func _ready() -> void:
	width = line_width
	default_color = min_charge_color
	top_level = true
	_space_state = get_world_2d().direct_space_state


func _process(_delta: float) -> void:
	if player == null or carry_controller == null:
		visible = false
		clear_points()
		return

	if show_only_while_carrying and not carry_controller.is_carrying():
		visible = false
		clear_points()
		return

	visible = true
	_update_visual_charge_color()
	_update_trajectory()


func _update_visual_charge_color() -> void:
	var charge := carry_controller.get_throw_charge()

	if not carry_controller.is_charging_throw():
		charge = 0.0

	default_color = min_charge_color.lerp(max_charge_color, charge)


func _update_trajectory() -> void:
	clear_points()

	var carried := carry_controller.carried_component
	if carried == null:
		return

	var throw_origin := player.global_position + carry_controller.hold_offset
	var mouse_position := player.get_global_mouse_position()
	var throw_direction := mouse_position - throw_origin

	if throw_direction.length() <= 1.0:
		return

	throw_direction = throw_direction.normalized()

	var initial_velocity := carry_controller.get_max_throw_velocity_for_direction(
		throw_direction
	)

	var gravity_scale: float = 1.0
	var physical_body := carried.root_node as PhysicalItemBody

	if physical_body != null and physical_body.profile != null:
		gravity_scale = physical_body.profile.gravity_scale

	var gravity := float(ProjectSettings.get_setting("physics/2d/default_gravity"))

	var current_position := throw_origin
	var current_velocity := initial_velocity

	add_point(current_position)

	var travelled_distance: float = 0.0

	for i in range(simulation_steps):
		var previous_position := current_position

		current_velocity.y += gravity * gravity_scale * simulation_step_time
		current_position += current_velocity * simulation_step_time

		travelled_distance += previous_position.distance_to(current_position)

		if travelled_distance > max_draw_distance:
			break

		if stop_on_collision:
			var hit_result: Dictionary = _check_collision(
				previous_position,
				current_position
			)

			if not hit_result.is_empty():
				add_point(hit_result.position)
				break

		add_point(current_position)


func _check_collision(from: Vector2, to: Vector2) -> Dictionary:
	var query := PhysicsRayQueryParameters2D.create(from, to)

	query.collision_mask = collision_mask
	query.collide_with_areas = false
	query.collide_with_bodies = true

	return _space_state.intersect_ray(query)
