extends Control

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1
const POT_SCENE := preload("res://scenes/pot.tscn")
const STARTER_SEED := preload("res://data/basil.tres")
const BASE_ACTIONS_PER_DAY := 5
const BASE_GROWTH_RATE := 1
const STARTING_COINS := 0
const STARTING_DAY := 1
const RUN_LENGTH := 7


@export var available_plants: Array[PlantType]
@export var selected_seed: PlantType

@onready var header: HeaderUI = %HeaderUI
@onready var shop: ShopScreen = %ShopScreen
@onready var summary: SummaryScreen = %SummaryScreen
@onready var pot_grid: HBoxContainer = %PotGrid
@onready var day_screen: Control = %DayScreen

enum Screen { DAY, SHOP, SUMMARY }

var current_screen: Screen = Screen.DAY
var current_day := STARTING_DAY
var current_coins := STARTING_COINS
var actions_per_day := BASE_ACTIONS_PER_DAY
var remaining_actions := BASE_ACTIONS_PER_DAY
var has_growth_speed := false
var has_extra_action := false
var best_score: int
var plants_by_id := {}

func _ready() -> void:
	#Lookup plants for load prep
	for plant: PlantType in available_plants:
		plants_by_id[plant.id] = plant
	
	#Check all pots in scene for any signals
	for pot: Pot in pot_grid.get_children():
		_connect_pot(pot)
		
	#Connect all signals
	shop.seed_selected.connect(_on_seed_selected)
	shop.upgrade_requested.connect(_on_upgrade_requested)
	
	#Build Shop with all plants
	shop.build(available_plants)
	
	#Set screen to starting screen
	if load_game():
		change_screen(Screen.DAY)
	else:
		_start_new_run()


func _connect_pot(pot: Pot) -> void:
	pot.tapped.connect(_on_pot_tapped)
	pot.harvested.connect(_sell_plant)

#Change between shop and day screens
func change_screen(screen: Screen) -> void:
	current_screen = screen
	day_screen.visible = current_screen == Screen.DAY
	shop.visible = current_screen == Screen.SHOP
	summary.visible = current_screen == Screen.SUMMARY
	_refresh()


func _refresh() -> void:
	if selected_seed.seed_cost > current_coins:
		selected_seed = STARTER_SEED
	header.update(current_day, RUN_LENGTH, current_coins, remaining_actions)
	shop.refresh(current_coins, has_growth_speed, has_extra_action, selected_seed)
	summary.update(calc_score(), best_score)


func _on_pot_tapped(pot: Pot) -> void:
	#Check if you have enough actions
	if remaining_actions <= 0:
		print("No actions remaining")
		return
	match pot.interact(selected_seed):
		Pot.Result.PLANTED:
			current_coins -= selected_seed.seed_cost
			remaining_actions -= 1
		Pot.Result.HARVESTED:
			remaining_actions -= 1
	_refresh()


func _on_end_day_pressed() -> void:
	save_game()
	if current_day < RUN_LENGTH:
		change_screen(Screen.SHOP)
	else:
		if calc_score() > best_score:
			best_score = calc_score()
		_refresh()
		change_screen(Screen.SUMMARY)


func _on_start_day_pressed() -> void:
	current_day += 1
	for pot: Pot in pot_grid.get_children():
		pot.advance_day(growing_rate())
	remaining_actions = actions_per_day
	change_screen(Screen.DAY)


func _on_seed_selected(plant: PlantType) -> void:
	selected_seed = plant
	_refresh()


func _on_upgrade_requested(upgrade: ShopScreen.Upgrade) -> void:
	match upgrade:
		ShopScreen.Upgrade.GROWTH_SPEED_UP:
			if has_growth_speed or current_coins < ShopScreen.GROWTH_SPEED_COST:
				return
			current_coins -= ShopScreen.GROWTH_SPEED_COST
			has_growth_speed = true
			
		ShopScreen.Upgrade.EXTRA_ACTION:
			if has_extra_action or current_coins < ShopScreen.EXTRA_ACTION_COST:
				return
			current_coins -= ShopScreen.EXTRA_ACTION_COST
			has_extra_action = true
			actions_per_day += 1
	_refresh()

#Increase coin amount when selling/harvesting
func _sell_plant(amount: int) -> void:
	current_coins += amount
	_refresh()


func growing_rate() -> int:
	return BASE_GROWTH_RATE + (1 if has_growth_speed else 0)


func _start_new_run() -> void:
	current_coins = STARTING_COINS
	current_day = STARTING_DAY
	remaining_actions = BASE_ACTIONS_PER_DAY
	actions_per_day = BASE_ACTIONS_PER_DAY
	has_growth_speed = false
	has_extra_action = false
	selected_seed = STARTER_SEED
	for pot: Pot in pot_grid.get_children():
		pot.reset()
	change_screen(Screen.DAY)
	save_game()


func calc_score() -> int:
	var unharvested := 0
	for pot: Pot in pot_grid.get_children():
		if pot.plant != null:
			@warning_ignore("integer_division")
			unharvested += pot.plant.seed_cost / 2
	return current_coins + unharvested


func clear_run() -> void:
	var data := {
		"version": SAVE_VERSION,
		"best_score": best_score
	}
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data, "\t"))


func save_game() -> void:
	var data := {
		"version": SAVE_VERSION,
		"best_score": best_score,
		"current_day": current_day,
		"current_coins": current_coins,
		"remaining_actions": remaining_actions,
		"actions_per_day": actions_per_day,
		"has_extra_action": has_extra_action,
		"selected_seed": selected_seed,
	}
	
	var pot_data := []
	for pot: Pot in pot_grid.get_children():
		pot_data.append(pot.to_dict())
	data["pots"] = pot_data
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not open save file: %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(data, "\t"))


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
		
	var data = JSON.parse_string(file.get_as_text())
	if data == null:
		push_error("Save file is corrupt")
		return false
	
	if int(data.get("version", 0)) != SAVE_VERSION:
		return false
		
	best_score = int(data.get("best_score", 0))
	
	if not data.has("run"):
		return false
		
	var run: Dictionary = data["run"]
	current_day = int(run.get("current_day", STARTING_DAY))
	current_coins = int(run.get("current_coins", STARTING_COINS))
	actions_per_day = int(run.get("actions_per_day", BASE_ACTIONS_PER_DAY))
	remaining_actions = int(run.get("remaining_actions", BASE_ACTIONS_PER_DAY))
	has_growth_speed = run.get("has_growth_speed", false)
	has_extra_action = run.get("has_extra_action", false)
	selected_seed = run.get("selected_seed", STARTER_SEED)
	
	var pots := pot_grid.get_children()
	var saved_pots: Array = run.get("pots", [])
	for i in mini(pots.size(), saved_pots.size()):
		pots[i].from_dict(saved_pots[i], plants_by_id)

	return true
