extends GOAPAction
class_name GOAPDeliverItemAction

@export var delivery_method: StringName = &"worker_receive_item"

func enter(blackboard: WorkerBlackboard) -> void:
	super.enter(blackboard)

	if blackboard.current_target == null:
		status = ActionStatus.FAILED
		return

	if blackboard.carried_item == null:
		status = ActionStatus.FAILED
		return

func tick(blackboard: WorkerBlackboard, _delta: float) -> ActionStatus:
	if blackboard.current_target == null or blackboard.carried_item == null:
		return fail()

	if not blackboard.current_target.has_method(delivery_method):
		return fail()

	var accepted: bool = blackboard.current_target.call(delivery_method, blackboard.carried_item, blackboard)
	if not accepted:
		return fail()

	blackboard.carried_item = null
	blackboard.set_fact(&"has_item", false)
	blackboard.set_fact(&"item_delivered", true)

	status = ActionStatus.SUCCEEDED
	return status
