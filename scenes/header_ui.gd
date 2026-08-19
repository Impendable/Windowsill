class_name HeaderUI
extends GridContainer

@onready var day_label: Label = %DayLabel
@onready var coin_label: Label = %CoinLabel
@onready var action_label: Label = %ActionBudget


func update(day: int, coins: int, actions: int) -> void:
	day_label.text = "Day: %d" % day
	coin_label.text = "Coins: %d" % coins
	action_label.text = "Actions: %d" % actions
