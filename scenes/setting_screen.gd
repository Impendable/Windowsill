class_name SettingScreen
extends Control

signal closed

@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = $SFXSlider

func _ready() -> void:
	#TODO 6: show the current saved values on the sliders.
	#	Careful: assigning slider.value emits value_changed. Range has
	#	set_value_no_signal() for exactly this situation. Predict what
	#	happens if you use plain assignment, then decide which you want.
	
	# TODO 7: connect each slider's value_changed signal to a handler below
	pass
	
func _on_music_changed(value: float) -> void:
	# TODO 8: tell Settings. Nothing else.
	pass
	
func _on_sfx_changed(value: float) -> void:
	# TODO 9
	pass


func _on_back_pressed() -> void:
	pass
