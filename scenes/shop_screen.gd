class_name ShopScreen
extends Control


signal upgrade_requested(upgrade: Upgrade)

enum Upgrade { GROWTH_SPEED_UP, EXTRA_ACTION }

const GROWTH_SPEED_COST := 75
const EXTRA_ACTION_COST := 150


@onready var growth_speed_button: Button = %GrowthSpeed
@onready var plus_action_button: Button = %PlusAction




func refresh(coins: int, owns_speed: bool, owns_action: bool) -> void:
	growth_speed_button.disabled = owns_speed or coins < GROWTH_SPEED_COST
	plus_action_button.disabled = owns_action or coins < EXTRA_ACTION_COST



func _on_plus_action_pressed() -> void:
	upgrade_requested.emit(Upgrade.EXTRA_ACTION)


func _on_growth_speed_pressed() -> void:
	upgrade_requested.emit(Upgrade.GROWTH_SPEED_UP)
