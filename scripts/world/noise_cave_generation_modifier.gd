extends TerrainModifier
class_name NoiseCaveTerrainModifier

@export var enabled: bool = true

@export_group("Noise")
@export var frequency: float = 0.08
@export var threshold: float = 0.42
@export var seed_offset: int = 999

@export_group("Depth")
@export var min_depth_from_surface: int = 12
@export var max_depth_from_surface: int = 80


func apply(
	terrain_cells: Dictionary,
	generator: WorldTerrainGenerator2,
	noise: FastNoiseLite
) -> Dictionary:
	if not enabled:
		return terrain_cells

	var cave_noise := FastNoiseLite.new()

	cave_noise.seed = noise.seed + seed_offset
	cave_noise.frequency = frequency
	cave_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX

	var result: Dictionary = {}

	for terrain_type in terrain_cells.keys():
		result[terrain_type] = []

		for cell in terrain_cells[terrain_type]:
			var surface_y: int = generator.get_surface_y_for_x(
				cell.x,
				noise
			)

			var depth_from_surface: int = (
				cell.y - surface_y
			)

			var valid_depth: bool = (
				depth_from_surface >= min_depth_from_surface
				and depth_from_surface <= max_depth_from_surface
			)

			if valid_depth:
				var noise_value: float = cave_noise.get_noise_2d(
					cell.x,
					cell.y
				)

				if noise_value > threshold:
					continue

			result[terrain_type].append(cell)

	return result
