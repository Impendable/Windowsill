extends Control

@onready var pot_grid: HBoxContainer = $PotGrid

var current_day := 1
var current_coins := 0
var remaining_actions := 5

func _ready() -> void:
	for pot: Pot in pot_grid.get_children():
		pot.tapped.connect(_on_pot_tapped)
	_refresh_header()


func _on_pot_tapped(pot: Pot) -> void:
	if remaining_actions > 0:
		var result := pot.interact()
		if result == 1:
			remaining_actions -= 1
			print("PLANT ACTION")
		elif result  == 2:
			remaining_actions -= 1
			print("HARVEST ACTION")
			pot.harvested.connect(_sell_plant)
		else:
			return
	else:
		print("No actions remaining")
		return
		
	print("%s tapped, state = %s" % [pot.name, Pot.State.keys()[pot.state]])
	_refresh_header()


func _on_next_day_pressed() -> void:
	current_day += 1
	for pot: Pot in pot_grid.get_children():
		pot.advance_day()
	remaining_actions = 5
	_refresh_header()
	
func _refresh_header() -> void:
	$HeaderUI/CoinLabel.text = "Coins: %s" % current_coins
	$HeaderUI/DayLabel.text = "Day: %s" % current_day
	$HeaderUI/ActionBudget.text = "Actions: %s" % remaining_actions
	
	
func _sell_plant(amount: int) -> void:
	current_coins += amount
	_refresh_header()
