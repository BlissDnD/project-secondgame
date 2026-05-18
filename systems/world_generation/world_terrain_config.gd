extends Resource
class_name WorldTerrainConfig

@export_group("World Size")
@export var world_width_tiles: int = 384
@export var world_height_tiles: int = 144

@export_group("Surface Noise")
@export var base_surface_y: int = 13
@export var surface_amplitude: int = 3
@export var noise_frequency: float = 0.02
@export var noise_seed: int = 12345

@export_group("Terrain Layers")
@export var dirt_depth_tiles: int = 8

@export_group("Dirt Terrain")
@export var dirt_terrain_set: int = 0
@export var dirt_terrain_id: int = 0

@export_group("Stone Terrain")
@export var stone_terrain_set: int = 0
@export var stone_terrain_id: int = 1

func create_noise() -> FastNoiseLite:
	var noise := FastNoiseLite.new()
	noise.seed = noise_seed
	noise.frequency = noise_frequency
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	return noise

func get_surface_y_for_x(x: int, noise: FastNoiseLite) -> int:
	var noise_value: float = noise.get_noise_1d(float(x))
	var surface_offset: int = roundi(noise_value * surface_amplitude)
	return base_surface_y + surface_offset

func get_terrain_type_for_cell(y: int, surface_y: int) -> StringName:
	var depth: int = y - surface_y

	if depth < dirt_depth_tiles:
		return &"dirt"

	return &"stone"
