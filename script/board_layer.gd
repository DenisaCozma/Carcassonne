extends Node2D

@export var tile_size := 128
@export var meeple_size := 48

var tile_deck: TileDeck = TileDeck.new()
var current_state: GameState
var pending_state_change: GameState = null

var players: Array[Player] = []
var current_player_index: int = 0
var feature_validator: FeatureValidator
var scoring_system: ScoringSystem

@onready var preview_tile: Sprite2D = $PreviewTile
@onready var placed_tiles: Node2D = $PlacedTiles
@onready var meeples_container: Node2D = $Meeples
@onready var meeple_template: Sprite2D = $MeepleTemplate

var game_hud: Control = null

var current_tile: Tile = null
var last_placed_tile_position: Vector2i = Vector2i.ZERO

func _ready():
	feature_validator = FeatureValidator.new(self)
	scoring_system = ScoringSystem.new(self)
	setup_players()
	tile_deck.build_deck()
	place_starting_tile()
	game_hud = get_node_or_null("../CanvasLayer/HUD")
	if not game_hud:
		game_hud = get_node_or_null("../UI/HUD")
	if not game_hud:
		game_hud = get_tree().root.get_node_or_null("Main/CanvasLayer/HUD")
	
	change_state(TurnState.new(self))
	update_hud()

func setup_players() -> void:
	var colors = [Meeple.Colors.RED, Meeple.Colors.BLUE, Meeple.Colors.GREEN, Meeple.Colors.YELLOW, Meeple.Colors.GRAY]
	colors.shuffle()
	
	var player1 = Player.new(0, "Jucător 1", colors[0])
	var player2 = Player.new(1, "Jucător 2", colors[1])
	
	players.append(player1)
	players.append(player2)

func get_current_player() -> Player:
	return players[current_player_index]

func next_player() -> void:
	current_player_index = (current_player_index + 1) % players.size()
	var current = get_current_player()
	update_hud()

func place_starting_tile() -> void:
	var starting_tile = Tile.new(TileDeck.STARTING_TILE_INDEX, 0)
	starting_tile.grid_position = Vector2i(0, 0)
	
	var tile_def = tile_deck.get_tile_def(TileDeck.STARTING_TILE_INDEX)
	
	var placed_tile := Sprite2D.new()
	placed_tile.texture = preview_tile.texture
	placed_tile.region_enabled = true
	placed_tile.region_rect = Rect2(
		tile_def.col * tile_size,
		tile_def.row * tile_size,
		tile_size,
		tile_size
	)
	placed_tile.global_position = Vector2(0, 0)
	placed_tile.rotation = 0
	placed_tile.set_meta("tile_data", starting_tile)
	placed_tiles.add_child(placed_tile)
	
func _input(event):
	if current_state:
		current_state.handle_input(event)
	
	if event is InputEventMouseButton and event.pressed:
		get_viewport().set_input_as_handled()

func _process(delta):
	if pending_state_change:
		change_state(pending_state_change)
		pending_state_change = null

	if current_state:
		current_state.update(delta)

func change_state(new_state: GameState) -> void:
	if current_state:
		current_state.exit()
	current_state = new_state
	current_state.enter()

func draw_tile() -> void:
	if tile_deck.is_empty():
		print("Jocul s-a terminat! Nu mai sunt tile-uri!")
		return

	var tile_index = tile_deck.draw_tile()
	if tile_index == -1:
		return
	
	current_tile = Tile.new(tile_index, 0)
	var tile_def = tile_deck.get_tile_def(tile_index)

	preview_tile.region_enabled = true
	preview_tile.region_rect = Rect2(
		tile_def.col * tile_size,
		tile_def.row * tile_size,
		tile_size,
		tile_size
	)
	preview_tile.rotation = 0
	preview_tile.visible = true
	update_hud()

func update_preview_position() -> void:
	if current_tile == null:
		return
		
	var mouse_pos = get_global_mouse_position()
	var col = round(mouse_pos.x / tile_size)
	var row = round(mouse_pos.y / tile_size)
	var snapped_pos = Vector2(col * tile_size, row * tile_size)
	
	preview_tile.global_position = snapped_pos
	preview_tile.position = snapped_pos
	current_tile.grid_position = Vector2i(col, row)
	
	if can_place_tile(current_tile.grid_position):
		preview_tile.modulate = Color(1, 1, 1, 1)
	else:
		if is_position_occupied(current_tile.grid_position):
			preview_tile.modulate = Color(1, 0, 0, 0.5)
		elif not has_adjacent_tile(current_tile.grid_position) and placed_tiles.get_child_count() > 0:
			preview_tile.modulate = Color(1, 0.5, 0, 0.7)
		else:
			preview_tile.modulate = Color(1, 0.3, 0.3, 0.7)

