extends Node

@export var interaction_area: Area2D
@export var actor: Node2D

var nearby_components: Array[InteractionComponent] = []
var current_target: InteractionComponent = null


func _ready() -> void:
	if interaction_area == null:
		push_error("interaction_area is not assigned.")
		return

	if actor == null:
		push_error("actor is not assigned.")
		return

	interaction_area.area_entered.connect(_on_area_entered)
	interaction_area.area_exited.connect(_on_area_exited)


func _physics_process(_delta: float) -> void:
	current_target = get_closest_target()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if current_target == null:
			LoggerConsole.log("No interaction target.")
			return

		if current_target.can_interact():
			current_target.interact(actor)


func _on_area_entered(area: Area2D) -> void:
	var root := area.owner

	if root == actor:
		return

	var component: InteractionComponent = find_interaction_component(root)

	if component == null:
		LoggerConsole.log(
			"No InteractionComponent on " + root.name
		)
		return

	if not component.can_interact():
		return

	if nearby_components.has(component):
		return

	nearby_components.append(component)

	LoggerConsole.log(
		"Added interactable: " + root.name
	)


func _on_area_exited(area: Area2D) -> void:
	var root := area.owner

	var component: InteractionComponent = find_interaction_component(root)

	if component != null:
		nearby_components.erase(component)


func get_closest_target() -> InteractionComponent:
	var closest: InteractionComponent = null
	var closest_distance := INF

	for component in nearby_components:
		if not is_instance_valid(component):
			continue

		if not component.can_interact():
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


func find_interaction_component(
	node: Node
) -> InteractionComponent:
	if node is InteractionComponent:
		return node

	for child in node.get_children():
		var found: InteractionComponent = (
			find_interaction_component(child)
		)

		if found != null:
			return found

	return null
