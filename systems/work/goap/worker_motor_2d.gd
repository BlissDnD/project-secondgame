extends Node
class_name WorkerMotor2D

signal destination_reached
signal movement_failed

@export var actor_path: NodePath
@export var navigation_agent_path: NodePath
@export var move_speed: float = 80.0
@export var acceleration: float = 900.0
@export var stop_distance: float = 8.0

var actor: CharacterBody2D
var navigation_agent: NavigationAgent2D
var destination: Vector2 = Vector2.ZERO
var has_destination: bool = false

func _ready() -> void:
	actor = get_node_or_null(actor_path) as CharacterBody2D
	navigation_agent = get_node_or_null(navigation_agent_path) as NavigationAgent2D

	if actor == null:
		push_error("WorkerMotor2D missing actor_path CharacterBody2D.")
	if navigation_agent == null:
		push_error("WorkerMotor2D missing navigation_agent_path NavigationAgent2D.")
		return

	navigation_agent.target_desired_distance = stop_distance
	navigation_agent.path_desired_distance = stop_distance

func move_to(global_position: Vector2) -> void:
	if navigation_agent == null:
		return

	destination = global_position
	has_destination = true
	navigation_agent.target_position = destination

func stop() -> void:
	has_destination = false
	if actor != null:
		actor.velocity = Vector2.ZERO

func _physics_process(delta: float) -> void:
	if actor == null or navigation_agent == null:
		return
	if not has_destination:
		return

	if navigation_agent.is_navigation_finished():
		stop()
		destination_reached.emit()
		return

	var next_position := navigation_agent.get_next_path_position()
	var direction := actor.global_position.direction_to(next_position)

	if actor.global_position.distance_to(destination) <= stop_distance:
		stop()
		destination_reached.emit()
		return

	var desired_velocity := direction * move_speed
	actor.velocity = actor.velocity.move_toward(desired_velocity, acceleration * delta)
	actor.move_and_slide()