func rotate_preview() -> void:
	if current_tile == null:
		return
	
	current_tile.rotate_clockwise()
	preview_tile.rotation = current_tile.get_rotation_radians()

func is_mouse_over_preview() -> bool:
	if not preview_tile.visible or current_tile == null:
		return false
	
	var mouse_pos = preview_tile.get_local_mouse_position()
	return preview_tile.get_rect().has_point(mouse_pos)

func place_preview_tile() -> void:
	if current_tile == null:
		return
	
	var placed_tile := Sprite2D.new()
	placed_tile.texture = preview_tile.texture
	placed_tile.region_enabled = preview_tile.region_enabled
	placed_tile.region_rect = preview_tile.region_rect
	placed_tile.global_position = preview_tile.global_position
	placed_tile.rotation = preview_tile.rotation
	placed_tile.scale = preview_tile.scale
	placed_tile.set_meta("tile_data", current_tile)
	placed_tiles.add_child(placed_tile)
	
	last_placed_tile_position = current_tile.grid_position
	
	tile_deck.discard_tile(current_tile.tile_type)
	update_hud()

func end_turn() -> void:
	current_tile = null
	preview_tile.rotation = 0
	preview_tile.modulate = Color.WHITE
	preview_tile.visible = false

func get_placed_tile_at(grid_pos: Vector2i) -> Sprite2D:
	for child in placed_tiles.get_children():
		if child is Sprite2D:
			var tile_data = child.get_meta("tile_data", null) as Tile
			if tile_data and tile_data.grid_position == grid_pos:
				return child
	return null

func is_position_occupied(grid_pos: Vector2i) -> bool:
	return get_placed_tile_at(grid_pos) != null

func has_adjacent_tile(grid_pos: Vector2i) -> bool:
	var adjacent_positions = [
		Vector2i(grid_pos.x + 1, grid_pos.y),
		Vector2i(grid_pos.x - 1, grid_pos.y),
		Vector2i(grid_pos.x, grid_pos.y + 1),
		Vector2i(grid_pos.x, grid_pos.y - 1),
	]
	
	for adj_pos in adjacent_positions:
		if is_position_occupied(adj_pos):
			return true
	
	return false

func can_place_tile(grid_pos: Vector2i) -> bool:
	if is_position_occupied(grid_pos):
		return false
	
	if placed_tiles.get_child_count() == 0:
		return true
	
	if not has_adjacent_tile(grid_pos):
		return false
	
	return matches_adjacent_tiles(current_tile, grid_pos)

func matches_adjacent_tiles(tile: Tile, grid_pos: Vector2i) -> bool:
	if tile == null:
		return false
	
	var tile_edges = tile.get_edges()
	
	var north_tile = get_placed_tile_at(Vector2i(grid_pos.x, grid_pos.y - 1))
	if north_tile != null:
		var north_tile_data = north_tile.get_meta("tile_data") as Tile
		var north_edges = north_tile_data.get_edges()
		if tile_edges[0] != north_edges[2]:
			return false
	
	var east_tile = get_placed_tile_at(Vector2i(grid_pos.x + 1, grid_pos.y))
	if east_tile != null:
		var east_tile_data = east_tile.get_meta("tile_data") as Tile
		var east_edges = east_tile_data.get_edges()
		if tile_edges[1] != east_edges[3]:
			return false
	
	var south_tile = get_placed_tile_at(Vector2i(grid_pos.x, grid_pos.y + 1))
	if south_tile != null:
		var south_tile_data = south_tile.get_meta("tile_data") as Tile
		var south_edges = south_tile_data.get_edges()
		if tile_edges[2] != south_edges[0]:
			return false
	
	var west_tile = get_placed_tile_at(Vector2i(grid_pos.x - 1, grid_pos.y))
	if west_tile != null:
		var west_tile_data = west_tile.get_meta("tile_data") as Tile
		var west_edges = west_tile_data.get_edges()
		if tile_edges[3] != west_edges[1]:
			return false
	
	return true

