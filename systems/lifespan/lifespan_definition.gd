class_name LifeSpanDefinition
extends Resource

@export var id: StringName
@export var display_name: String = ""

@export var total_lifespan_minutes: int = 1440
@export var stages: Array[LifeSpanStageDefinition] = []


func get_stage_for_age_minutes(age_minutes: int) -> LifeSpanStageDefinition:
	if stages.is_empty():
		return null

	var progress := clampf(
		float(age_minutes) / float(max(total_lifespan_minutes, 1)),
		0.0,
		1.0
	)

	var selected_stage: LifeSpanStageDefinition = stages[0]

	for stage in stages:
		if stage == null:
			continue

		if progress >= stage.starts_at_progress:
			selected_stage = stage

	return selected_stage
