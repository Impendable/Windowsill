extends Control

@onready var pot_grid: HBoxContainer = %PotGrid
@onready var day_screen: Control = %DayScreen
@onready var shop_screen: Control = %ShopScreen
@onready var seed_list: HBoxContainer = %SeedList
@onready var action_upgrade: Button = %PlusAction
@onready var exta_pot_upgrade: Button = %ExtraPot

@export var available_plants: Array[PlantType]
@export var selected_seed: PlantType
enum Screen { DAY, SHOP }

var actions_per_day := 5
var current_day := 1
var current_coins := 0
var epu_cost := 75
var au_cost := 150
var remaining_actions := actions_per_day

var current_screen: Screen = Screen.DAY

func _ready() -> void:
	#Check all pots in scene for any signals
	for pot: Pot in pot_grid.get_children():
		pot.tapped.connect(_on_pot_tapped)
		pot.harvested.connect(_sell_plant)
	
	_refresh_shop()


func _on_pot_tapped(pot: Pot) -> void:
	#Check if you have enough actions
	if remaining_actions <= 0:
		print("No actions remaining")
		return
	#call pot.interact with seed, check what state pot is in and store as result
	var result := pot.interact(selected_seed)
	#Cost an action for anything that returns an action (Can add more costs)
	if result != Pot.Result.NONE:
		remaining_actions -= 1
	_refresh_header()
	_refresh_shop()


func _on_next_day_pressed() -> void:
	change_screen(Screen.SHOP)

		
#Refresh the header, called everytime something changes
func _refresh_header() -> void:
	%CoinLabel.text = "Coins: %s" % current_coins
	%DayLabel.text = "Day: %s" % current_day
	%ActionBudget.text = "Actions: %s" % remaining_actions
	
	
	
func _refresh_shop() -> void:
	for plant: PlantType in available_plants:
		var button := Button.new()
		button.text = "%s (%d)" % [plant.display_name, plant.seed_cost]
		button.disabled = current_coins < plant.seed_cost
		button.pressed.connect(_on_seed_selected.bind(plant))
		seed_list.add_child(button)
		
	action_upgrade.disabled = current_coins < au_cost
	exta_pot_upgrade.disabled = current_coins < epu_cost
	
#Increase coin amount when selling/harvesting
func _sell_plant(amount: int) -> void:
	current_coins += amount
	_refresh_header()

#Change between shop and day screens
func change_screen(screen: Screen) -> void:
	current_screen = screen
	day_screen.visible = current_screen == Screen.DAY
	shop_screen.visible = current_screen == Screen.SHOP
	_refresh_shop()
	_refresh_header()


func _on_end_day_pressed() -> void:
	change_screen(Screen.DAY)
	current_day += 1
	#Each pot needs to advance it's state based on growth rate
	for pot: Pot in pot_grid.get_children():
		pot.advance_day()
	#Reset remaining days
	remaining_actions = actions_per_day
	_refresh_header()


func _on_seed_selected(new_seed: PlantType) -> void:
	selected_seed = new_seed
	
	


func _on_extra_pot_pressed() -> void:
	var new_pot: Pot = Pot.new()
	pot_grid.add_child(new_pot)
	exta_pot_upgrade.hide()
	exta_pot_upgrade.disabled = true
	_refresh_header()
	


func _on_plus_action_pressed() -> void:
	actions_per_day += 1
	action_upgrade.hide()
	action_upgrade.disabled = true
	_refresh_header()
