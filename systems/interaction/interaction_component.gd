extends Node
class_name InteractionComponent

@export var enabled: bool = true
@export var hover_radius_px: float = 32.0
@export var actions: Array[InteractionAction] = []

@export_group("Highlight")
@export var highlight_target: CanvasItem
@export var highlight_color: Color = Color(1.35, 1.35, 1.35, 1.0)

var _default_modulate: Color = Color.WHITE
var _is_highlighted: bool = false

func _ready() -> void:
	if highlight_target == null:
		highlight_target = owner as CanvasItem

	if highlight_target != null:
		_default_modulate = highlight_target.modulate


func can_interact() -> bool:
	return enabled and not get_available_actions().is_empty()


func get_available_actions() -> Array[InteractionAction]:
	var result: Array[InteractionAction] = []

	if not enabled:
		return result

	for action in actions:
		if action == null:
			continue

		if action.enabled:
			result.append(action)

	return result


func has_action(action_id: StringName) -> bool:
	for action in get_available_actions():
		if action.action_id == action_id:
			return true

	return false


func execute_action(action_id: StringName, actor: Node) -> void:
	if not has_action(action_id):
		return

	LoggerConsole.log(
		str(actor.name) + " used " + str(action_id) + " on " + str(owner.name)
	)

func set_highlighted(value: bool) -> void:
	if _is_highlighted == value:
		return

	_is_highlighted = value

	if highlight_target == null:
		return

	if value:
		highlight_target.modulate = highlight_color
	else:
		highlight_target.modulate = _default_modulate
