class_name SettingScreen
extends Control

signal closed

@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider

func _ready() -> void:
	#show the current saved values on the sliders.
	master_slider.set_value_no_signal(Settings.master_volume)
	music_slider.set_value_no_signal(Settings.music_volume)
	sfx_slider.set_value_no_signal(Settings.sfx_volume)
	#connect each slider's value_changed signal to a handler
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)


func _on_master_changed(value: float) -> void:
	Settings.set_master_volume(value)


func _on_music_changed(value: float) -> void:
	Settings.set_music_volume(value)


func _on_sfx_changed(value: float) -> void:
	Settings.set_sfx_volume(value)


func _on_close_settings_pressed() -> void:
	Settings.save_settings()
	closed.emit()
