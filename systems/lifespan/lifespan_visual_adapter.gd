class_name LifeSpanVisualAdapter
extends Node

@export var lifespan_component: LifeSpanComponent
@export var sprite: Sprite2D


func _ready() -> void:
	if lifespan_component == null:
		push_warning("LifeSpanVisualAdapter missing LifeSpanComponent.")
		return

	if sprite == null:
		push_warning("LifeSpanVisualAdapter missing Sprite2D.")
		return

	lifespan_component.stage_changed.connect(_on_stage_changed)

	if lifespan_component.current_stage != null:
		_apply_stage(lifespan_component.current_stage)


func _on_stage_changed(new_stage: LifeSpanStageDefinition) -> void:
	_apply_stage(new_stage)


func _apply_stage(stage: LifeSpanStageDefinition) -> void:
	if stage == null:
		return

	if stage.sprite_texture != null:
		sprite.texture = stage.sprite_texture
