class_name VisibilityCullingComponent
extends Node

@export var visual_root: Node2D
@export var visible_distance: float = 2500.0
@export var check_interval_seconds: float = 0.5

var _player: Node2D
var _time_accumulator: float = 0.0
var _is_visible_state: bool = true


func _ready() -> void:
	print("VisibilityCulling READY: ", owner.name)
	call_deferred("_initialize")


func _process(delta: float) -> void:
	if _player == null:
		_try_resolve_player()

		if _player == null:
			return

	if visual_root == null:
		return

	_time_accumulator += delta

	if _time_accumulator < check_interval_seconds:
		return

	_time_accumulator = 0.0
	_update_visibility_state()


func _initialize() -> void:
	if visual_root == null:
		push_error("VisibilityCullingComponent missing visual_root.")
		return

	_try_resolve_player()

	if _player == null:
		push_warning("VisibilityCullingComponent could not find Player yet.")

	_update_visibility_state()


func _try_resolve_player() -> void:
	var root := get_tree().current_scene

	if root == null:
		return

	var player := root.find_child("Player", true, false)

	if player == null:
		return

	_player = player as Node2D


func _update_visibility_state() -> void:
	if _player == null:
		return

	var distance := visual_root.global_position.distance_to(_player.global_position)
	var should_be_visible := distance <= visible_distance

	if should_be_visible == _is_visible_state:
		return

	_is_visible_state = should_be_visible
	_apply_visibility(distance)


func _apply_visibility(distance: float) -> void:
	visual_root.visible = _is_visible_state

	print(
		"VisibilityCulling: ",
		owner.name,
		" visible=", _is_visible_state,
		" distance=", distance
	)
