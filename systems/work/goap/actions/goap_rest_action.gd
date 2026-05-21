extends GOAPAction
class_name GOAPRestAction

@export var energy_per_second: float = 25.0
@export var finish_energy: float = 80.0

func enter(blackboard: WorkerBlackboard) -> void:
	super.enter(blackboard)
	blackboard.set_fact(&"is_resting", true)

func tick(blackboard: WorkerBlackboard, delta: float) -> ActionStatus:
	blackboard.stats.restore_energy(energy_per_second * delta)

	if blackboard.stats.energy >= finish_energy:
		blackboard.set_fact(&"needs_rest", false)
		blackboard.set_fact(&"is_resting", false)
		status = ActionStatus.SUCCEEDED
		return status

	status = ActionStatus.RUNNING
	return status

func exit(blackboard: WorkerBlackboard) -> void:
	blackboard.set_fact(&"is_resting", false)
	super.exit(blackboard)
