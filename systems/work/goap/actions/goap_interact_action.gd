extends GOAPAction
class_name GOAPInteractAction

@export var interaction_method: StringName = &"worker_interact"
@export var interaction_time: float = 0.5
@export var energy_cost: float = 2.0

var elapsed: float = 0.0
var has_called_interaction: bool = false

func enter(blackboard: WorkerBlackboard) -> void:
	super.enter(blackboard)
	elapsed = 0.0
	has_called_interaction = false

	if blackboard.current_target == null:
		status = ActionStatus.FAILED
		return

	blackboard.set_fact(&"is_interacting", true)

func tick(blackboard: WorkerBlackboard, delta: float) -> ActionStatus:
	if blackboard.current_target == null or not is_instance_valid(blackboard.current_target):
		return fail()

	elapsed += delta

	if elapsed < interaction_time:
		status = ActionStatus.RUNNING
		return status

	if not has_called_interaction:
		has_called_interaction = true

		if blackboard.current_target.has_method(interaction_method):
			blackboard.current_target.call(interaction_method, blackboard)
			blackboard.stats.consume_energy(energy_cost)
		else:
			return fail()

	blackboard.set_fact(&"is_interacting", false)
	status = ActionStatus.SUCCEEDED
	return status

func exit(blackboard: WorkerBlackboard) -> void:
	blackboard.set_fact(&"is_interacting", false)
	super.exit(blackboard)
