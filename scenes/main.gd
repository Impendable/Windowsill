extends Control

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 2
const STARTER_SEED := preload("res://data/basil.tres")
const RUN_LENGTH := 14
const LEGACY_PLANT_IDS := {
	1: "basil",
	2: "parsley",
	3: "oregano",
}


@export var available_plants: Array[PlantType]

@onready var header: HeaderUI = %HeaderUI
@onready var notification_alert: Notification = %NotificationLabel
@onready var day: DayScreen = %DayScreen
@onready var shop: ShopScreen = %ShopScreen
@onready var settings: SettingScreen = %SettingScreen
@onready var summary: SummaryScreen = %SummaryScreen
@onready var pot_grid: HBoxContainer = %PotGrid
@onready var settings_button: TextureButton = %SettingsButton
@onready var harvest_sound: AudioStreamPlayer = %HarvestSound
@onready var action_button_sound: AudioStreamPlayer = %ActionButtonSound
@onready var seed_selected_sound: AudioStreamPlayer = %SeedSelectedSound
@onready var seed_planted_sound: AudioStreamPlayer = %SeedPlantedSound
@onready var bg_music: AudioStreamPlayer = %BGMusic

enum Screen { DAY, SHOP, SUMMARY, SETTINGS }

var run := RunState.new()
var current_screen: Screen = Screen.DAY
var previous_screen: Screen = Screen.DAY
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
	day.visible = current_screen == Screen.DAY
	shop.visible = current_screen == Screen.SHOP
	summary.visible = current_screen == Screen.SUMMARY
	settings.visible = current_screen == Screen.SETTINGS
	header.visible = screen != Screen.SETTINGS
	settings_button.visible = screen != Screen.SETTINGS
	_refresh()

#Refresh all screens and seed chosen if necessary
func _refresh() -> void:
	header.update(run.day, RUN_LENGTH, run.coins, run.remaining_actions)
	day.refresh(run.coins, _selected_seed())
	shop.refresh(run.coins, run.has_growth_speed, run.has_sell_boost)
	summary.update(calc_score(), best_score)

#Function for when a pot is tapped
func _on_pot_tapped(pot: Pot) -> void:
	#Check if you have enough actions
	if run.remaining_actions <= 0:
		notification_alert.show_message("No actions remaining")
		return
		
	var seed_type := _selected_seed()
	
	if pot.state == Pot.State.EMPTY and run.coins < seed_type.seed_cost:
		notification_alert.show_message("Not enough coins")
		return
	match pot.interact(seed_type):
		Pot.Result.PLANTED:
			seed_planted_sound.play()
			run.coins -= seed_type.seed_cost
			run.remaining_actions -= 1
			save_game()
		Pot.Result.HARVESTED:
			run.remaining_actions -= 1
			save_game()
		Pot.Result.NONE:
			notification_alert.show_message("Growing: %s/%s days" % [pot.growth_counter,pot.plant.growth_days])
	_refresh()

#End Day pressed (Day Screen)
func _on_end_day_pressed() -> void:
	action_button_sound.play()
	if run.day < RUN_LENGTH:
		save_game()
		change_screen(Screen.SHOP)
	else:
		if calc_score() > best_score:
			best_score = calc_score()
		clear_run()
		change_screen(Screen.SUMMARY)

#Start Day Pressed (Shop Screen)
func _on_start_day_pressed() -> void:
	action_button_sound.play()
	run.day += 1
	for pot: Pot in pot_grid.get_children():
		pot.advance_day(run.growth_rate())
	run.remaining_actions = run.actions_per_day
	change_screen(Screen.DAY)
	save_game()


func _selected_seed() -> PlantType:
	return plants_by_id.get(run.selected_seed_id, STARTER_SEED)

#Switch which seed is being planted
func _on_seed_selected(plant: PlantType) -> void:
	seed_selected_sound.play()
	notification_alert.show_message("%s: Grows in %d days\nSells for %d coins." %[plant.display_name, plant.growth_days, plant.sell_price])
	run.selected_seed_id = plant.id
	_refresh()

