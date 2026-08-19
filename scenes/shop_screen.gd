class_name ShopScreen
extends Control

signal seed_selected(plant: PlantType)
signal upgrade_requested(upgrade: Upgrade)

enum Upgrade { EXTRA_POT, EXTRA_ACTION }

const EXTRA_POT_COST := 75
const EXTRA_ACTION_COST := 150

@onready var seed_list: HBoxContainer = %SeedList
@onready var extra_pot_button: Button = %ExtraPot
@onready var plus_action_button: Button = %PlusAction

var seed_buttons := {} # PlantType -> Button

func build(plants: Array[PlantType]) -> void:
	for plant: PlantType in plants:
		var button := Button.new()
		button.text = "%s (%d)" % [plant.display_name, plant.seed_cost]
		button.toggle_mode = true
		button.pressed.connect(_on_seed_button_pressed.bind(plant))
		seed_list.add_child(button)
		seed_buttons[plant] = button

func refresh(coins: int, owns_pot: bool, owns_action: bool, selected: PlantType) -> void:
	for plant: PlantType in seed_buttons:
		var button: Button = seed_buttons[plant]
		button.disabled = coins < plant.seed_cost
		button.button_pressed = plant == selected
	extra_pot_button.disabled = owns_pot or coins < EXTRA_POT_COST
	plus_action_button.disabled = owns_action or coins < EXTRA_ACTION_COST
	
func _on_seed_button_pressed(plant: PlantType) -> void:
	seed_selected.emit(plant)


func _on_extra_pot_pressed() -> void:
	upgrade_requested.emit(Upgrade.EXTRA_POT)


func _on_plus_action_pressed() -> void:
	upgrade_requested.emit(Upgrade.EXTRA_ACTION)
