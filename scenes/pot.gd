class_name Pot
extends Button

signal tapped(pot: Pot)
signal harvested(amount: int)

enum State { EMPTY, GROWING, READY }
enum Result { NONE, PLANTED, HARVESTED }

var plant: PlantType
var state: State = State.EMPTY

var growth_counter: int

func _on_pressed() -> void:
	tapped.emit(self)

func advance_day(growth_per_day: int = 1) -> void:
	if state == State.GROWING:
		growth_counter += growth_per_day
		if growth_counter >= plant.growth_days:
			growth_counter = 0
			state = State.READY
	_refresh()

func interact(seed_type: PlantType) -> Result:
	var result := Result.NONE
	match state:
		State.EMPTY:
			plant = seed_type
			state = State.GROWING
			result = Result.PLANTED
			print("%s has been planted" % plant.display_name)
		State.READY:
			harvested.emit(plant.sell_price)
			print("%s has been harvested" % plant.display_name)	
			plant = null
			state = State.EMPTY
			result = Result.HARVESTED
		
		State.GROWING:
			print("Plant: %s Current growth: %s/%s" % [plant.display_name, growth_counter, plant.growth_days])
	_refresh()
	return result

func _refresh() -> void:
	match state:
		State.EMPTY:
			text = "Empty"
		State.GROWING:
			text = "%s %d/%d" % [plant.display_name, growth_counter, plant.growth_days]
		State.READY:
			text = "%s ready!" % plant.display_name
	
