extends RefCounted
class_name GameState

var game  

func _init(g):
	game = g

func enter() -> void:
	pass

func exit() -> void:
	pass

func handle_input(event: InputEvent) -> void:
	pass

func update(delta: float) -> void:
	pass
