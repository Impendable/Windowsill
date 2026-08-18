extends Control

@onready var pot_grid: HBoxContainer = $PotGrid

var current_day := 1
var current_coins := 0
var remaining_actions := 5

func _ready() -> void:
	for pot: Pot in pot_grid.get_children():
		pot.tapped.connect(_on_pot_tapped)
		pot.harvested.connect(_sell_plant)
	_refresh_header()


func _on_pot_tapped(pot: Pot) -> void:
	if remaining_actions <= 0:
		print("No actions remaining")
		return
	var result := pot.interact()
	if result != Pot.Result.NONE:
		remaining_actions -= 1
	_refresh_header()


func _on_next_day_pressed() -> void:
	current_day += 1
	#Each pot needs to advance it's state based on growth rate
	for pot: Pot in pot_grid.get_children():
		pot.advance_day()
	#Reset remaining days
	remaining_actions = 5
	_refresh_header()
	
#Refresh the header, called everytime something changes
func _refresh_header() -> void:
	$HeaderUI/CoinLabel.text = "Coins: %s" % current_coins
	$HeaderUI/DayLabel.text = "Day: %s" % current_day
	$HeaderUI/ActionBudget.text = "Actions: %s" % remaining_actions
	
	
#Increase coin amount when selling/harvesting
func _sell_plant(amount: int) -> void:
	current_coins += amount
	_refresh_header()
