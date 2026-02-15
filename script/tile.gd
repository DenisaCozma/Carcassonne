extends Resource
class_name Tile

@export var tile_type: int  
@export var rotation: int = 0  
@export var grid_position: Vector2i = Vector2i.ZERO

var col: int
var row: int

func _init(type: int = 0, rot: int = 0) -> void:
	tile_type = type
	rotation = rot

func rotate_clockwise() -> void:
	rotation = (rotation + 1) % 4

func rotate_counter_clockwise() -> void:
	rotation = (rotation - 1 + 4) % 4

func get_rotation_degrees() -> float:
	return rotation * 90.0

func get_rotation_radians() -> float:
	return rotation * PI / 2.0

func get_edges() -> Array[int]:
	var tile_def = TileDeck.TILE_DEFINITIONS[tile_type]
	var base_edges = tile_def.edges
	
	if rotation == 0:
		return base_edges.duplicate()
	elif rotation == 1:
		return [base_edges[3], base_edges[0], base_edges[1], base_edges[2]]
	elif rotation == 2:
		return [base_edges[2], base_edges[3], base_edges[0], base_edges[1]]
	else:
		return [base_edges[1], base_edges[2], base_edges[3], base_edges[0]]

func get_road_segments() -> Array:
	var tile_def = TileDeck.TILE_DEFINITIONS[tile_type]
	return rotate_segments(tile_def.road_segments)

func get_city_segments() -> Array:
	var tile_def = TileDeck.TILE_DEFINITIONS[tile_type]
	return rotate_segments(tile_def.city_segments)

func rotate_segments(base_segments: Array) -> Array:
	if rotation == 0:
		return base_segments.duplicate(true)
	
	var rotated = []
	for segment in base_segments:
		var rotated_segment = []
		for edge in segment:
			# Rotește fiecare edge
			var new_edge = rotate_edge_index(edge, rotation)
			rotated_segment.append(new_edge)
		rotated.append(rotated_segment)
	
	return rotated

func rotate_edge_index(edge: int, rot: int) -> int:
	return (edge + rot) % 4
