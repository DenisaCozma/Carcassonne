extends RefCounted
class_name FeatureValidator

enum FeatureType {
	ROAD,
	CITY,
	FIELD,
	MONASTERY
}

var board_layer  

func _init(board):
	board_layer = board

func can_place_meeple_on_feature(tile: Tile, meeple_position: Meeple.Position) -> bool:
	var feature_type = get_feature_type_at_position(tile, meeple_position)
	
	if feature_type == FeatureType.MONASTERY:
		return can_place_on_monastery(tile)
	elif feature_type == FeatureType.ROAD:
		return can_place_on_road(tile, meeple_position)
	elif feature_type == FeatureType.CITY:
		return can_place_on_city(tile, meeple_position)
	elif feature_type == FeatureType.FIELD:
		return can_place_on_field(tile, meeple_position)
	
	return false

func get_feature_type_at_position(tile: Tile, position: Meeple.Position) -> FeatureType:
	if position == Meeple.Position.CENTER:
		var tile_def = TileDeck.get_tile_def(tile.tile_type)
		if tile_def.has_monastery:
			return FeatureType.MONASTERY
		else:
			return FeatureType.FIELD
	
	var world_edge = int(position)
	var local_edge_index = (world_edge - tile.rotation + 4) % 4

	var tile_def = TileDeck.get_tile_def(tile.tile_type)
	var base_edges = tile_def.edges
	var edge_type = base_edges[local_edge_index]

	match edge_type:
		TileDeck.EdgeType.ROAD:
			return FeatureType.ROAD
		TileDeck.EdgeType.CITY:
			return FeatureType.CITY
		TileDeck.EdgeType.FIELD:
			return FeatureType.FIELD
			
	return FeatureType.FIELD

func can_place_on_monastery(tile: Tile) -> bool:
	var meeples = get_meeples_on_tile(tile)
	for meeple in meeples:
		if meeple.position == Meeple.Position.CENTER:
			return false
	return true

func can_place_on_road(tile: Tile, position: Meeple.Position) -> bool:
	var connected_tiles = explore_road(tile, position)
	
	if connected_tiles.is_empty():
		return false

	var meeples_on_road = get_meeples_on_feature(connected_tiles, FeatureType.ROAD)
	
	return meeples_on_road.is_empty()

func explore_road(start_tile: Tile, start_position: Meeple.Position) -> Array:
	var result = []
	var visited = {}
	var queue = []
	
	var start_edge = int(start_position)
	var start_road_segments = start_tile.get_road_segments()
	var start_segment = get_segment_for_edge(start_road_segments, start_edge)
	
	if start_segment.is_empty():
		return []

	var segment_str = str(start_segment)
	var start_key = "%d,%d:%s" % [start_tile.grid_position.x, start_tile.grid_position.y, segment_str]
	visited[start_key] = true
	result.append(start_tile)

	var start_neighbors = get_road_neighbors_with_segments(start_tile, start_tile.grid_position, start_segment)
	for neighbor in start_neighbors:
		queue.append(neighbor)
	
	while not queue.is_empty():
		var current = queue.pop_front()
		var current_tile = current.tile
		var current_pos = current.position
		var current_segment = current.segment
		
		var seg_str = str(current_segment)
		var key = "%d,%d:%s" % [current_pos.x, current_pos.y, seg_str]
		
		if key in visited:
			continue
		
		visited[key] = true
		result.append(current_tile)
		
		var neighbors = get_road_neighbors_with_segments(current_tile, current_pos, current_segment)
		
		for neighbor in neighbors:
			var neighbor_seg_str = str(neighbor.segment)
			var neighbor_key = "%d,%d:%s" % [neighbor.position.x, neighbor.position.y, neighbor_seg_str]
			
			if neighbor_key not in visited:
				queue.append(neighbor)
	
	return result

func get_segment_for_edge(segments: Array, edge: int) -> Array:
	for segment in segments:
		if edge in segment:
			return segment
	return []

func get_road_neighbors_with_segments(tile: Tile, grid_pos: Vector2i, current_segment: Array) -> Array:
	var neighbors = []
	var edges = tile.get_edges()
	
	var directions = [
		{"offset": Vector2i(0, -1), "edge": 0, "opposite": 2},
		{"offset": Vector2i(1, 0), "edge": 1, "opposite": 3},
		{"offset": Vector2i(0, 1), "edge": 2, "opposite": 0},
		{"offset": Vector2i(-1, 0), "edge": 3, "opposite": 1}
	]
	
	for edge_index in current_segment:
		var edge_type = edges[edge_index]

		if edge_type != TileDeck.EdgeType.ROAD:
			continue

		var dir = null
		for d in directions:
			if d.edge == edge_index:
				dir = d
				break
		
		if dir == null:
			continue
		
		var neighbor_pos = grid_pos + dir.offset
		var neighbor_sprite = board_layer.get_placed_tile_at(neighbor_pos)
		
		if neighbor_sprite != null:
			var neighbor_tile = neighbor_sprite.get_meta("tile_data") as Tile
			var neighbor_edges = neighbor_tile.get_edges()
			
			if neighbor_edges[dir.opposite] == TileDeck.EdgeType.ROAD:
				var neighbor_road_segments = neighbor_tile.get_road_segments()
				var neighbor_segment = get_segment_for_edge(neighbor_road_segments, dir.opposite)
				
				if neighbor_segment.is_empty():
					continue
				
				neighbors.append({
					"tile": neighbor_tile,
					"position": neighbor_pos,
					"segment": neighbor_segment
				})
	
	return neighbors

