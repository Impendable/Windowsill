class_name RunState
extends RefCounted

const STARTING_COINS := 10
const STARTING_DAY := 1
const BASE_ACTIONS_PER_DAY := 6
const BASE_GROWTH_RATE := 1

var day := STARTING_DAY
var coins := STARTING_COINS
var actions_per_day := BASE_ACTIONS_PER_DAY
var remaining_actions := BASE_ACTIONS_PER_DAY
var has_growth_speed := false
var has_sell_boost := false
var selected_seed_id := ""



func growth_rate() -> int:
	return BASE_GROWTH_RATE + (1 if has_growth_speed else 0)

func sell_boost() -> bool:
	return true if has_sell_boost else false

func to_dict() -> Dictionary:
	var run_data := {
		"day": day,
		"coins": coins,
		"remaining_actions": remaining_actions,
		"actions_per_day": actions_per_day,
		"has_sell_boost": has_sell_boost,
		"has_growth_speed": has_growth_speed,
		"selected_seed_id": selected_seed_id,
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
	
	return run
