class_name Pot
extends Button

signal tapped(pot: Pot)

enum State { EMPTY, GROWING, READY }

var state: State = State.EMPTY


func _on_pressed() -> void:
	tapped.emit(self)
