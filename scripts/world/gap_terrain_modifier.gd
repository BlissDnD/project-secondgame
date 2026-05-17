extends TerrainModifier
class_name GapTerrainModifier

@export var enabled: bool = true
@export var gap_start_x: int = 28
@export var gap_width_tiles: int = 10
@export var gap_depth_tiles: int = 40


func apply(
	terrain_cells: Dictionary,
	generator: WorldTerrainGenerator2,
	noise: FastNoiseLite
) -> Dictionary:
	print(
	"Gap modifier values: start=",
	gap_start_x,
	" width=",
	gap_width_tiles,
	" depth=",
	gap_depth_tiles
)
	if not enabled:
		return terrain_cells

	var result: Dictionary = {}

	for terrain_type in terrain_cells.keys():
		result[terrain_type] = []

		for cell in terrain_cells[terrain_type]:
			var inside_gap_x: bool = (
				cell.x >= gap_start_x
				and cell.x < gap_start_x + gap_width_tiles
			)

			if inside_gap_x:
				var surface_y: int = generator.get_surface_y_for_x(
					cell.x,
					noise
				)

				var gap_bottom_y: int = surface_y + gap_depth_tiles

				if cell.y >= surface_y and cell.y <= gap_bottom_y:
					continue

			result[terrain_type].append(cell)

	return result
