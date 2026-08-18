extends Button

enum State { EMPTY, GROWING, READY }



func _on_pressed() -> void:
	print(State.keys()[0])
