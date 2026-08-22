extends Node

const CONFIG_PATH := "user://settings.cfg"

var music_volume := 1.0 #linear 0.0 to 1.0
var sfx_volume := 1.0

func ready() -> void:
	load_settings()
	
func set_music_volume(value: float) -> void:
	music_volume = value
	_apply_to_bus("Music", music_volume)
	save_settings()
	
func set_sfx_volume(value: float) -> void:
	sfx_volume = value
	_apply_to_bus("SFX", sfx_volume)
	save_settings()
	
func _apply_to_bus(bus_name: String, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		push_error("Audio bus does not exist")
		return
	if linear == 0.0:
		AudioServer.set_bus_mute(index, true)
		return
	else:
		AudioServer.set_bus_mute(index, false)
		AudioServer.set_bus_volume_db(index, linear_to_db(linear))
	
func save_settings() -> void:
	var config := ConfigFile.new()
	#TODO 4: store both volumes under an "audio" section
	config.save(CONFIG_PATH)
	
func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		_apply_all() #no file yet - defaults already set above
		return
	#TODO 5: read both values back, with current values as defaults
	_apply_all()

func _apply_all() -> void:
	_apply_to_bus("Music", music_volume)
	_apply_to_bus("SFX", sfx_volume)