func get_all_placed_tiles() -> Array[Sprite2D]:
	var tiles: Array[Sprite2D] = []
	for child in placed_tiles.get_children():
		if child is Sprite2D:
			tiles.append(child)
	return tiles

func start_new_game() -> void:
	for child in placed_tiles.get_children():
		child.queue_free()
	
	for child in meeples_container.get_children():
		child.queue_free()
	
	current_player_index = 0
	for player in players:
		player.available_meeples = 7
		player.placed_meeples.clear()
	
	tile_deck.reset()
	place_starting_tile()
	change_state(TurnState.new(self))

func show_meeple_placement_ui() -> void:
	var tile_sprite = get_placed_tile_at(last_placed_tile_position)
	if tile_sprite != null:
		var tile_data = tile_sprite.get_meta("tile_data") as Tile
		var tile_def = tile_deck.get_tile_def(tile_data.tile_type)
		
		if tile_def and tile_def.has_monastery:
			print("Afișare UI pentru plasare meeple...")
			print("Apasă: 1=Nord, 2=Est, 3=Sud, 4=Vest, 5=Mănăstire, 0=Skip")
		else:
			print("Afișare UI pentru plasare meeple...")
			print("Apasă: 1=Nord, 2=Est, 3=Sud, 4=Vest, 0=Skip")
	else:
		print("Afișare UI pentru plasare meeple...")
		print("Apasă: 1=Nord, 2=Est, 3=Sud, 4=Vest, 0=Skip")

func place_meeple_at(position: Meeple.Position) -> void:
	var player = get_current_player()
	
	if not player.can_place_meeple():
		print("Nu mai ai meeple-uri disponibile!")
		return
	
	# Obține tile-ul pe care vrei să plasezi
	var tile_sprite = get_placed_tile_at(last_placed_tile_position)
	if tile_sprite == null:
		print("Tile-ul nu a fost găsit!")
		return
	
	var tile_data = tile_sprite.get_meta("tile_data") as Tile
	var tile_def = tile_deck.get_tile_def(tile_data.tile_type)
	
	# Verifică dacă încearcă să plaseze pe CENTER fără mănăstire
	if position == Meeple.Position.CENTER:
		if tile_def == null or not tile_def.has_monastery:
			print("Acest tile nu are mănăstire! Nu poți plasa meeple pe CENTER.")
			return
	
	# VALIDARE: Verifică dacă caracteristica e deja ocupată
	if not feature_validator.can_place_meeple_on_feature(tile_data, position):
		print("Nu poți plasa meeple! Această caracteristică e deja ocupată de alt jucător!")
		return
	
	var meeple = Meeple.new(player.color, position, player.player_id)
	meeple.tile_position = last_placed_tile_position
	
	create_meeple_sprite(meeple)
	player.place_meeple(meeple)
	
	update_hud()
	finish_turn()

func skip_meeple_placement() -> void:
	finish_turn()

func finish_turn() -> void:
	call_deferred("check_and_score_completed_features")
	
	end_turn()
	next_player()
	pending_state_change = TurnState.new(self)

func check_and_score_completed_features() -> void:
	scoring_system.check_completed_features()
	update_hud()

func create_meeple_sprite(meeple: Meeple) -> void:
	var meeple_sprite = Sprite2D.new()
	meeple_sprite.texture = meeple_template.texture
	meeple_sprite.region_enabled = true
	meeple_sprite.region_rect = Rect2(meeple.color * 80, 0, 80, 80)
	meeple_sprite.scale = Vector2(meeple_size / 80.0, meeple_size / 80.0)
	
	var tile_world_pos = Vector2(
		last_placed_tile_position.x * tile_size,
		last_placed_tile_position.y * tile_size
	)
	
	var offset = Vector2.ZERO
	match meeple.position:
		Meeple.Position.NORTH:
			offset = Vector2(0, -64)
		Meeple.Position.EAST:
			offset = Vector2(64, 0) 
		Meeple.Position.SOUTH:
			offset = Vector2(0, 64)
		Meeple.Position.WEST:
			offset = Vector2(-64, 0)
		Meeple.Position.CENTER:
			offset = Vector2(0, 0)
	
	meeple_sprite.global_position = tile_world_pos + offset
	meeple_sprite.set_meta("meeple_data", meeple)
	meeples_container.add_child(meeple_sprite)

func update_hud():
	if game_hud and game_hud.has_method("refresh"):
		game_hud.refresh()
