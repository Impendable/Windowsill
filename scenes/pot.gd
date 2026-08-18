class_name Pot
extends Button

signal tapped(pot: Pot)
signal harvested(pot: Pot)

enum State { EMPTY, GROWING, READY }
enum Result { NONE, PLANTED, HARVESTED }
const GROWTH_DAYS := 3
const SELL_PRICE := 10

var state: State = State.EMPTY
var result: Result = Result.NONE

var growth_counter: int

func _on_pressed() -> void:
	tapped.emit(self)

func advance_day() -> void:
	if state == State.GROWING:
		growth_counter += 1
		if growth_counter >= GROWTH_DAYS:
			growth_counter = 0
			state = State.READY
	_refresh()

func interact() -> int:
	match state:
		State.EMPTY:
			print("Planting...")
			state = State.GROWING
			result = Result.PLANTED
		State.READY:
			print("Harvesting...")
			harvested.emit(self, SELL_PRICE)
			state = State.EMPTY
			result = Result.HARVESTED
		State.GROWING:
			print("Plant is growing!")
			result = Result.NONE
	_refresh()
	return result

func _refresh() -> void:
	self.text = State.keys()[state]
