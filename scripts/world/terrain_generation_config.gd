extends Resource
class_name TerrainGenerationConfig

@export var tile_size: int = 64

@export var room_columns: int = 6
@export var room_rows: int = 4

@export var room_width_tiles: int = 64
@export var room_height_tiles: int = 36

@export var surface_y: int = 18

@export var terrain_set_id: int = 0
@export var dirt_terrain_id: int = 0


func get_world_width_tiles() -> int:
	return room_columns * room_width_tiles


func get_world_height_tiles() -> int:
	return room_rows * room_height_tiles
