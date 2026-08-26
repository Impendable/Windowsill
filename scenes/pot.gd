class_name Pot
extends Button

@onready var plant_sprite: TextureRect = %PlantSprite

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
		State.READY:
			harvested.emit(plant.sell_price)
			plant = null
			state = State.EMPTY
			result = Result.HARVESTED
		State.GROWING:
			pass
	_refresh()
	return result


func _refresh() -> void:
	match state:
		State.EMPTY:
			plant_sprite.visible = false
		State.GROWING:
			if float(growth_counter) / plant.growth_days <= 0.5:
				plant_sprite.texture = plant.planted_texture
			else:
				plant_sprite.texture = plant.growing_texture
			plant_sprite.visible = true
			
		State.READY:
			plant_sprite.texture = plant.ready_texture
			plant_sprite.visible = true


func reset() -> void:
	state = State.EMPTY
	plant = null
	growth_counter = 0
	_refresh()


func to_dict() -> Dictionary:
	return {
		"plant_id": plant.id if plant != null else "",
		"state": state,
		"growth_counter": growth_counter,
	}


func from_dict(data: Dictionary, plants_by_id: Dictionary) -> void:
	var loaded := int(data.get("state", State.EMPTY))
	plant = plants_by_id.get(data.get("plant_id", ""))
	if not State.values().has(loaded):
		loaded = State.EMPTY
	state = loaded as State
	growth_counter = int(data.get("growth_counter", 0))
	if plant == null:
		state = State.EMPTY
		growth_counter = 0
	_refresh()
