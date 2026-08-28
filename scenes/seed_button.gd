class_name SeedButton
extends TextureButton

@onready var label: Label = %SeedLabel

var plant: PlantType

func setup(new_plant: PlantType) -> void:
	plant = new_plant


func set_label(text: String) -> void:
	label.text = text
