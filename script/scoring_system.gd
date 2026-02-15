extends RefCounted
class_name ScoringSystem

var board_layer
var feature_validator: FeatureValidator

func _init(board):
	board_layer = board
	feature_validator = board.feature_validator

func check_completed_features() -> void:
	check_completed_roads()
	check_completed_cities()
	check_completed_monasteries()

# === DRUMURI ===

func check_completed_roads() -> void:
	var checked_tiles = {}
	
	for child in board_layer.placed_tiles.get_children():
		if child is Sprite2D:
			var tile_data = child.get_meta("tile_data") as Tile
			var key = "%d,%d" % [tile_data.grid_position.x, tile_data.grid_position.y]
			
			if key in checked_tiles:
				continue
			
			var edges = tile_data.get_edges()
			var road_segments = tile_data.get_road_segments()
			
			for segment in road_segments:
				if segment.is_empty():
					continue
				
				var edge_index = segment[0]
				
				if edges[edge_index] != TileDeck.EdgeType.ROAD:
					continue
				
				var meeple_pos = edge_index as Meeple.Position
				var road_tiles = feature_validator.explore_road(tile_data, meeple_pos)
				
				if road_tiles.is_empty():
					continue
				
				for road_tile in road_tiles:
					var road_key = "%d,%d" % [road_tile.grid_position.x, road_tile.grid_position.y]
					if road_key not in checked_tiles:
						checked_tiles[road_key] = true
				
				if is_road_complete(road_tiles):
					print("🎉 Drum complet găsit cu %d tile-uri!" % road_tiles.size())
					score_completed_road(road_tiles)
					# Continuă să verificăm alte drumuri

func is_road_complete(tiles: Array) -> bool:
	var open_ends = 0
	
	var road_edges_per_tile = {}

	for i in range(tiles.size()):
		var tile = tiles[i]
		var key = "%d,%d" % [tile.grid_position.x, tile.grid_position.y]
		road_edges_per_tile[key] = []
		
		var edges = tile.get_edges()
		var road_segments = tile.get_road_segments()
		
		for segment in road_segments:
			var segment_in_use = false
			
			for edge in segment:
				if edges[edge] != TileDeck.EdgeType.ROAD:
					continue
				
				var directions = [
					{"offset": Vector2i(0, -1), "edge": 0, "opposite": 2},
					{"offset": Vector2i(1, 0), "edge": 1, "opposite": 3},
					{"offset": Vector2i(0, 1), "edge": 2, "opposite": 0},
					{"offset": Vector2i(-1, 0), "edge": 3, "opposite": 1}
				]
				
				for dir in directions:
					if dir.edge == edge:
						var neighbor_pos = tile.grid_position + dir.offset
						var neighbor_key = "%d,%d" % [neighbor_pos.x, neighbor_pos.y]
						
						if neighbor_key in road_edges_per_tile or tiles.any(func(t): return t.grid_position == neighbor_pos):
							segment_in_use = true
							break
				
				if segment_in_use:
					break
			
			if segment_in_use or tiles.size() == 1:
				for edge in segment:
					if edges[edge] == TileDeck.EdgeType.ROAD:
						road_edges_per_tile[key].append(edge)
	
	for tile in tiles:
		var edges = tile.get_edges()
		var grid_pos = tile.grid_position
		var key = "%d,%d" % [grid_pos.x, grid_pos.y]
		var used_edges = road_edges_per_tile.get(key, [])
		
		var directions = [
			{"offset": Vector2i(0, -1), "edge": 0, "opposite": 2},
			{"offset": Vector2i(1, 0), "edge": 1, "opposite": 3},
			{"offset": Vector2i(0, 1), "edge": 2, "opposite": 0},
			{"offset": Vector2i(-1, 0), "edge": 3, "opposite": 1}
		]
		
		for dir in directions:
			var edge = dir.edge
			
			if edge not in used_edges:
				continue
			
			if edges[edge] == TileDeck.EdgeType.ROAD:
				var neighbor_pos = grid_pos + dir.offset
				var neighbor_sprite = board_layer.get_placed_tile_at(neighbor_pos)
				
				if neighbor_sprite == null:
					open_ends += 1
				else:
					var neighbor_tile = neighbor_sprite.get_meta("tile_data") as Tile
					var neighbor_edges = neighbor_tile.get_edges()
					
					if neighbor_edges[dir.opposite] != TileDeck.EdgeType.ROAD:
						open_ends += 1
	
	return open_ends == 0

