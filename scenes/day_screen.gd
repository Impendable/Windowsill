class_name DayScreen
extends Control

@export var seed_button_scene: PackedScene

signal seed_selected(plant: PlantType)

@onready var seed_list: HBoxContainer = %SeedButtons

var seed_buttons := {} # PlantType -> SeedButton


func build(plants: Array[PlantType]) -> void:
	for plant: PlantType in plants:
		var button: SeedButton = seed_button_scene.instantiate()
		button.toggle_mode = true
		seed_list.add_child(button)
		button.setup(plant)
		button.pressed.connect(_on_seed_button_pressed.bind(plant))
		seed_buttons[plant] = button


func refresh(run: RunState):
		for plant: PlantType in seed_buttons:
			var button: SeedButton = seed_buttons[plant]
			var count := run.seed_count(plant.id)
			if plant.unlimited:
				button.set_label("%s\n∞" % plant.display_name)
				button.disabled = false
			else:
				button.set_label("%s\nx%d" % [plant.display_name, count])
				button.disabled = count <= 0
			button.button_pressed = plant.id == run.selected_seed_id


func _on_seed_button_pressed(plant: PlantType) -> void:
	seed_selected.emit(plant)
