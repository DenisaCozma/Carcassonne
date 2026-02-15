extends Resource
class_name Meeple

enum Position {
	NORTH,
	EAST,
	SOUTH,
	WEST,
	CENTER
}

enum Colors {
	BLUE = 0,
	GREEN = 1,
	YELLOW = 2,
	RED = 3,
	GRAY = 4
}

var color: Colors
var position: Position
var owner_id: int
var tile_position: Vector2i

func _init(c: Colors, pos: Position, owner: int):
	color = c
	position = pos
	owner_id = owner
