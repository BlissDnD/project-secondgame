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

	if blackboard == null:
		status = ActionStatus.FAILED
		return

	if blackboard.current_target == null:
		status = ActionStatus.FAILED
		return

	blackboard.set_fact(&"is_interacting", true)


func tick(blackboard: WorkerBlackboard, delta: float) -> ActionStatus:
	if blackboard == null:
		return fail()

	if blackboard.current_target == null or not is_instance_valid(blackboard.current_target):
		return fail()

	if blackboard.stats != null and blackboard.stats.stamina <= 0.0:
		return fail("stamina_depleted")

	elapsed += delta

	if elapsed < interaction_time:
		status = ActionStatus.RUNNING
		return status

	if has_called_interaction:
		blackboard.set_fact(&"is_interacting", false)
		status = ActionStatus.SUCCEEDED
		return status

	has_called_interaction = true

	if not blackboard.current_target.has_method(interaction_method):
		return fail("missing_interaction_method")

	var result = blackboard.current_target.call(interaction_method, blackboard)

	if blackboard.stats != null:
		blackboard.stats.consume_energy(energy_cost)

	if result is Dictionary:
		var success: bool = bool(result.get("success", false))

		if not success:
			return fail(str(result.get("reason", "interaction_failed")))

		if result.has("carried_item"):
			blackboard.carried_item = result["carried_item"]
			blackboard.set_fact(&"has_item", true)

		if result.get("needs_delivery", false):
			blackboard.set_fact(&"needs_delivery", true)

		if result.get("work_complete", false):
			blackboard.set_fact(&"work_complete", true)

		blackboard.set_fact(&"is_interacting", false)
		status = ActionStatus.SUCCEEDED
		return status

	if result == true:
		blackboard.set_fact(&"is_interacting", false)
		status = ActionStatus.SUCCEEDED
		return status

	return fail("interaction_returned_false")


func exit(blackboard: WorkerBlackboard) -> void:
	if blackboard != null:
		blackboard.set_fact(&"is_interacting", false)

	super.exit(blackboard)
