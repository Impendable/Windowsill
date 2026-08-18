extends Control

@onready var pot_grid: GridContainer = $PotGrid

var pot: Pot

func _ready() -> void:
	for pot in pot_grid.get_children():
		pot.tapped.connect(_on_pot_tapped)

func _on_pot_tapped(pot: Pot) -> void:
	print("%s tapped, state = %s" % [pot.name, Pot.State.keys()[pot.state]])
