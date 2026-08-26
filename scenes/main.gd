extends Control

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1
const POT_SCENE := preload("res://scenes/pot.tscn")
const STARTER_SEED := preload("res://data/basil.tres")
const BASE_ACTIONS_PER_DAY := 6
const BASE_GROWTH_RATE := 1
const STARTING_COINS := 10
const STARTING_DAY := 1
const RUN_LENGTH := 14


@export var available_plants: Array[PlantType]
@export var selected_seed: PlantType

@onready var header: HeaderUI = %HeaderUI
@onready var day: DayScreen = %DayScreen
@onready var shop: ShopScreen = %ShopScreen
@onready var settings: SettingScreen = %SettingScreen
@onready var summary: SummaryScreen = %SummaryScreen
@onready var pot_grid: HBoxContainer = %PotGrid
@onready var day_screen: Control = %DayScreen
@onready var harvest_sound: AudioStreamPlayer = %HarvestSound
@onready var bg_music: AudioStreamPlayer = %BGMusic

enum Screen { DAY, SHOP, SUMMARY, SETTINGS }

var current_screen: Screen = Screen.DAY
var previous_screen: Screen = Screen.DAY
var current_day := STARTING_DAY
var current_coins := STARTING_COINS
var actions_per_day := BASE_ACTIONS_PER_DAY
var remaining_actions := BASE_ACTIONS_PER_DAY
var has_growth_speed := false
var has_sell_boost := false
var best_score: int
var plants_by_id := {}

func _ready() -> void:
	#Start music immediately
	bg_music.play()
	#Lookup plants for load prep
	for plant: PlantType in available_plants:
		plants_by_id[plant.id] = plant
	
	#Check all pots in scene for any signals
	for pot: Pot in pot_grid.get_children():
		_connect_pot(pot)
		
	#Connect all signals
	day.seed_selected.connect(_on_seed_selected)
	shop.upgrade_requested.connect(_on_upgrade_requested)
	settings.closed.connect(_on_settings_closed)
	
	#Build Shop with all plants
	day.build(available_plants)
	
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
	settings.visible = current_screen == Screen.SETTINGS
	_refresh()

#Refresh all screens and seed chosen if necessary
func _refresh() -> void:
	header.update(current_day, RUN_LENGTH, current_coins, remaining_actions)
	day.refresh(current_coins, selected_seed)
	shop.refresh(current_coins, has_growth_speed, has_sell_boost)
	summary.update(calc_score(), best_score)

#Function for when a pot is tapped
func _on_pot_tapped(pot: Pot) -> void:
	#Check if you have enough actions
	if remaining_actions <= 0:
		print("No actions remaining")
		return
	if pot.state == Pot.State.EMPTY and current_coins < selected_seed.seed_cost:
		print("Not enough coins")
		return
	match pot.interact(selected_seed):
		Pot.Result.PLANTED:
			current_coins -= selected_seed.seed_cost
			remaining_actions -= 1
		Pot.Result.HARVESTED:
			remaining_actions -= 1
	_refresh()
	pot._refresh()

#End Day pressed (Day Screen)
func _on_end_day_pressed() -> void:
	
	if current_day < RUN_LENGTH:
		save_game()
		change_screen(Screen.SHOP)
	else:
		if calc_score() > best_score:
			best_score = calc_score()
		clear_run()
		change_screen(Screen.SUMMARY)

#Start Day Pressed (Shop Screen)
func _on_start_day_pressed() -> void:
	current_day += 1
	for pot: Pot in pot_grid.get_children():
		pot.advance_day(growing_rate())
	remaining_actions = actions_per_day
	change_screen(Screen.DAY)

#Switch which seed is being planted
func _on_seed_selected(plant: PlantType) -> void:
	selected_seed = plant
	_refresh()

#Connects from shopscreen to signal upgrades
func _on_upgrade_requested(upgrade: ShopScreen.Upgrade) -> void:
	match upgrade:
		ShopScreen.Upgrade.GROWTH_SPEED_UP:
			if has_growth_speed or current_coins < ShopScreen.GROWTH_SPEED_COST:
				return
			current_coins -= ShopScreen.GROWTH_SPEED_COST
			has_growth_speed = true
			
		ShopScreen.Upgrade.SELL_BOOST:
			if has_sell_boost or current_coins < ShopScreen.SELL_BOOST_COST:
				return
			current_coins -= ShopScreen.SELL_BOOST_COST
			has_sell_boost = true
	_refresh()


func _on_settings_closed() -> void:
	header.visible = true
	change_screen(previous_screen)
	$Settings.visible = true
	Settings.save_settings()


func _on_settings_pressed() -> void:
	if current_screen != Screen.SETTINGS:
		previous_screen = current_screen
	header.visible = false
	$Settings.visible = false
	change_screen(Screen.SETTINGS)


#Increase coin amount when selling/harvesting
func _sell_plant(amount: int) -> void:
	harvest_sound.play()
	if has_sell_boost:
		current_coins += amount * 1.25
	else:
		current_coins += amount
	_refresh()

#Changes growing rate based on upgrades
func growing_rate() -> int:
	return BASE_GROWTH_RATE + (1 if has_growth_speed else 0)

#Start a new run on summaryscreen button pressed, resets states keeps best score
func _start_new_run() -> void:
	current_coins = STARTING_COINS
	current_day = STARTING_DAY
	remaining_actions = BASE_ACTIONS_PER_DAY
	actions_per_day = BASE_ACTIONS_PER_DAY
	has_growth_speed = false
	has_sell_boost = false
	selected_seed = STARTER_SEED
	for pot: Pot in pot_grid.get_children():
		pot.reset()
		pot._refresh()
	change_screen(Screen.DAY)
	save_game()

#Calcs score based on current coins and a refund of half the cost of the currently growing seed
func calc_score() -> int:
	var unharvested := 0
	for pot: Pot in pot_grid.get_children():
		if pot.plant != null:
			@warning_ignore("integer_division")
			unharvested += pot.plant.seed_cost / 2
	return current_coins + unharvested

#clears the run at end of game
func clear_run() -> void:
	var data := {
		"version": SAVE_VERSION,
		"best_score": best_score
	}
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data, "\t"))

#Save game to file (data only)
func save_game() -> void:
	var pot_data := []
	for pot: Pot in pot_grid.get_children():
		pot_data.append(pot.to_dict())
		
	var data := {
		"version": SAVE_VERSION,
		"best_score": best_score,
		"run": {
		"current_day": current_day,
		"current_coins": current_coins,
		"remaining_actions": remaining_actions,
		"actions_per_day": actions_per_day,
		"has_sell_boost": has_sell_boost,
		"has_growth_speed": has_growth_speed,
		"selected_seed_id": selected_seed.id,
		"pots": pot_data,
		},
	}
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not open save file: %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(data, "\t"))

#Load game (data)
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
	has_sell_boost = run.get("has_sell_boost", false)
	selected_seed = plants_by_id.get(run.get("selected_seed_id", ""), STARTER_SEED)
	
	var pots := pot_grid.get_children()
	var saved_pots: Array = run.get("pots", [])
	for i in mini(pots.size(), saved_pots.size()):
		pots[i].from_dict(saved_pots[i], plants_by_id)

	return true
