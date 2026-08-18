extends Control

@onready var pot_grid: GridContainer = $PotGrid

var current_day := 1
var current_coins := 0

func _ready() -> void:
	for pot: Pot in pot_grid.get_children():
		pot.tapped.connect(_on_pot_tapped)



func _on_pot_tapped(pot: Pot) -> void:
	current_coins += pot.interact()
	print("%s tapped, state = %s" % [pot.name, Pot.State.keys()[pot.state]])
	_refresh_header()


func _on_next_day_pressed() -> void:
	current_day += 1
	for pot: Pot in pot_grid.get_children():
		pot.advance_day()
	_refresh_header()
	
func _refresh_header() -> void:
	$HeaderUI/CoinLabel.text = "Coins: %s" % current_coins
	$HeaderUI/DayLabel.text = "Day: %s" % current_day
	