func score_completed_road(tiles: Array) -> void:
	print("🔍 Verificare meeple-uri pe drum completat:")
	print("   - Număr tile-uri: %d" % tiles.size())
	print("   - Tile-uri în drum:")
	for t in tiles:
		print("     * Tile la poziția %s" % t.grid_position)
	
	var meeples_on_road = feature_validator.get_meeples_on_feature(tiles, FeatureValidator.FeatureType.ROAD)
	
	print("   - Număr meeple-uri găsite: %d" % meeples_on_road.size())
	
	if meeples_on_road.is_empty():
		print("⚠️ Niciun meeple pe acest drum - nu se acordă puncte")
		return
	
	var points = tiles.size()
	
	var meeple_counts = {}
	for meeple in meeples_on_road:
		print("   - Meeple găsit: Jucător %d pe poziția %s (tile %s)" % [
			meeple.owner_id, 
			Meeple.Position.keys()[meeple.position],
			meeple.tile_position
		])
		if meeple.owner_id not in meeple_counts:
			meeple_counts[meeple.owner_id] = 0
		meeple_counts[meeple.owner_id] += 1
	
	var max_count = 0
	var winners = []
	
	for player_id in meeple_counts.keys():
		var count = meeple_counts[player_id]
		if count > max_count:
			max_count = count
			winners = [player_id]
		elif count == max_count:
			winners.append(player_id)
	
	for winner_id in winners:
		var player = board_layer.players[winner_id]
		player.score += points
		print("✅ %s primește %d puncte! (Total: %d)" % [player.player_name, points, player.score])
	
	for meeple in meeples_on_road:
		return_meeple_to_player(meeple)

func return_meeple_to_player(meeple: Meeple) -> void:
	var found = false
	for child in board_layer.meeples_container.get_children():
		var meeple_data = child.get_meta("meeple_data", null) as Meeple
		if meeple_data and \
		   meeple_data.tile_position == meeple.tile_position and \
		   meeple_data.position == meeple.position and \
		   meeple_data.owner_id == meeple.owner_id:
			board_layer.meeples_container.remove_child(child)
			child.queue_free()
			found = true
			break
	
	if not found:
		print("⚠️ Nu am găsit meeple-ul pentru ștergere!")
	
	var player = board_layer.players[meeple.owner_id]
	player.return_meeple(meeple)

# === ORAȘE ===

func check_completed_cities() -> void:
	var checked_tiles = {}
	
	for child in board_layer.placed_tiles.get_children():
		if child is Sprite2D:
			var tile_data = child.get_meta("tile_data") as Tile
			var key = "%d,%d" % [tile_data.grid_position.x, tile_data.grid_position.y]
			
			if key in checked_tiles:
				continue
			
			var edges = tile_data.get_edges()
			var city_segments = tile_data.get_city_segments()
			
			for segment in city_segments:
				if segment.is_empty():
					continue
				
				var edge_index = segment[0]
				
				if edges[edge_index] != TileDeck.EdgeType.CITY:
					continue
				
				var meeple_pos = edge_index as Meeple.Position
				var city_tiles = feature_validator.explore_city(tile_data, meeple_pos)
				
				if city_tiles.is_empty():
					continue
				
				for city_tile in city_tiles:
					var city_key = "%d,%d" % [city_tile.grid_position.x, city_tile.grid_position.y]
					if city_key not in checked_tiles:
						checked_tiles[city_key] = true
				
				if is_city_complete(city_tiles):
					print("🏰 Oraș complet găsit cu %d tile-uri!" % city_tiles.size())
					score_completed_city(city_tiles)
					# Continuă să verificăm alte orașe

func is_city_complete(tiles: Array) -> bool:
	var open_edges = 0
	
	var city_edges_per_tile = {}
	
	for i in range(tiles.size()):
		var tile = tiles[i]
		var key = "%d,%d" % [tile.grid_position.x, tile.grid_position.y]
		city_edges_per_tile[key] = []
		
		var edges = tile.get_edges()
		var city_segments = tile.get_city_segments()
		
		for segment in city_segments:
			var segment_in_use = false
			
			for edge in segment:
				if edges[edge] != TileDeck.EdgeType.CITY:
					continue
				
				var directions = [
					{"offset": Vector2i(0, -1), "edge": 0, "opposite": 2},
					{"offset": Vector2i(1, 0), "edge": 1, "opposite": 3},
					{"offset": Vector2i(0, 1), "edge": 2, "opposite": 0},
					{"offset": Vector2i(-1, 0), "edge": 3, "opposite": 1}
				]
				
				for dir in directions:
					if dir.edge == edge:
						var neighbor_pos = tile.grid_position + dir.offset
						var neighbor_key = "%d,%d" % [neighbor_pos.x, neighbor_pos.y]
						
						if neighbor_key in city_edges_per_tile or tiles.any(func(t): return t.grid_position == neighbor_pos):
							segment_in_use = true
							break
				
				if segment_in_use:
					break
			
			if segment_in_use or tiles.size() == 1:
				for edge in segment:
					if edges[edge] == TileDeck.EdgeType.CITY:
						city_edges_per_tile[key].append(edge)
	
	# A doua trecere: verifică capete deschise
	for tile in tiles:
		var edges = tile.get_edges()
		var grid_pos = tile.grid_position
		var key = "%d,%d" % [grid_pos.x, grid_pos.y]
		var used_edges = city_edges_per_tile.get(key, [])
		
		var directions = [
			{"offset": Vector2i(0, -1), "edge": 0, "opposite": 2},
			{"offset": Vector2i(1, 0), "edge": 1, "opposite": 3},
			{"offset": Vector2i(0, 1), "edge": 2, "opposite": 0},
			{"offset": Vector2i(-1, 0), "edge": 3, "opposite": 1}
		]
		
		for dir in directions:
			var edge = dir.edge
			
			if edge not in used_edges:
				continue
			
			if edges[edge] == TileDeck.EdgeType.CITY:
				var neighbor_pos = grid_pos + dir.offset
				var neighbor_sprite = board_layer.get_placed_tile_at(neighbor_pos)
				
				if neighbor_sprite == null:
					open_edges += 1
				else:
					var neighbor_tile = neighbor_sprite.get_meta("tile_data") as Tile
					var neighbor_edges = neighbor_tile.get_edges()
					
					if neighbor_edges[dir.opposite] != TileDeck.EdgeType.CITY:
						open_edges += 1
	
	return open_edges == 0

