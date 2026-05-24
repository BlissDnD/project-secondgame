extends Node
class_name InteractionManager

@export var interaction_area: Area2D
@export var actor: Node2D
@export var active_action_id: StringName = &"hand"
@export var include_carryables: bool = true
@export var player_carry_controller: PlayerCarryController

var nearby_targets: Dictionary = {}
var current_target: Node = null


func _ready() -> void:
	if interaction_area == null:
		push_error("InteractionManager: interaction_area is not assigned.")
		return

	if actor == null:
		push_error("InteractionManager: actor is not assigned.")
		return

	if player_carry_controller == null:
		player_carry_controller = actor.get_node_or_null("PlayerCarryController") as PlayerCarryController

	if not interaction_area.area_entered.is_connected(_on_area_entered):
		interaction_area.area_entered.connect(_on_area_entered)

	if not interaction_area.area_exited.is_connected(_on_area_exited):
		interaction_area.area_exited.connect(_on_area_exited)


func _physics_process(_delta: float) -> void:
	var next_target: Node = get_best_target()
	set_current_target(next_target)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("carry_action"):
		if player_carry_controller != null:
			player_carry_controller.try_interact()
		return

	if event.is_action_pressed("interact"):
		if current_target == null:
			LoggerConsole.log("No interaction target.")
			return

		if current_target is InteractionComponent:
			_use_interaction_component(current_target as InteractionComponent)
			return

		LoggerConsole.log("Target has no interaction action.")


func _on_area_entered(area: Area2D) -> void:
	if area == null:
		return

	var target: Node = _find_target_from_area(area)

	if target == null:
		return

	var root: Node = target.owner

	if root == actor:
		return

	var id: int = target.get_instance_id()

	if nearby_targets.has(id):
		return

	nearby_targets[id] = target


func _on_area_exited(area: Area2D) -> void:
	if area == null:
		return

	var target: Node = _find_target_from_area(area)

	if target == null:
		return

	var id: int = target.get_instance_id()

	if nearby_targets.has(id):
		nearby_targets.erase(id)

	if current_target == target:
		_set_target_highlighted(current_target, false)
		current_target = null


func get_best_target() -> Node:
	var hovered: Node = get_hovered_target()

	if hovered != null:
		return hovered

	return get_closest_target()


func get_hovered_target() -> Node:
	if actor == null:
		return null

	var mouse_pos: Vector2 = actor.get_global_mouse_position()

	for item in nearby_targets.values():
		var target: Node = item as Node

		if not _is_valid_target(target):
			continue

		if _is_mouse_over_target(target, mouse_pos):
			return target

	return null


func get_closest_target() -> Node:
	var closest: Node = null
	var closest_distance: float = INF

	if actor == null:
		return null

	for item in nearby_targets.values():
		var target: Node = item as Node

		if not _is_valid_target(target):
			continue

		var target_root: Node2D = _get_target_root(target)

		if target_root == null:
			continue

		var distance: float = actor.global_position.distance_to(target_root.global_position)

		if distance < closest_distance:
			closest_distance = distance
			closest = target

	return closest


func set_current_target(next_target: Node) -> void:
	if current_target == next_target:
		return

	if current_target != null and is_instance_valid(current_target):
		_set_target_highlighted(current_target, false)

	current_target = next_target

	if current_target != null and is_instance_valid(current_target):
		_set_target_highlighted(current_target, true)


func _use_interaction_component(component: InteractionComponent) -> void:
	var owner_node: Node = component.owner

	if owner_node != null and owner_node.has_method("interact"):
		owner_node.interact(actor)
		return

	if component.has_action(active_action_id):
		component.execute_action(active_action_id, actor)
		return

	if component.has_action(&"hand"):
		component.execute_action(&"hand", actor)
		return

	LoggerConsole.log("Target has no usable action.")


func _find_target_from_area(area: Area2D) -> Node:
	var root: Node = area.owner

	if root == null:
		root = area

	var interaction_component: InteractionComponent = _find_interaction_component(root)

	if interaction_component != null:
		return interaction_component

	if include_carryables:
		var carryable_component: CarryableComponent = _find_carryable_component(root)

		if carryable_component != null:
			return carryable_component

	return null


func _is_valid_target(target: Node) -> bool:
	if target == null:
		return false

	if not is_instance_valid(target):
		return false

	if target is InteractionComponent:
		return (target as InteractionComponent).can_interact()

	if include_carryables and target is CarryableComponent:
		return (target as CarryableComponent).can_carry()

	return false


func _get_target_root(target: Node) -> Node2D:
	if target is InteractionComponent:
		return target.owner as Node2D

	if target is CarryableComponent:
		return (target as CarryableComponent).get_carried_root()

	return target.owner as Node2D


func _is_mouse_over_target(target: Node, mouse_pos: Vector2) -> bool:
	if target is InteractionComponent:
		var interaction_component := target as InteractionComponent

		if interaction_component.hover_area != null:
			return _is_mouse_over_area(interaction_component.hover_area, mouse_pos)

		var owner_node := interaction_component.owner as Node2D

		if owner_node == null:
			return false

		return owner_node.global_position.distance_to(mouse_pos) <= interaction_component.hover_radius_px

	if target is CarryableComponent:
		var carryable_component := target as CarryableComponent
		return _is_mouse_over_area(carryable_component, mouse_pos)

	return false


func _is_mouse_over_area(area: Area2D, mouse_pos: Vector2) -> bool:
	for child in area.get_children():
		if child is CollisionShape2D:
			var collision_shape := child as CollisionShape2D
			var shape: Shape2D = collision_shape.shape

			if shape == null:
				continue

			var local_mouse_shape: Vector2 = collision_shape.to_local(mouse_pos)

			if shape is RectangleShape2D:
				var rectangle := shape as RectangleShape2D
				var half_size: Vector2 = rectangle.size * 0.5

				if absf(local_mouse_shape.x) <= half_size.x and absf(local_mouse_shape.y) <= half_size.y:
					return true

			if shape is CircleShape2D:
				var circle := shape as CircleShape2D

				if local_mouse_shape.length() <= circle.radius:
					return true

	return false


func _set_target_highlighted(target: Node, value: bool) -> void:
	if target == null:
		return

	if target is InteractionComponent:
		(target as InteractionComponent).set_highlighted(value)
		return

	if target is CarryableComponent:
		(target as CarryableComponent).set_highlighted(value)
		return


func _find_interaction_component(node: Node) -> InteractionComponent:
	if node == null:
		return null

	if node is InteractionComponent:
		return node as InteractionComponent

	for child in node.get_children():
		var found := _find_interaction_component(child)

		if found != null:
			return found

	return null


func _find_carryable_component(node: Node) -> CarryableComponent:
	if node == null:
		return null

	if node is CarryableComponent:
		return node as CarryableComponent

	for child in node.get_children():
		var found := _find_carryable_component(child)

		if found != null:
			return found

	return null
