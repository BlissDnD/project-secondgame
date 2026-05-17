extends Node

@export var interaction_area: Area2D
@export var actor: Node2D
@export var active_action_id: StringName = &"hand"
var highlighted_target: InteractionComponent = null

var nearby_components: Dictionary = {}
var current_target: InteractionComponent = null


func _ready() -> void:
	if interaction_area == null:
		push_error("InteractionManager: interaction_area is not assigned.")
		return

	if actor == null:
		push_error("InteractionManager: actor is not assigned.")
		return

	interaction_area.area_entered.connect(_on_area_entered)
	interaction_area.area_exited.connect(_on_area_exited)


func _physics_process(_delta: float) -> void:
	var next_target := get_best_target()
	set_current_target(next_target)
	
func set_current_target(next_target: InteractionComponent) -> void:
	if current_target == next_target:
		return

	if current_target != null and is_instance_valid(current_target):
		current_target.set_highlighted(false)

	current_target = next_target

	if current_target != null and is_instance_valid(current_target):
		current_target.set_highlighted(true)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if current_target == null:
			LoggerConsole.log("No " + str(active_action_id) + " target.")
			return

		current_target.execute_action(active_action_id, actor)


func _on_area_entered(area: Area2D) -> void:
	var root := area.owner

	if root == null:
		return

	if root == actor:
		return

	var component := find_interaction_component(root)

	if component == null:
		return

	if not is_valid_target(component):
		return

	var id := component.get_instance_id()

	if nearby_components.has(id):
		return

	nearby_components[id] = component
	LoggerConsole.log("Added interaction target: " + root.name)


func _on_area_exited(area: Area2D) -> void:
	var root := area.owner

	if root == null:
		return

	var component := find_interaction_component(root)

	if component == null:
		return

	var id := component.get_instance_id()

	if nearby_components.has(id):
		nearby_components.erase(id)

	if current_target == component:
		component.set_highlighted(false)
		current_target = null


func get_best_target() -> InteractionComponent:
	var hovered := get_hovered_target()

	if hovered != null:
		return hovered

	return get_closest_target()


func get_hovered_target() -> InteractionComponent:
	var mouse_pos := actor.get_global_mouse_position()

	for component in nearby_components.values():
		if not is_valid_target(component):
			continue

		if is_mouse_over_component(component, mouse_pos):
			return component

	return null


func get_closest_target() -> InteractionComponent:
	var closest: InteractionComponent = null
	var closest_distance := INF

	for component in nearby_components.values():
		if not is_valid_target(component):
			continue

		var owner_node := component.owner as Node2D

		if owner_node == null:
			continue

		var distance := actor.global_position.distance_to(
			owner_node.global_position
		)

		if distance < closest_distance:
			closest_distance = distance
			closest = component

	return closest


func is_mouse_over_component(
	component: InteractionComponent,
	mouse_pos: Vector2
) -> bool:
	var owner_node := component.owner as Node2D

	if owner_node == null:
		return false

	return owner_node.global_position.distance_to(mouse_pos) <= component.hover_radius_px


func is_valid_target(component: InteractionComponent) -> bool:
	if component == null:
		return false

	if not is_instance_valid(component):
		return false

	if not component.can_interact():
		return false

	if not component.has_action(active_action_id):
		return false

	return true


func find_interaction_component(node: Node) -> InteractionComponent:
	if node is InteractionComponent:
		return node

	for child in node.get_children():
		var found := find_interaction_component(child)

		if found != null:
			return found

	return null