func score_completed_city(tiles: Array) -> void:
	print("🔍 Verificare meeple-uri pe oraș completat:")
	print("   - Număr tile-uri: %d" % tiles.size())
	print("   - Tile-uri în oraș:")
	for t in tiles:
		print("     * Tile la poziția %s" % t.grid_position)
	
	var meeples_on_city = feature_validator.get_meeples_on_feature(tiles, FeatureValidator.FeatureType.CITY)
	
	print("   - Număr meeple-uri găsite: %d" % meeples_on_city.size())
	
	if meeples_on_city.is_empty():
		print("⚠️ Niciun meeple pe acest oraș - nu se acordă puncte")
		return
	
	# Calculează puncte: 2 puncte per tile + 2 puncte per shield (TODO: shields)
	var points = tiles.size() * 2
	
	var meeple_counts = {}
	for meeple in meeples_on_city:
		print("   - Meeple găsit: Jucător %d pe poziția %s (tile %s)" % [
			meeple.owner_id, 
			Meeple.Position.keys()[meeple.position],
			meeple.tile_position
		])
		if meeple.owner_id not in meeple_counts:
			meeple_counts[meeple.owner_id] = 0
		meeple_counts[meeple.owner_id] += 1
	
	var max_count = 0
	var winners = []
	
	for player_id in meeple_counts.keys():
		var count = meeple_counts[player_id]
		if count > max_count:
			max_count = count
			winners = [player_id]
		elif count == max_count:
			winners.append(player_id)
	
	for winner_id in winners:
		var player = board_layer.players[winner_id]
		player.score += points
		print("✅ %s primește %d puncte pentru oraș! (Total: %d)" % [player.player_name, points, player.score])
	
	for meeple in meeples_on_city:
		return_meeple_to_player(meeple)

# === MĂNĂSTIRI ===

func check_completed_monasteries() -> void:
	# Iterează prin toate tile-urile cu mănăstiri
	for child in board_layer.placed_tiles.get_children():
		if child is Sprite2D:
			var tile_data = child.get_meta("tile_data") as Tile
			var tile_def = TileDeck.TILE_DEFINITIONS[tile_data.tile_type]
			
			# Verifică dacă tile-ul are mănăstire
			if tile_def.has_monastery:
				if is_monastery_complete(tile_data):
					print("⛪ Mănăstire completă găsită la poziția %s!" % tile_data.grid_position)
					score_completed_monastery(tile_data)
					# Continuă să verificăm alte mănăstiri

func is_monastery_complete(tile: Tile) -> bool:
	var pos = tile.grid_position
	var adjacent_positions = [
		Vector2i(pos.x - 1, pos.y - 1),  # NW
		Vector2i(pos.x, pos.y - 1),      # N
		Vector2i(pos.x + 1, pos.y - 1),  # NE
		Vector2i(pos.x - 1, pos.y),      # W
		Vector2i(pos.x + 1, pos.y),      # E
		Vector2i(pos.x - 1, pos.y + 1),  # SW
		Vector2i(pos.x, pos.y + 1),      # S
		Vector2i(pos.x + 1, pos.y + 1),  # SE
	]
	
	for adj_pos in adjacent_positions:
		if board_layer.get_placed_tile_at(adj_pos) == null:
			return false
	
	return true

func score_completed_monastery(tile: Tile) -> void:
	# Caută meeple pe CENTER (mănăstire)
	var meeples_on_monastery = []
	
	for child in board_layer.meeples_container.get_children():
		var meeple_data = child.get_meta("meeple_data", null) as Meeple
		if meeple_data and \
		   meeple_data.tile_position == tile.grid_position and \
		   meeple_data.position == Meeple.Position.CENTER:
			meeples_on_monastery.append(meeple_data)
	
	print("🔍 Verificare meeple-uri pe mănăstire:")
	print("   - Tile mănăstire: %s" % tile.grid_position)
	print("   - Număr meeple-uri găsite: %d" % meeples_on_monastery.size())
	
	if meeples_on_monastery.is_empty():
		print("⚠️ Niciun meeple pe această mănăstire - nu se acordă puncte")
		return
	
	# Mănăstirea completă = 9 puncte (tile-ul + 8 vecini)
	var points = 9
	
	for meeple in meeples_on_monastery:
		var player = board_layer.players[meeple.owner_id]
		player.score += points
		print("✅ %s primește %d puncte pentru mănăstire! (Total: %d)" % [player.player_name, points, player.score])
		return_meeple_to_player(meeple)
