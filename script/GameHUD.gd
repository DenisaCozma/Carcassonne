extends Control
class_name GameHUD

# Referințe la nodurile UI (trebuie configurate în editor)
@onready var player1_label: Label = $RightPanel/VBoxContainer/Player1Info
@onready var player2_label: Label = $RightPanel/VBoxContainer/Player2Info
@onready var tiles_remaining_label: Label = $RightPanel/VBoxContainer/TilesRemaining
@onready var current_turn_label: Label = $RightPanel/VBoxContainer/CurrentTurn

# Referință către BoardLayer
var board_layer: Node2D

func _ready():
	# Găsește BoardLayer automat (încearcă mai multe path-uri)
	board_layer = get_node_or_null("../../BoardLayer")
	if not board_layer:
		board_layer = get_node_or_null("../BoardLayer")
	if not board_layer:
		board_layer = get_tree().root.get_node_or_null("Main/BoardLayer")
	
	if board_layer:
		update_hud()

func update_hud():

	if not board_layer:
		print("board_layer is null!")
		return

	if board_layer.players.size() >= 1:
		var p1 = board_layer.players[0]
		var p1_color_name = Meeple.Colors.keys()[p1.color]
		var p1_text = "%s (%s)\n   Score: %d | Meeple: %d/7" % [
			p1.player_name,
			p1_color_name,
			p1.score,
			p1.available_meeples
		]
		print("   - P1 text: %s" % p1_text)
		if player1_label:
			player1_label.text = p1_text
			print("Player1 label updated")
		else:
			print("player1_label is null!")
	
	if board_layer.players.size() >= 2:
		var p2 = board_layer.players[1]
		var p2_color_name = Meeple.Colors.keys()[p2.color]
		var p2_text = "%s (%s)\n   Score: %d | Meeple: %d/7" % [
			p2.player_name,
			p2_color_name,
			p2.score,
			p2.available_meeples
		]
		print("   - P2 text: %s" % p2_text)
		if player2_label:
			player2_label.text = p2_text
			print("Player2 label updated")
		else:
			print("player2_label is null!")
			
	var tiles_left = board_layer.tile_deck.tiles_remaining()
	var total_tiles = TileDeck.total_tiles() - 1  
	var tiles_text = "Tile-uri rămase: %d/%d" % [tiles_left, total_tiles]
	print("   - Tiles text: %s" % tiles_text)
	if tiles_remaining_label:
		tiles_remaining_label.text = tiles_text
		print(" Tiles label updated")
	else:
		print(" tiles_remaining_label is null!")
	

	var current_player = board_layer.get_current_player()
	var turn_text = "Tura: %s" % current_player.player_name
	print("   - Turn text: %s" % turn_text)
	if current_turn_label:
		current_turn_label.text = turn_text
		print("Turn label updated")
	else:
		print("  current_turn_label is null!")

func refresh():
	update_hud()
