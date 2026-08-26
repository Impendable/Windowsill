class_name DayScreen
extends Control

@export var seed_button_scene: PackedScene

signal seed_selected(plant: PlantType)

@onready var seed_list: HBoxContainer = %SeedButtons

var seed_buttons := {} # PlantType -> Button


func build(plants: Array[PlantType]) -> void:
	for plant: PlantType in plants:
		var button := seed_button_scene.instantiate()
		button.get_child(0).text = "%s\n(%d)" % [plant.display_name, plant.seed_cost]
		button.get_child(0).position.x = 15
		button.get_child(0).position.y = 20
		button.toggle_mode = true
		button.pressed.connect(_on_seed_button_pressed.bind(plant))
		seed_list.add_child(button)
		seed_buttons[plant] = button


func _on_seed_button_pressed(plant: PlantType) -> void:
	seed_selected.emit(plant)


func refresh(coins: int, selected: PlantType):
		for plant: PlantType in seed_buttons:
			var button: TextureButton = seed_buttons[plant]
			button.disabled = coins < plant.seed_cost
			button.button_pressed = plant == selected
