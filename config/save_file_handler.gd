extends Node

signal before_save(config: ConfigFile, first_time: bool)
signal after_load(config: ConfigFile)

var config = ConfigFile.new()
const SAVE_FILE_PATH = "user://save.ini"


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_all()
		get_tree().quit()

func init() -> void:
	if !FileAccess.file_exists(SAVE_FILE_PATH):
		save_all(true)
	load_all()


#
#
#
func save_all(first_time: bool = false) -> void:
	if first_time:
		# Default settings.
		config.set_value("video", "fullscreen", false)
		config.set_value("audio", "master", 1.0)
		config.set_value("audio", "music", 1.0)
		config.set_value("audio", "sfx", 1.0)
	
	before_save.emit(config, first_time)
	
	var err := config.save(SAVE_FILE_PATH)
	if err != OK:
		push_error("SaveFileHandler: save failed! %s" % error_string(err))

func load_all() -> void:
	var err := config.load(SAVE_FILE_PATH)
	if err != OK:
		push_error("SaveFileHandler: load failed! %s" % error_string(err))
	
	# Apply settings:
	var video_settings = load_data("video")
	apply_fullscreen(video_settings.fullscreen)
	var audio_settings = load_data("audio")
	for bus in audio_settings.keys():
		apply_audio_volume(AudioServer.get_bus_index(bus.to_pascal_case()), audio_settings[bus])
	
	after_load.emit(config)

#
# Serializing the data.
#
func save_data(section: String, key: String, data: Variant) -> void:
	config.set_value(section, key, data)
	config.save(SAVE_FILE_PATH)
	
func load_data(section: String) -> Dictionary:
	var result := {}
	if config.has_section(section):
		for key in config.get_section_keys(section):
			result[key] = config.get_value(section, key)
	return result

#
# Setters and getters.
#
func set_fullscreen(toggled_on: bool) -> void:
	save_data("video", "fullscreen", toggled_on)
	apply_fullscreen(toggled_on)

func set_volume(bus: String, normalized_volume: float = 1.0) -> void:
	save_data("audio", bus.to_lower(), normalized_volume)
	apply_audio_volume(AudioServer.get_bus_index(bus.to_pascal_case()), normalized_volume)

func get_volume(bus: String) -> float:
	var audio_settings: Dictionary = load_data("audio")
	var result: float = 0.0
	if audio_settings.has(bus):
		result = audio_settings[bus]
	return result

#
# Applying settings.
#
func apply_fullscreen(value: bool):
	if (value == true):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func apply_audio_volume(bus_index: int, volume: float):
	if bus_index != -1:
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(volume))
