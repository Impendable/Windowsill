class_name ShopScreen
extends Control

@export var seed_button_scene: PackedScene

signal upgrade_requested(upgrade: Upgrade)
signal seed_purchased(plant: PlantType)

enum Upgrade { GROWTH_SPEED_UP, SELL_BOOST }

const GROWTH_SPEED_COST := 20
const SELL_BOOST_COST := 75


@onready var growth_speed_button: TextureButton = %GrowthSpeed
@onready var sell_boost_button: TextureButton = %SellBoost
@onready var seed_shop_list: HBoxContainer = %SeedList
@onready var shop_sound: AudioStreamPlayer = %ShopButtonSound

var seed_buttons := {} # PlantType -> SeedButton


func build(plants: Array[PlantType]) -> void:
	for plant: PlantType in plants:
		if plant.unlimited:
			continue #Doesn't sell free/infinite seeds
		var button: SeedButton = seed_button_scene.instantiate()
		seed_shop_list.add_child(button)
		button.setup(plant)
		button.pressed.connect(_on_seed_buy_pressed.bind(plant))
		seed_buttons[plant] = button



func refresh(run: RunState) -> void:
	growth_speed_button.disabled = run.has_growth_speed or run.coins < GROWTH_SPEED_COST
	sell_boost_button.disabled = run.has_sell_boost or run.coins < SELL_BOOST_COST
	
	for plant: PlantType in seed_buttons:
		var button: SeedButton = seed_buttons[plant]
		button.set_label("%s\n%dc\n(x%d)" % [plant.display_name, plant.seed_cost, run.seed_count(plant.id)])
		button.disabled = run.coins < plant.seed_cost


func _on_seed_buy_pressed(plant: PlantType) -> void:
	shop_sound.play()
	seed_purchased.emit(plant)


func _on_plus_action_pressed() -> void:
	shop_sound.play()
	upgrade_requested.emit(Upgrade.SELL_BOOST)


func _on_growth_speed_pressed() -> void:
	shop_sound.play()
	upgrade_requested.emit(Upgrade.GROWTH_SPEED_UP)
