extends GameState
class_name TurnState

enum Phase {
	DRAW,
	PREVIEW,
	MEEPLE_PLACEMENT
}

var phase := Phase.DRAW

func enter():
	game.draw_tile()
	phase = Phase.PREVIEW

func update(delta):
	if phase == Phase.PREVIEW:
		game.update_preview_position()

func handle_input(event):
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:
		
		if phase == Phase.PREVIEW:
			game.rotate_preview()
		
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_RIGHT \
	and event.pressed:
		
		if phase == Phase.PREVIEW:
			if game.current_tile and game.can_place_tile(game.current_tile.grid_position):
				game.place_preview_tile()
				phase = Phase.MEEPLE_PLACEMENT
				game.show_meeple_placement_ui()
			else:
				print("❌ Plasare invalidă - alege o poziție validă!")
	
	if event is InputEventKey and event.pressed and phase == Phase.MEEPLE_PLACEMENT:
		match event.keycode:
			KEY_1, KEY_KP_1:
				game.place_meeple_at(Meeple.Position.NORTH)
			KEY_2, KEY_KP_2:
				game.place_meeple_at(Meeple.Position.EAST)
			KEY_3, KEY_KP_3:
				game.place_meeple_at(Meeple.Position.SOUTH)
			KEY_4, KEY_KP_4:
				game.place_meeple_at(Meeple.Position.WEST)
			KEY_5, KEY_KP_5:
				game.place_meeple_at(Meeple.Position.CENTER)
			KEY_0, KEY_KP_0, KEY_SPACE:
				game.skip_meeple_placement()
