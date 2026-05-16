extends Node

@export var interaction_area: Area2D
@export var actor: Node2D

var nearby_components: Array[InteractableComponent] = []
var current_target: InteractableComponent = null


func _ready() -> void:
	if interaction_area == null:
		push_error("InteractionManager: interaction_area is not assigned.")
		return

	if actor == null:
		push_error("InteractionManager: actor is not assigned.")
		return

	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)


func _physics_process(_delta: float) -> void:
	current_target = get_closest_target()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if current_target == null:
			print("No interaction target.")
			return

		if current_target.can_interact():
			current_target.interact(actor)


func _on_body_entered(body: Node2D) -> void:
	print("BODY ENTERED INTERACTION AREA: ", body.name)

	var component := find_interactable_component(body)

	if component == null:
		print("No InteractableComponent found on: ", body.name)
		return

	if component.can_interact():
		print("Added interactable: ", body.name)
		nearby_components.append(component)


func _on_body_exited(body: Node2D) -> void:
	var component := find_interactable_component(body)

	if component != null:
		nearby_components.erase(component)


func find_interactable_component(body: Node) -> InteractableComponent:
	for child in body.get_children():
		if child is InteractableComponent:
			return child

	return null


func get_closest_target() -> InteractableComponent:
	var closest: InteractableComponent = null
	var closest_distance := INF

	for component in nearby_components:
		if not is_instance_valid(component):
			continue

		if not component.can_interact():
			continue

		var owner_node := component.owner as Node2D

		if owner_node == null:
			continue

		var distance := actor.global_position.distance_to(owner_node.global_position)

		if distance < closest_distance:
			closest_distance = distance
			closest = component

	return closest
