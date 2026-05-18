extends Node

@export var interaction_area: Area2D
@export var actor: Node2D
@export var active_action_id: StringName = &"hand"

var nearby_components: Dictionary = {}
var current_target: InteractionComponent = null


func _ready() -> void:
	if interaction_area == null:
		push_error("InteractionManager: interaction_area is not assigned.")
		return

	if actor == null:
		push_error("InteractionManager: actor is not assigned.")
		return

	if not interaction_area.area_entered.is_connected(_on_area_entered):
		interaction_area.area_entered.connect(_on_area_entered)

	if not interaction_area.area_exited.is_connected(_on_area_exited):
		interaction_area.area_exited.connect(_on_area_exited)


func _physics_process(_delta: float) -> void:
	var next_target: InteractionComponent = get_best_target()
	set_current_target(next_target)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if current_target == null:
			LoggerConsole.log("No interaction target.")
			return

		var owner_node: Node = current_target.owner

		if owner_node != null and owner_node.has_method("interact"):
			owner_node.interact(actor)
			return

		if current_target.has_action(active_action_id):
			current_target.execute_action(active_action_id, actor)
			return

		if current_target.has_action(&"hand"):
			current_target.execute_action(&"hand", actor)
			return

		LoggerConsole.log("Target has no usable action.")


func _on_area_entered(area: Area2D) -> void:
	var root: Node = area.owner

	if root == null:
		return

	if root == actor:
		return

	var component: InteractionComponent = find_interaction_component(root)

	if component == null:
		return

	if not is_valid_target(component):
		return

	var id: int = component.get_instance_id()

	if nearby_components.has(id):
		return

	nearby_components[id] = component
	LoggerConsole.log("Added interaction target: " + root.name)


func _on_area_exited(area: Area2D) -> void:
	var root: Node = area.owner

	if root == null:
		return

	var component: InteractionComponent = find_interaction_component(root)

	if component == null:
		return

	var id: int = component.get_instance_id()

	if nearby_components.has(id):
		nearby_components.erase(id)

	if current_target == component:
		component.set_highlighted(false)
		current_target = null


func get_best_target() -> InteractionComponent:
	var hovered: InteractionComponent = get_hovered_target()

	if hovered != null:
		return hovered

	return get_closest_target()


func get_hovered_target() -> InteractionComponent:
	var mouse_pos: Vector2 = actor.get_global_mouse_position()

	for item in nearby_components.values():
		var component: InteractionComponent = item as InteractionComponent

		if not is_valid_target(component):
			continue

		if is_mouse_over_component(component, mouse_pos):
			return component

	return null


func get_closest_target() -> InteractionComponent:
	var closest: InteractionComponent = null
	var closest_distance: float = INF

	for item in nearby_components.values():
		var component: InteractionComponent = item as InteractionComponent

		if not is_valid_target(component):
			continue

		var owner_node: Node2D = component.owner as Node2D

		if owner_node == null:
			continue

		var distance: float = actor.global_position.distance_to(owner_node.global_position)

		if distance < closest_distance:
			closest_distance = distance
			closest = component

	return closest


func set_current_target(next_target: InteractionComponent) -> void:
	if current_target == next_target:
		return

	if current_target != null and is_instance_valid(current_target):
		current_target.set_highlighted(false)

	current_target = next_target

	if current_target != null and is_instance_valid(current_target):
		current_target.set_highlighted(true)


func is_mouse_over_component(component: InteractionComponent, mouse_pos: Vector2) -> bool:
	if component == null:
		return false

	if component.hover_area != null:
		return is_mouse_over_area(component.hover_area, mouse_pos)

	var owner_node: Node2D = component.owner as Node2D

	if owner_node == null:
		return false

	return owner_node.global_position.distance_to(mouse_pos) <= component.hover_radius_px


func is_mouse_over_area(area: Area2D, mouse_pos: Vector2) -> bool:
	for child in area.get_children():
		if child is CollisionPolygon2D:
			var polygon: CollisionPolygon2D = child as CollisionPolygon2D
			var local_mouse: Vector2 = polygon.to_local(mouse_pos)

			if Geometry2D.is_point_in_polygon(local_mouse, polygon.polygon):
				return true

		if child is CollisionShape2D:
			var collision_shape: CollisionShape2D = child as CollisionShape2D
			var shape: Shape2D = collision_shape.shape

			if shape == null:
				continue

			var local_mouse_shape: Vector2 = collision_shape.to_local(mouse_pos)

			if shape is RectangleShape2D:
				var rectangle: RectangleShape2D = shape as RectangleShape2D
				var half_size: Vector2 = rectangle.size * 0.5

				if abs(local_mouse_shape.x) <= half_size.x and abs(local_mouse_shape.y) <= half_size.y:
					return true

			if shape is CircleShape2D:
				var circle: CircleShape2D = shape as CircleShape2D

				if local_mouse_shape.length() <= circle.radius:
					return true

	return false


func is_valid_target(component: InteractionComponent) -> bool:
	if component == null:
		return false

	if not is_instance_valid(component):
		return false

	if not component.can_interact():
		return false

	var owner_node: Node = component.owner

	if owner_node != null and owner_node.has_method("interact"):
		return true

	if component.has_action(active_action_id):
		return true

	if component.has_action(&"hand"):
		return true

	return false


func find_interaction_component(node: Node) -> InteractionComponent:
	if node is InteractionComponent:
		return node as InteractionComponent

	for child in node.get_children():
		var found: InteractionComponent = find_interaction_component(child)

		if found != null:
			return found

	return null