func can_place_on_city(tile: Tile, position: Meeple.Position) -> bool:
	var connected_tiles = explore_city(tile, position)
	var meeples_on_city = get_meeples_on_feature(connected_tiles, FeatureType.CITY)
	return meeples_on_city.is_empty()

func explore_city(start_tile: Tile, start_position: Meeple.Position) -> Array:
	var result = []
	var visited = {}
	var queue = []
	
	var start_edge = int(start_position)
	var start_city_segments = start_tile.get_city_segments()
	var start_segment = get_segment_for_edge(start_city_segments, start_edge)
	
	if start_segment.is_empty():
		return []
	
	var segment_str = str(start_segment)
	var start_key = "%d,%d:%s" % [start_tile.grid_position.x, start_tile.grid_position.y, segment_str]
	visited[start_key] = true
	result.append(start_tile)
	
	var start_neighbors = get_city_neighbors_with_segments(start_tile, start_tile.grid_position, start_segment)
	for neighbor in start_neighbors:
		queue.append(neighbor)
	
	while not queue.is_empty():
		var current = queue.pop_front()
		var current_tile = current.tile
		var current_pos = current.position
		var current_segment = current.segment
		
		var seg_str = str(current_segment)
		var key = "%d,%d:%s" % [current_pos.x, current_pos.y, seg_str]
		
		if key in visited:
			continue
		
		visited[key] = true
		result.append(current_tile)
		
		var neighbors = get_city_neighbors_with_segments(current_tile, current_pos, current_segment)
		for neighbor in neighbors:
			var neighbor_seg_str = str(neighbor.segment)
			var neighbor_key = "%d,%d:%s" % [neighbor.position.x, neighbor.position.y, neighbor_seg_str]
			if neighbor_key not in visited:
				queue.append(neighbor)
	
	return result

func get_city_neighbors_with_segments(tile: Tile, grid_pos: Vector2i, current_segment: Array) -> Array:
	var neighbors = []
	var edges = tile.get_edges()
	
	var directions = [
		{"offset": Vector2i(0, -1), "edge": 0, "opposite": 2},
		{"offset": Vector2i(1, 0), "edge": 1, "opposite": 3},
		{"offset": Vector2i(0, 1), "edge": 2, "opposite": 0},
		{"offset": Vector2i(-1, 0), "edge": 3, "opposite": 1}
	]

	for edge_index in current_segment:
		var edge_type = edges[edge_index]

		if edge_type != TileDeck.EdgeType.CITY:
			continue

		var dir = null
		for d in directions:
			if d.edge == edge_index:
				dir = d
				break
		
		if dir == null:
			continue
		
		var neighbor_pos = grid_pos + dir.offset
		var neighbor_sprite = board_layer.get_placed_tile_at(neighbor_pos)
		
		if neighbor_sprite != null:
			var neighbor_tile = neighbor_sprite.get_meta("tile_data") as Tile
			var neighbor_edges = neighbor_tile.get_edges()

			if neighbor_edges[dir.opposite] == TileDeck.EdgeType.CITY:
				var neighbor_city_segments = neighbor_tile.get_city_segments()
				var neighbor_segment = get_segment_for_edge(neighbor_city_segments, dir.opposite)
				
				if neighbor_segment.is_empty():
					continue
				
				neighbors.append({
					"tile": neighbor_tile,
					"position": neighbor_pos,
					"segment": neighbor_segment
				})
	
	return neighbors

func can_place_on_field(tile: Tile, position: Meeple.Position) -> bool:
	return true

func get_meeples_on_tile(tile: Tile) -> Array:
	var meeples := []

	for child in board_layer.meeples_container.get_children():
		var meeple_data = child.get_meta("meeple_data")
		if meeple_data == null:
			continue

		if meeple_data.tile_position == tile.grid_position:
			meeples.append(meeple_data)

	return meeples

func get_meeples_on_feature(tiles: Array, feature_type: FeatureType) -> Array:
	var meeples = []
	
	for tile in tiles:
		var tile_meeples = get_meeples_on_tile(tile)
		for meeple in tile_meeples:
			var meeple_feature = get_feature_type_at_position(tile, meeple.position)
			if meeple_feature == feature_type:
				meeples.append(meeple)
	
	return meeples
