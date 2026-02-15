extends Resource
class_name TileDeck

enum EdgeType {
	FIELD = 0,
	ROAD = 1,
	CITY = 2,
}

class TileDef:
	var col: int
	var row: int
	var count: int
	var edges: Array[int]
	var has_monastery: bool = false 
	var road_segments: Array
	var city_segments: Array
	
	func _init(c: int, r: int, n: int, e: Array[int], m: bool, rs: Array = [], cs: Array = []):
		col = c
		row = r
		count = n
		edges = e
		has_monastery = m
		road_segments = rs
		city_segments = cs

static var TILE_DEFINITIONS := [
	TileDef.new(0, 0, 5, [EdgeType.CITY, EdgeType.CITY, EdgeType.FIELD, EdgeType.FIELD], false, [], [[0,1]]),
	TileDef.new(1, 0, 3, [EdgeType.FIELD, EdgeType.CITY, EdgeType.FIELD, EdgeType.CITY], false, [], [[1,3]]),
	TileDef.new(2, 0, 4, [EdgeType.FIELD, EdgeType.ROAD, EdgeType.ROAD, EdgeType.ROAD], false, [[1],[2],[3]], []),
	TileDef.new(3, 0, 1, [EdgeType.CITY, EdgeType.CITY, EdgeType.CITY, EdgeType.CITY], false, [], [[0,1,2,3]]),
	TileDef.new(4, 0, 3, [EdgeType.ROAD, EdgeType.ROAD, EdgeType.ROAD, EdgeType.ROAD], false, [[0],[1],[2],[3]], []),
	
	TileDef.new(0, 1, 4, [EdgeType.CITY, EdgeType.FIELD, EdgeType.CITY, EdgeType.CITY], false, [], [[0,2,3]]),
	TileDef.new(1, 1, 3, [EdgeType.CITY, EdgeType.ROAD, EdgeType.CITY, EdgeType.CITY], false, [[1]], [[0,2,3]]),
	TileDef.new(2, 1, 5, [EdgeType.ROAD, EdgeType.ROAD, EdgeType.CITY, EdgeType.CITY], false, [[0,1]], [[2,3]]),
	TileDef.new(3, 1, 2, [EdgeType.CITY, EdgeType.FIELD, EdgeType.FIELD, EdgeType.CITY], false, [], [[0],[3]]),
	TileDef.new(4, 1, 9, [EdgeType.ROAD, EdgeType.ROAD, EdgeType.FIELD, EdgeType.FIELD], false, [[0,1]], []),
	
	TileDef.new(0, 2, 5, [EdgeType.FIELD, EdgeType.FIELD, EdgeType.CITY, EdgeType.FIELD], false, [], [[2]]),
	TileDef.new(1, 2, 4, [EdgeType.CITY, EdgeType.ROAD, EdgeType.FIELD, EdgeType.ROAD], false, [[1,3]], [[0]]),
	TileDef.new(2, 2, 3, [EdgeType.ROAD, EdgeType.ROAD, EdgeType.FIELD, EdgeType.CITY], false, [[0,1]], [[3]]),
	TileDef.new(3, 2, 3, [EdgeType.ROAD, EdgeType.ROAD, EdgeType.ROAD, EdgeType.CITY], false, [[0], [1], [2]], [[3]]),
	TileDef.new(4, 2, 8, [EdgeType.ROAD, EdgeType.FIELD, EdgeType.ROAD, EdgeType.FIELD], false, [[0,2]], []),
	
	TileDef.new(0, 3, 3, [EdgeType.CITY, EdgeType.FIELD, EdgeType.CITY, EdgeType.FIELD], false, [], [[0],[2]]),
	TileDef.new(1, 3, 4, [EdgeType.FIELD, EdgeType.FIELD, EdgeType.FIELD, EdgeType.FIELD], true,[],[]),
	TileDef.new(2, 3, 3, [EdgeType.FIELD, EdgeType.ROAD, EdgeType.ROAD, EdgeType.CITY], false,[[1,2]], [[3]]),
	TileDef.new(3, 3, 2, [EdgeType.FIELD, EdgeType.FIELD, EdgeType.ROAD, EdgeType.FIELD], true, [[2]], []),
]

var deck: Array[int] = []
var discarded_tiles: Array[int] = []

const STARTING_TILE_INDEX = 12

func build_deck() -> void:
	deck.clear()
	discarded_tiles.clear()
	
	for i in range(TILE_DEFINITIONS.size()):
		if i == STARTING_TILE_INDEX:
			continue
		
		var tile_def = TILE_DEFINITIONS[i]
		for j in range(tile_def.count):
			deck.append(i)
	
	deck.shuffle()

func draw_tile() -> int:
	if deck.is_empty():
		return -1
	
	var tile_index = deck.pop_back()
	return tile_index

static func get_tile_def(tile_index: int) -> TileDef:
	if tile_index < 0 or tile_index >= TILE_DEFINITIONS.size():
		return null
	
	return TILE_DEFINITIONS[tile_index]

func is_empty() -> bool:
	return deck.is_empty()

func tiles_remaining() -> int:
	return deck.size()

static func total_tiles() -> int:
	var total = 0
	for tile_def in TILE_DEFINITIONS:
		total += tile_def.count
	return total

func return_tile_to_deck(tile_index: int) -> void:
	deck.append(tile_index)

func discard_tile(tile_index: int) -> void:
	discarded_tiles.append(tile_index)

func reset() -> void:
	build_deck()
