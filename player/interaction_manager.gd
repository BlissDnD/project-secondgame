extends Node

@export var interaction_area: Area2D
@export var actor: Node2D

var nearby_interactables: Array[Node2D] = []
var current_target: Node2D = null


func _ready() -> void:
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)


func _physics_process(_delta: float) -> void:
	current_target = get_closest_target()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and current_target != null:
		if current_target.has_method("interact"):
			current_target.interact(actor)


func _on_body_entered(body: Node2D) -> void:
	if body.has_method("interact"):
		nearby_interactables.append(body)


func _on_body_exited(body: Node2D) -> void:
	nearby_interactables.erase(body)


func get_closest_target() -> Node2D:
	var closest: Node2D = null
	var closest_distance := INF

	for target in nearby_interactables:
		if not is_instance_valid(target):
			continue

		var distance := actor.global_position.distance_to(target.global_position)

		if distance < closest_distance:
			closest_distance = distance
			closest = target

	return closest
