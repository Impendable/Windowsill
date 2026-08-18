extends Control

@onready var pot_grid: GridContainer = $PotGrid

signal next_day

var current_day := 1
var pot: Pot

func _ready() -> void:
	for pot in pot_grid.get_children():
		pot.tapped.connect(_on_pot_tapped)
	$HeaderUI/DayLabel.text = "Day: %s" % current_day


func _on_pot_tapped(pot: Pot) -> void:
	pot.interact()
	print("%s tapped, state = %s" % [pot.name, Pot.State.keys()[pot.state]])


func _on_next_day_pressed(pot: Pot) -> void:
	current_day += 1
	next_day.emit()
	
