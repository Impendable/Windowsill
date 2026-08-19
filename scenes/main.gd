extends Control

const POT_SCENE := preload("res://scenes/pot.tscn")
const STARTER_SEED := preload("res://data/basil.tres")
const BASE_ACTIONS_PER_DAY := 5
const BASE_GROWTH_RATE := 1


@export var available_plants: Array[PlantType]
@export var selected_seed: PlantType

@onready var header: HeaderUI = %HeaderUI
@onready var shop: ShopScreen = %ShopScreen
@onready var pot_grid: HBoxContainer = %PotGrid
@onready var day_screen: Control = %DayScreen

enum Screen { DAY, SHOP }

var current_screen: Screen = Screen.DAY
var current_day := 1
var current_coins := 200
var actions_per_day := BASE_ACTIONS_PER_DAY
var remaining_actions := BASE_ACTIONS_PER_DAY
var has_growth_speed := false
var has_extra_action := false
var growth_rate := BASE_GROWTH_RATE

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
	_refresh()

func _refresh() -> void:
	header.update(current_day, current_coins, remaining_actions)
	shop.refresh(current_coins, has_growth_speed, has_extra_action, selected_seed)

func _on_pot_tapped(pot: Pot) -> void:
	#Check if you have enough actions
	if remaining_actions <= 0:
		print("No actions remaining")
		return
	#Planting costs coins, Harvesting doesn't
	if pot.state == Pot.State.EMPTY and current_coins < selected_seed.seed_cost:
		print("Not enough money, switching to Basil!")
		selected_seed = STARTER_SEED
		return
	match pot.interact(selected_seed):
		Pot.Result.PLANTED:
			current_coins -= selected_seed.seed_cost
			remaining_actions -= 1
		Pot.Result.HARVESTED:
			remaining_actions -= 1
	_refresh()


func _on_end_day_pressed() -> void:
	change_screen(Screen.SHOP)


func _on_start_day_pressed() -> void:
	current_day += 1
	for pot: Pot in pot_grid.get_children():
		pot.advance_day(growth_rate)
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
			growth_rate = 2
			
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
