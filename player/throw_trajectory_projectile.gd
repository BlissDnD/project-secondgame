extends Line2D
class_name ThrowTrajectoryPreview

@export var player: CharacterBody2D
@export var carry_controller: PlayerCarryController

@export_range(8, 512, 1) var simulation_steps: int = 160
@export var use_project_physics_step: bool = true
@export_range(0.001, 0.1, 0.001) var custom_simulation_step_time: float = 0.0125
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


func _physics_process(_delta: float) -> void:
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

	var mouse_position := player.get_global_mouse_position()
	var current_position := carry_controller.get_throw_origin()
	var throw_direction := mouse_position - current_position

	if throw_direction.length() <= 1.0:
		return

	var current_velocity := carry_controller.get_preview_throw_velocity_for_mouse(
		mouse_position
	)

	if current_velocity.length() <= 0.0:
		return

	var gravity := _get_gravity_for_carried(carried)
	var step_time := _get_simulation_step_time()

	add_point(current_position)

	var travelled_distance: float = 0.0

	for i in range(simulation_steps):
		var previous_position := current_position

		current_velocity += gravity * step_time
		current_position += current_velocity * step_time

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


func _get_simulation_step_time() -> float:
	if use_project_physics_step:
		return 1.0 / float(Engine.physics_ticks_per_second)

	return custom_simulation_step_time


func _get_gravity_for_carried(carried: CarryableComponent) -> Vector2:
	var carried_root := carried.get_carried_root()
	var external_motion := _find_external_motion_component(carried_root)

	if external_motion != null:
		return external_motion.get_prediction_gravity()

	var physical_body := carried_root as PhysicalItemBody

	if physical_body != null and physical_body.profile != null:
		var gravity_value := float(ProjectSettings.get_setting("physics/2d/default_gravity"))
		var gravity_vector := ProjectSettings.get_setting("physics/2d/default_gravity_vector") as Vector2
		return gravity_vector.normalized() * gravity_value * physical_body.profile.gravity_scale

	return player.get_gravity()


func _check_collision(from: Vector2, to: Vector2) -> Dictionary:
	var query := PhysicsRayQueryParameters2D.create(from, to)

	query.collision_mask = collision_mask
	query.collide_with_areas = false
	query.collide_with_bodies = true

	return _space_state.intersect_ray(query)


func _find_external_motion_component(node: Node) -> WorkerExternalMotionComponent:
	if node == null:
		return null

	if node is WorkerExternalMotionComponent:
		return node as WorkerExternalMotionComponent

	for child in node.get_children():
		var found := _find_external_motion_component(child)

		if found != null:
			return found

	return null
