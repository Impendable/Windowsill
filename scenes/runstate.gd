class_name RunState
extends RefCounted

const STARTING_COINS := 10
const STARTING_DAY := 1
const BASE_ACTIONS_PER_DAY := 6
const BASE_GROWTH_RATE := 1
const SELL_BOOST_MULTIPLIER := 1.25

var day := STARTING_DAY
var coins := STARTING_COINS
var actions_per_day := BASE_ACTIONS_PER_DAY
var remaining_actions := BASE_ACTIONS_PER_DAY
var has_growth_speed := false
var has_sell_boost := false
var selected_seed_id := ""
var inventory := {} #plant_id -> count



func growth_rate() -> int:
	return BASE_GROWTH_RATE + (1 if has_growth_speed else 0)


func sell_multiplier() -> float:
	return SELL_BOOST_MULTIPLIER if has_sell_boost else 1.0


func seed_count(plant_id: String) -> int:
	return int(inventory.get(plant_id, 0))


func add_seed(plant_id: String, amount := 1) -> void:
	inventory[plant_id] = seed_count(plant_id) + amount


func consume_seed(plant_id: String) -> void:
	var remaining := seed_count(plant_id) - 1
	if remaining > 0:
		inventory[plant_id] = remaining
	else:
		inventory.erase(plant_id)


func to_dict() -> Dictionary:
	var run_data := {
		"day": day,
		"coins": coins,
		"remaining_actions": remaining_actions,
		"actions_per_day": actions_per_day,
		"has_sell_boost": has_sell_boost,
		"has_growth_speed": has_growth_speed,
		"selected_seed_id": selected_seed_id,
		"inventory": inventory.duplicate()
	}
	return run_data
	
static func from_dict(data: Dictionary) -> RunState:
	var run := RunState.new()
	run.day = int(data.get("day", STARTING_DAY))
	run.coins = int(data.get("coins", STARTING_COINS))
	run.actions_per_day = int(data.get("actions_per_day", BASE_ACTIONS_PER_DAY))
	run.remaining_actions = int(data.get("remaining_actions", run.actions_per_day))
	run.has_growth_speed = data.get("has_growth_speed", false)
	run.has_sell_boost = data.get("has_sell_boost", false)
	run.selected_seed_id = data.get("selected_seed_id", "")
	var raw: Dictionary = data.get("inventory", {})
	for id in raw:
		run.inventory[id] = int(raw[id])
	
	return run
