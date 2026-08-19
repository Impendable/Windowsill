extends Control

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
@onready var pot_grid: HBoxContainer = %PotGrid
@onready var day_screen: Control = %DayScreen
@onready var summary_screen: Control = %SummaryScreen
@onready var score: Label = $SummaryScreen/VBoxContainer/Score

enum Screen { DAY, SHOP, SUMMARY }

var current_screen: Screen = Screen.DAY
var current_day := STARTING_DAY
var current_coins := STARTING_COINS
var actions_per_day := BASE_ACTIONS_PER_DAY
var remaining_actions := BASE_ACTIONS_PER_DAY
var has_growth_speed := false
var has_extra_action := false

func _ready() -> void:
	#Check all pots in scene for any signals
	for pot: Pot in pot_grid.get_children():
		_connect_pot(pot)
	shop.seed_selected.connect(_on_seed_selected)
	shop.upgrade_requested.connect(_on_upgrade_requested)
	shop.build(available_plants)
	change_screen(Screen.DAY)


func _connect_pot(pot: Pot) -> void:
	pot.tapped.connect(_on_pot_tapped)
	pot.harvested.connect(_sell_plant)

#Change between shop and day screens
func change_screen(screen: Screen) -> void:
	current_screen = screen
	day_screen.visible = current_screen == Screen.DAY
	shop.visible = current_screen == Screen.SHOP
	summary_screen.visible = current_screen == Screen.SUMMARY
	_refresh()


func _refresh() -> void:
	if selected_seed.seed_cost > current_coins:
		selected_seed = STARTER_SEED
	header.update(current_day, RUN_LENGTH, current_coins, remaining_actions)
	shop.refresh(current_coins, has_growth_speed, has_extra_action, selected_seed)


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
	if current_day != RUN_LENGTH:
		change_screen(Screen.SHOP)
	else:
		score.text = "Score: %d" % calc_score()
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
	return BASE_GROWTH_RATE + 1 if has_growth_speed else 1


func _start_new_run() -> void:
	current_coins = STARTING_COINS
	current_day = STARTING_DAY
	remaining_actions = BASE_ACTIONS_PER_DAY
	has_growth_speed = false
	has_extra_action = false
	selected_seed = STARTER_SEED
	
func calc_score() -> int:
	var current_growth_cost := 0
	for pot: Pot in pot_grid.get_children():
		for plant: PlantType in pot:
			@warning_ignore("integer_division")
			current_growth_cost = current_growth_cost + plant.seed_cost / 2
	return current_coins + current_growth_cost