#Connects from shopscreen to signal upgrades
func _on_upgrade_requested(upgrade: ShopScreen.Upgrade) -> void:
	match upgrade:
		ShopScreen.Upgrade.GROWTH_SPEED_UP:
			if run.has_growth_speed or run.coins < ShopScreen.GROWTH_SPEED_COST:
				return
			run.coins -= ShopScreen.GROWTH_SPEED_COST
			run.has_growth_speed = true
			
		ShopScreen.Upgrade.SELL_BOOST:
			if run.has_sell_boost or run.coins < ShopScreen.SELL_BOOST_COST:
				return
			run.coins -= ShopScreen.SELL_BOOST_COST
			run.has_sell_boost = true
	_refresh()


func _on_settings_closed() -> void:
	change_screen(previous_screen)
	Settings.save_settings()


func _on_settings_pressed() -> void:
	if current_screen != Screen.SETTINGS:
		previous_screen = current_screen
	change_screen(Screen.SETTINGS)


#Increase coin amount when selling/harvesting
func _sell_plant(amount: int) -> void:
	harvest_sound.play()
	run.coins += roundi(amount * run.sell_multiplier())
	_refresh()

#Start a new run on summaryscreen button pressed, resets states keeps best score
func _start_new_run() -> void:
	run = RunState.new()
	for pot: Pot in pot_grid.get_children():
		pot.reset()
	change_screen(Screen.DAY)
	save_game()

#Calcs score based on current coins and a refund of half the cost of the currently growing seed
func calc_score() -> int:
	var unharvested := 0
	for pot: Pot in pot_grid.get_children():
		if pot.plant != null:
			@warning_ignore("integer_division")
			unharvested += pot.plant.seed_cost / 2
	return run.coins + unharvested


func _write_save(data: Dictionary) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Could not open save file: %s" % FileAccess.get_open_error())
		return
	file.store_string(JSON.stringify(data, "\t"))

#clears the run at end of game
func clear_run() -> void:
	_write_save({
		"version": SAVE_VERSION,
		"best_score": best_score
	})

#Save game to file (data only)
func save_game() -> void:
	var pot_data := []
	for pot: Pot in pot_grid.get_children():
		pot_data.append(pot.to_dict())
		
	var run_dict := run.to_dict()
	run_dict["pots"] = pot_data
	
	_write_save({
		"version": SAVE_VERSION,
		"best_score": best_score,
		"run": run_dict,
	})

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
	
	var version := int(data.get("version", 0))
	if version > SAVE_VERSION:
		push_error("Save file is from a newer version of the game!")
		return false
	
	if version < SAVE_VERSION:
		data = _migrate(data, version)
		if data == null:
			return false
	
	best_score = int(data.get("best_score", 0))
	
	if not data.has("run"):
		return false
		
	var run_data: Dictionary = data["run"]
	run = RunState.from_dict(run_data)
	
	if run.selected_seed_id not in plants_by_id:
		run.selected_seed_id = STARTER_SEED.id
	
	var pots := pot_grid.get_children()
	var saved_pots: Array = run_data.get("pots", [])
	for i in mini(pots.size(), saved_pots.size()):
		pots[i].from_dict(saved_pots[i], plants_by_id)

	return true


func _migrate(data: Dictionary, from_version: int) -> Dictionary:
	var version := from_version
	
	if version == 1:
		data = _migrate_1_to_2(data)
		version = 2

	data["version"] = version
	return data
	
	
func _migrate_1_to_2(data: Dictionary) -> Dictionary:
	if not data.has("run"):
		return data
	var run_data: Dictionary = data["run"]
	
	if run_data.has("current_coins"):
		run_data["coins"] = run_data["current_coins"]
		run_data.erase("current_coins")
	if run_data.has("current_day"):
		run_data["day"] = run_data["current_day"]
		run_data.erase("current_day")
	for pot_data in run_data.get("pots", []):
		var pid = pot_data.get("plant_id", "")
		if pid is float or pid is int:
			pot_data["plant_id"] = LEGACY_PLANT_IDS.get(int(pid), "")
		var sid = run_data.get("selected_seed_id", "")
		if sid is float or sid is int:
			run_data["selected_seed_id"] = LEGACY_PLANT_IDS.get(int(sid), "")
	
	return data
