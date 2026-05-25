class_name LifeSpanStageSceneAdapter
extends Node

@export var lifespan_component: LifeSpanComponent
@export var stage_root: Node2D
@export var remove_previous_stage: bool = true

var current_stage_instance: Node
var current_stage_id: StringName


func _ready() -> void:
	call_deferred("_initialize")


func _initialize() -> void:
	if lifespan_component == null:
		push_error("LifeSpanStageSceneAdapter missing LifeSpanComponent.")
		return

	if stage_root == null:
		push_error("LifeSpanStageSceneAdapter missing stage_root.")
		return

	if not lifespan_component.stage_changed.is_connected(_on_stage_changed):
		lifespan_component.stage_changed.connect(_on_stage_changed)

	lifespan_component.force_refresh_stage()

	if lifespan_component.current_stage != null:
		_apply_stage(lifespan_component.current_stage)


func _on_stage_changed(new_stage: LifeSpanStageDefinition) -> void:
	_apply_stage(new_stage)


func _apply_stage(stage: LifeSpanStageDefinition) -> void:
	if stage == null:
		push_warning("LifeSpanStageSceneAdapter received null stage.")
		return

	if stage.id == current_stage_id:
		return

	if stage.stage_scene == null:
		push_warning("LifeSpan stage has no stage_scene: %s" % str(stage.id))
		return

	if remove_previous_stage:
		_clear_current_stage()

	var instance := stage.stage_scene.instantiate()
	stage_root.add_child(instance)

	current_stage_instance = instance
	current_stage_id = stage.id

	print("LifeSpanStageSceneAdapter applied stage scene: ", stage.id)


func _clear_current_stage() -> void:
	if current_stage_instance == null:
		return

	if is_instance_valid(current_stage_instance):
		current_stage_instance.queue_free()

	current_stage_instance = null
	current_stage_id = &""
