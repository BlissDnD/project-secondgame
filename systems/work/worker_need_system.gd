extends Node
class_name WorkerNeedSystem

signal need_changed(old_need: StringName, new_need: StringName)

const NONE: StringName = &"None"
const IDLE_NEED: StringName = &"IdleNeed"
const DO_ASSIGNED_WORK_NEED: StringName = &"DoAssignedWorkNeed"
const RECOVER_STAMINA_NEED: StringName = &"RecoverStaminaNeed"
const FAILED_NEED: StringName = &"FailedNeed"

var current_need: StringName = NONE
var previous_need: StringName = NONE


func evaluate(stats: WorkerStatsComponent, has_assignment: bool) -> StringName:
	var next_need := _get_next_need(stats, has_assignment)
	_set_need(next_need)
	return current_need


func _get_next_need(stats: WorkerStatsComponent, has_assignment: bool) -> StringName:
	if stats == null:
		return FAILED_NEED

	if not stats.is_alive():
		return FAILED_NEED

	if stats.is_stamina_low:
		return RECOVER_STAMINA_NEED

	if has_assignment:
		return DO_ASSIGNED_WORK_NEED

	return IDLE_NEED


func _set_need(new_need: StringName) -> void:
	if current_need == new_need:
		return

	var old_need := current_need
	previous_need = current_need
	current_need = new_need

	need_changed.emit(old_need, current_need)


func is_recovery_needed() -> bool:
	return current_need == RECOVER_STAMINA_NEED


func is_work_needed() -> bool:
	return current_need == DO_ASSIGNED_WORK_NEED


func is_idle_needed() -> bool:
	return current_need == IDLE_NEED


func is_failed() -> bool:
	return current_need == FAILED_NEED


func get_debug_state() -> Dictionary:
	return {
		"current_need": str(current_need),
		"previous_need": str(previous_need)
	}
