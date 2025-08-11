class_name CatgirlResource extends Resource

#
# Things that are @exported will be marked as PROPERTY_USAGE_DEFAULT, and we'll use that for serialization.
#

@export var catgirl_name: String = ""
@export var texture_id: int = -1 ## A number to load("res://catgirls/art/catgirl_{texture_id}.png"). The loading happens outside.

## Player2AINPC._selected_character, run player2.exe and read: http://localhost:4315/docs/#/Characters/selected_characters
var player2_character: Dictionary

const MAX_HUNGER := 10.0 # Feed
const MAX_HYGIENE := 10.0 # Wash
const MAX_AFFECTION := 10.0 # Headpat
const MAX_CHAT := 10.0 # Talk

const MAX_FRIENDSHIP := 5.0

# Stats decrease as time passes.
@export_range(0, MAX_HUNGER) var progress_hunger: float = MAX_HUNGER * 0.5:
	set(new_value):
		progress_hunger = clamp(new_value, 0, MAX_HUNGER)
		emit_changed()
@export_range(0, MAX_HYGIENE) var progress_hygiene: float = MAX_HYGIENE * 0.8:
	set(new_value):
		progress_hygiene = clamp(new_value, 0, MAX_HYGIENE)
		emit_changed()
@export_range(0, MAX_AFFECTION) var progress_affection: float = 0.0:
	set(new_value):
		progress_affection = clamp(new_value, 0, MAX_AFFECTION)
		emit_changed()
@export_range(0, MAX_CHAT) var progress_chat: float = 0.0:
	set(new_value):
		progress_chat = clamp(new_value, 0, MAX_CHAT)
		emit_changed()

@export_range(0, MAX_FRIENDSHIP) var progress_friendship: float = 0:
	set(new_value):
		progress_friendship = max(new_value, 0)
		while progress_friendship >= MAX_FRIENDSHIP:
			progress_friendship -= MAX_FRIENDSHIP
			points_friendship += 1
		emit_changed()
@export var points_friendship: int = 0: # This doesn't go down. Used as in-game currency.
	set(new_value):
		points_friendship = max(new_value, 0)
		emit_changed()

# Hours needed to lose 1 stat point.
const HOURS_PER_POINT_HUNGER: float = 4
const HOURS_PER_POINT_HYGIENE: float = 3
const HOURS_PER_POINT_AFFECTION: float = 2
const HOURS_PER_POINT_CHAT: float = 6

# Cap offline decay (hours). Set to 0 to disable cap (no cap).
const OFFLINE_CAP_HOURS: int = 48

# Internal timestamp saved with the character (unix seconds)
var last_online_unix: int = 0

func init(_player2_character: Dictionary) -> void:
	if _player2_character.is_empty():
		push_warning("Can't init empty _player2_character!")
		return
	
	player2_character = _player2_character
	
	if !SaveFileHandler.before_save.is_connected(serialize):
		SaveFileHandler.before_save.connect(serialize)
	if !SaveFileHandler.after_load.is_connected(deserialize):
		SaveFileHandler.after_load.connect(deserialize)
	
	deserialize(SaveFileHandler.config)

func serialize(config: ConfigFile, _first_time: bool) -> void:
	if player2_character.is_empty():
		push_warning("Can't serialize empty player2_character!")
		return
	for prop in get_property_list():
		if (prop.usage & PROPERTY_USAGE_DEFAULT) && (prop.hint != PROPERTY_HINT_RESOURCE_TYPE):
			var key = prop.name
			var val = get(key)
			config.set_value(player2_character["id"], key, val)
			#if val is Resource: # Recursive serialize.
	config.set_value(player2_character["id"], "last_online_unix", int(Time.get_unix_time_from_system()))

func deserialize(_config: ConfigFile) -> void:
	var data: Dictionary = SaveFileHandler.load_data(player2_character["id"])
	if data.is_empty():
		# First time.
		return
	for key in data.keys():
		set(key, data[key])
	
	# Compute elapsed time.
	#
	var saved_time_seconds: int = 0
	if data.has("last_online_unix"):
		saved_time_seconds = data["last_online_unix"]
	elif last_online_unix != 0:
		saved_time_seconds = last_online_unix
	if saved_time_seconds <= 0:
		# no timestamp available — set fresh one now and skip decay.
		last_online_unix = int(Time.get_unix_time_from_system())
		return
	var now: int = int(Time.get_unix_time_from_system())
	var elapsed_seconds := now - saved_time_seconds
	if elapsed_seconds <= 0:
		# No time passed.
		last_online_unix = now
		return
	
	# Apply optional cap.
	#
	if OFFLINE_CAP_HOURS > 0:
		var cap_seconds := OFFLINE_CAP_HOURS * 60 * 60
		if elapsed_seconds > cap_seconds:
			elapsed_seconds = cap_seconds
	
	# Apply points decay.
	#
	var hours := float(elapsed_seconds) / 3600.0
	if HOURS_PER_POINT_HUNGER > 0.0:
		var lost := hours / HOURS_PER_POINT_HUNGER
		progress_hunger = progress_hunger - lost
	if HOURS_PER_POINT_HYGIENE > 0.0:
		var lost := hours / HOURS_PER_POINT_HYGIENE
		progress_hygiene = progress_hygiene - lost
	if HOURS_PER_POINT_AFFECTION > 0.0:
		var lost := hours / HOURS_PER_POINT_AFFECTION
		progress_affection = progress_affection - lost
	if HOURS_PER_POINT_CHAT > 0.0:
		var lost := hours / HOURS_PER_POINT_CHAT
		progress_chat = progress_chat - lost
	
	last_online_unix = now
