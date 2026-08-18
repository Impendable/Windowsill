class_name Pot
extends Button

@onready var main_path: NodePath = ^"/root/scenes/main"

signal tapped(pot: Pot)

enum State { EMPTY, GROWING, READY }
const GROWTH_DAYS := 3
const SELL_PRICE := 10

var state: State = State.EMPTY
var growth_counter: int

func _ready() -> void:
	main_path.next_day.connect(advance_day)

func _on_pressed() -> void:
	tapped.emit(self)

func advance_day():
	growth_counter += 1
	if growth_counter == GROWTH_DAYS:
		growth_counter = 0
		state = State.READY

func interact():
	match state:
		"EMPTY":
			print("Planting...")
			state = State.GROWING
		"READY":
			print("Harvesting...")
			state = State.EMPTY
		"GROWING":
			print("Plant is growing!")
	
func _refresh():
	self.text = State.keys()[state]
