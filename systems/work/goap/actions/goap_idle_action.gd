extends GOAPAction
class_name GOAPIdleAction

@export var idle_time: float = 1.0

var elapsed: float = 0.0

func enter(blackboard: WorkerBlackboard) -> void:
	super.enter(blackboard)
	elapsed = 0.0
	blackboard.set_fact(&"is_idle", true)

func tick(blackboard: WorkerBlackboard, delta: float) -> ActionStatus:
	elapsed += delta

	if elapsed >= idle_time:
		blackboard.set_fact(&"is_idle", false)
		status = ActionStatus.SUCCEEDED
		return status

	status = ActionStatus.RUNNING
	return status

func exit(blackboard: WorkerBlackboard) -> void:
	blackboard.set_fact(&"is_idle", false)
	super.exit(blackboard)
