class_name HeaderUI
extends GridContainer

@onready var day_label: Label = %DayLabel
@onready var coin_label: Label = %CoinLabel
@onready var action_label: Label = %ActionBudget

func update(day: int, final_day: int, coins: int, actions: int) -> void:
	day_label.text = "Day: %d/%d" % [day, final_day]
	coin_label.text = "Coins: %d" % coins
	action_label.text = "Actions: %d" % actions
