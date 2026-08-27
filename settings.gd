extends Node

const CONFIG_PATH := "user://settings.cfg"
 
var master_volume := 1.0
var music_volume := 1.0 #linear 0.0 to 1.0
var sfx_volume := 1.0

func _ready() -> void:
	load_settings()
	
func set_music_volume(value: float) -> void:
	music_volume = value
	_apply_to_bus("Music", music_volume)


func set_sfx_volume(value: float) -> void:
	sfx_volume = value
	_apply_to_bus("SFX", sfx_volume)


func set_master_volume(value: float) -> void:
	master_volume = value
	_apply_to_bus("Master", master_volume)

func _apply_to_bus(bus_name: String, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index < 0:
		push_error("Audio bus '%s' does not exist" % bus_name)
		return
	if linear <= 0.0:
		AudioServer.set_bus_mute(index, true)
		return
	else:
		AudioServer.set_bus_mute(index, false)
		AudioServer.set_bus_volume_db(index, linear_to_db(linear))
	
func save_settings() -> void:
	var config := ConfigFile.new()
	
	#store both volumes under an "audio" section
	config.set_value("audio", "master", master_volume)
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.save(CONFIG_PATH)
	
func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		_apply_all() #no file yet - defaults already set above
		return
	# read values back, with current values as defaults
	master_volume = config.get_value("audio", "master", master_volume)
	music_volume = config.get_value("audio", "music", music_volume)
	sfx_volume = config.get_value("audio", "sfx", sfx_volume)
	_apply_all()

func _apply_all() -> void:
	_apply_to_bus("Master", master_volume)
	_apply_to_bus("Music", music_volume)
	_apply_to_bus("SFX", sfx_volume)
