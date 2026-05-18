extends TerrainModifier
class_name CaveSystemTerrainModifier

@export var enabled: bool = true

@export_group("Chambers")
@export var chamber_count: int = 8
@export var chamber_min_radius: Vector2i = Vector2i(4, 3)
@export var chamber_max_radius: Vector2i = Vector2i(10, 6)
@export var min_depth_from_surface: int = 12
@export var max_depth_from_surface: int = 80

@export_group("Tunnels")
@export var tunnel_radius: int = 2
@export var tunnel_max_steps: int = 2000
@export_range(0.0, 1.0, 0.01) var tunnel_directness: float = 0.75
@export_range(0.0, 1.0, 0.01) var extra_connection_chance: float = 0.25

@export_group("Random")
@export var seed_offset: int = 9001

var _carved_cells: Dictionary = {}


func apply(
	terrain_cells: Dictionary,
	config: WorldTerrainConfig,
	generation_data: WorldGenerationData,
	noise: FastNoiseLite
) -> Dictionary:
	if not enabled:
		return terrain_cells

	if config == null:
		push_error("CaveSystemTerrainModifier.apply: config is null.")
		return terrain_cells

	if generation_data == null:
		push_error("CaveSystemTerrainModifier.apply: generation_data is null.")
		return terrain_cells

	if noise == null:
		push_error("CaveSystemTerrainModifier.apply: noise is null.")
		return terrain_cells

	_carved_cells.clear()

	var rng := RandomNumberGenerator.new()
	rng.seed = noise.seed + seed_offset

	var chambers: Array[Dictionary] = generate_chambers(
		config,
		noise,
		rng
	)

	chambers.sort_custom(_sort_chambers_by_x)
	generation_data.generated_chambers = chambers.duplicate()

	for chamber in chambers:
		var center: Vector2i = chamber["center"]
		var radius: Vector2i = chamber["radius"]

		carve_ellipse(
			center,
			radius
		)

	for index in range(chambers.size() - 1):
		var chamber_a: Dictionary = chambers[index]
		var chamber_b: Dictionary = chambers[index + 1]

		carve_tunnel(
			chamber_a["center"],
			chamber_b["center"],
			rng
		)

	for i in range(chambers.size()):
		for j in range(i + 2, chambers.size()):
			if rng.randf() > extra_connection_chance:
				continue

			carve_tunnel(
				chambers[i]["center"],
				chambers[j]["center"],
				rng
			)

	remove_carved_cells(terrain_cells)

	return terrain_cells


func generate_chambers(
	config: WorldTerrainConfig,
	noise: FastNoiseLite,
	rng: RandomNumberGenerator
) -> Array[Dictionary]:
	var chambers: Array[Dictionary] = []

	var min_x: int = 8
	var max_x: int = config.world_width_tiles - 8

	if max_x <= min_x:
		return chambers

	for _i in range(chamber_count):
		var x: int = rng.randi_range(min_x, max_x)
		var surface_y: int = config.get_surface_y_for_x(x, noise)

		var min_y: int = surface_y + min_depth_from_surface
		var max_y: int = mini(
			surface_y + max_depth_from_surface,
			config.world_height_tiles - 8
		)

		if max_y <= min_y:
			continue

		var center := Vector2i(
			x,
			rng.randi_range(min_y, max_y)
		)

		var radius := Vector2i(
			rng.randi_range(chamber_min_radius.x, chamber_max_radius.x),
			rng.randi_range(chamber_min_radius.y, chamber_max_radius.y)
		)

		chambers.append({
			"center": center,
			"radius": radius
		})

	return chambers


func _sort_chambers_by_x(a: Dictionary, b: Dictionary) -> bool:
	var center_a: Vector2i = a["center"]
	var center_b: Vector2i = b["center"]

	return center_a.x < center_b.x


func carve_ellipse(
	center: Vector2i,
	radius: Vector2i
) -> void:
	if radius.x <= 0 or radius.y <= 0:
		return

	for x in range(center.x - radius.x, center.x + radius.x + 1):
		for y in range(center.y - radius.y, center.y + radius.y + 1):
			var normalized_x: float = float(x - center.x) / float(radius.x)
			var normalized_y: float = float(y - center.y) / float(radius.y)

			if normalized_x * normalized_x + normalized_y * normalized_y <= 1.0:
				_carved_cells[Vector2i(x, y)] = true


func carve_tunnel(
	from_cell: Vector2i,
	to_cell: Vector2i,
	rng: RandomNumberGenerator
) -> void:
	var current: Vector2i = from_cell
	var steps: int = 0

	while current != to_cell and steps < tunnel_max_steps:
		carve_circle(
			current,
			tunnel_radius
		)

		var direction := Vector2i.ZERO

		if rng.randf() <= tunnel_directness:
			var delta: Vector2i = to_cell - current

			if abs(delta.x) > abs(delta.y):
				direction.x = sign_int(delta.x)
			else:
				direction.y = sign_int(delta.y)
		else:
			match rng.randi_range(0, 3):
				0:
					direction = Vector2i.RIGHT
				1:
					direction = Vector2i.LEFT
				2:
					direction = Vector2i.DOWN
				3:
					direction = Vector2i.UP

		current += direction
		steps += 1

	carve_circle(
		to_cell,
		tunnel_radius
	)


func carve_circle(
	center: Vector2i,
	radius: int
) -> void:
	if radius <= 0:
		_carved_cells[center] = true
		return

	var radius_squared: int = radius * radius

	for x in range(center.x - radius, center.x + radius + 1):
		for y in range(center.y - radius, center.y + radius + 1):
			var offset := Vector2i(
				x - center.x,
				y - center.y
			)

			if offset.length_squared() <= radius_squared:
				_carved_cells[Vector2i(x, y)] = true


func remove_carved_cells(
	terrain_cells: Dictionary
) -> void:
	for terrain_type in terrain_cells.keys():
		var source_cells: Array = terrain_cells[terrain_type]
		var kept_cells: Array[Vector2i] = []

		for cell in source_cells:
			if not _carved_cells.has(cell):
				kept_cells.append(cell)

		terrain_cells[terrain_type] = kept_cells


func sign_int(value: int) -> int:
	if value > 0:
		return 1

	if value < 0:
		return -1

	return 0
