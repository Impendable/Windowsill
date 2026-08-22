class_name ShopScreen
extends Control


signal upgrade_requested(upgrade: Upgrade)

enum Upgrade { GROWTH_SPEED_UP, SELL_BOOST }

const GROWTH_SPEED_COST := 20
const SELL_BOOST_COST := 75


@onready var growth_speed_button: Button = %GrowthSpeed
@onready var sell_boost_button: Button = %SellBoost
@onready var shop_sound: AudioStreamPlayer = %ShopButtonSound


func refresh(coins: int, owns_speed: bool, owns_action: bool) -> void:
	growth_speed_button.disabled = owns_speed or coins < GROWTH_SPEED_COST
	sell_boost_button.disabled = owns_action or coins < SELL_BOOST_COST



func _on_plus_action_pressed() -> void:
	shop_sound.play()
	upgrade_requested.emit(Upgrade.SELL_BOOST)
	


func _on_growth_speed_pressed() -> void:
	shop_sound.play()
	upgrade_requested.emit(Upgrade.GROWTH_SPEED_UP)
