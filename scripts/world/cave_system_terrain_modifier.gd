extends TerrainModifier
class_name CaveSystemTerrainModifier

@export var enabled: bool = true
@export var seed_offset: int = 5000

@export_group("Bounds")
@export var start_x: int = 40
@export var end_x: int = 320
@export var min_depth_from_surface: int = 18
@export var max_depth_from_surface: int = 90

@export_group("Chambers")
@export var chamber_count: int = 8
@export var chamber_min_radius: Vector2i = Vector2i(4, 3)
@export var chamber_max_radius: Vector2i = Vector2i(12, 7)

@export_group("Tunnels")
@export var tunnel_half_width: int = 2
@export_range(0.0, 1.0, 0.01) var extra_connection_chance: float = 0.25


func apply(
	terrain_cells: Dictionary,
	generator: WorldTerrainGenerator2,
	noise: FastNoiseLite
) -> Dictionary:
	if not enabled:
		return terrain_cells

	var rng := RandomNumberGenerator.new()
	rng.seed = noise.seed + seed_offset

	var chambers: Array[Dictionary] = generate_chambers(generator, noise, rng)
	var carved_cells: Dictionary = {}

	for chamber in chambers:
		carve_ellipse(
			carved_cells,
			chamber["center"],
			chamber["radius"]
		)

	for i in range(chambers.size() - 1):
		carve_tunnel(
			carved_cells,
			chambers[i]["center"],
			chambers[i + 1]["center"]
		)

	for i in range(chambers.size()):
		for j in range(i + 2, chambers.size()):
			if rng.randf() <= extra_connection_chance:
				carve_tunnel(
					carved_cells,
					chambers[i]["center"],
					chambers[j]["center"]
				)

	return remove_carved_cells(terrain_cells, carved_cells)


func generate_chambers(
	generator: WorldTerrainGenerator2,
	noise: FastNoiseLite,
	rng: RandomNumberGenerator
) -> Array[Dictionary]:
	var chambers: Array[Dictionary] = []

	for i in range(chamber_count):
		var x: int = rng.randi_range(start_x, end_x)
		var surface_y: int = generator.get_surface_y_for_x(x, noise)

		var y: int = surface_y + rng.randi_range(
			min_depth_from_surface,
			max_depth_from_surface
		)

		var radius: Vector2i = Vector2i(
			rng.randi_range(chamber_min_radius.x, chamber_max_radius.x),
			rng.randi_range(chamber_min_radius.y, chamber_max_radius.y)
		)

		chambers.append({
			"center": Vector2i(x, y),
			"radius": radius
		})

	chambers.sort_custom(_sort_chambers_by_x)

	return chambers


func _sort_chambers_by_x(a: Dictionary, b: Dictionary) -> bool:
	return a["center"].x < b["center"].x


func carve_ellipse(
	carved_cells: Dictionary,
	center: Vector2i,
	radius: Vector2i
) -> void:
	for x in range(center.x - radius.x, center.x + radius.x + 1):
		for y in range(center.y - radius.y, center.y + radius.y + 1):
			var dx: float = float(x - center.x) / float(radius.x)
			var dy: float = float(y - center.y) / float(radius.y)

			if dx * dx + dy * dy <= 1.0:
				carved_cells[Vector2i(x, y)] = true


func carve_tunnel(
	carved_cells: Dictionary,
	from_cell: Vector2i,
	to_cell: Vector2i
) -> void:
	var current: Vector2i = from_cell

	while current.x != to_cell.x:
		carve_circle(carved_cells, current, tunnel_half_width)

		if current.x < to_cell.x:
			current.x += 1
		else:
			current.x -= 1

	while current.y != to_cell.y:
		carve_circle(carved_cells, current, tunnel_half_width)

		if current.y < to_cell.y:
			current.y += 1
		else:
			current.y -= 1

	carve_circle(carved_cells, to_cell, tunnel_half_width)


func carve_circle(
	carved_cells: Dictionary,
	center: Vector2i,
	radius: int
) -> void:
	for x in range(center.x - radius, center.x + radius + 1):
		for y in range(center.y - radius, center.y + radius + 1):
			var cell := Vector2i(x, y)

			if center.distance_to(cell) <= radius:
				carved_cells[cell] = true


func remove_carved_cells(
	terrain_cells: Dictionary,
	carved_cells: Dictionary
) -> Dictionary:
	var result: Dictionary = {}

	for terrain_type in terrain_cells.keys():
		result[terrain_type] = []

		for cell in terrain_cells[terrain_type]:
			if carved_cells.has(cell):
				continue

			result[terrain_type].append(cell)

	return result
