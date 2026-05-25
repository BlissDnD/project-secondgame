class_name LifeSpanVisualAdapter
extends Node

@export var lifespan_component: LifeSpanComponent
@export var sprite: Sprite2D


func _ready() -> void:
	call_deferred("_initialize")


func _initialize() -> void:
	if lifespan_component == null:
		push_error("LifeSpanVisualAdapter missing LifeSpanComponent.")
		return

	if sprite == null:
		push_error("LifeSpanVisualAdapter missing Sprite2D.")
		return

	if not lifespan_component.stage_changed.is_connected(_on_stage_changed):
		lifespan_component.stage_changed.connect(_on_stage_changed)

	lifespan_component.force_refresh_stage()

	if lifespan_component.current_stage != null:
		_apply_stage(lifespan_component.current_stage)
	else:
		push_warning("LifeSpanVisualAdapter: current_stage is still null.")


func _on_stage_changed(new_stage: LifeSpanStageDefinition) -> void:
	_apply_stage(new_stage)


func _apply_stage(stage: LifeSpanStageDefinition) -> void:
	if stage == null:
		push_warning("LifeSpanVisualAdapter received null stage.")
		return

	if stage.sprite_texture == null:
		push_warning("LifeSpan stage has no sprite_texture: %s" % str(stage.id))
		return

	sprite.texture = stage.sprite_texture
	print("LifeSpanVisualAdapter applied stage: ", stage.id)
