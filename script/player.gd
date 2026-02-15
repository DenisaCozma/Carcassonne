extends Resource
class_name Player

var player_id: int
var player_name: String
var color: Meeple.Colors
var available_meeples: int = 7
var placed_meeples: Array[Meeple] = []
var score : int = 0

func _init(id: int, name: String, player_color: Meeple.Colors):
	player_id = id
	player_name = name
	color = player_color

func can_place_meeple() -> bool:
	return available_meeples > 0

func place_meeple(meeple: Meeple) -> void:
	if available_meeples > 0:
		available_meeples -= 1
		placed_meeples.append(meeple)

func return_meeple(meeple: Meeple) -> void:
	var index = placed_meeples.find(meeple)
	if index != -1:
		placed_meeples.remove_at(index)
		available_meeples += 1
