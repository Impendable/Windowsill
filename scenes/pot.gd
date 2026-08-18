class_name Pot
extends Button

@onready var main_path: NodePath = ^"/root/scenes/main"

signal tapped(pot: Pot)

enum State { EMPTY, GROWING, READY }
const GROWTH_DAYS := 3
const SELL_PRICE := 10

var state: State = State.EMPTY
var growth_counter: int

func _on_pressed() -> void:
	tapped.emit(self)

func advance_day():
	if state == State.GROWING:
		growth_counter += 1
	if growth_counter >= GROWTH_DAYS:
		growth_counter = 0
		state = State.READY
	_refresh()

func interact():
	match state:
		State.EMPTY:
			print("Planting...")
			state = State.GROWING
			_refresh()
			return 0
		State.READY:
			print("Harvesting...")
			state = State.EMPTY
			_refresh()
			return SELL_PRICE
		State.EMPTY:
			print("Plant is growing!")
			_refresh()
			return 0
	
func _refresh():
	self.text = State.keys()[state]
