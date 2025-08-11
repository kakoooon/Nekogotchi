class_name SpeechBubble extends PanelContainer

@onready var label: Label = %Label
@onready var scroll_container: ScrollContainer = %ScrollContainer

@export var max_width: int = 400 # Width cap before text wrapping kicks in.
@export var max_height: int = 60 # Height cap before scrolling kicks in.

var initial_size: Vector2
var initial_position: Vector2

func _ready() -> void:
	initial_size = size
	initial_position = position

func show_text(text: String, char_delay: float = 0.05) -> void:
	if text.is_empty(): 
		return
	
	scroll_container.custom_minimum_size = Vector2.ZERO
	scroll_container.size = Vector2.ZERO
	
	label.text = ""
	label.custom_minimum_size = Vector2.ZERO
	label.size = Vector2.ZERO
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	
	size = initial_size
	position = initial_position
	
	for c in text:
		label.text += c
		adjust_size()
		await get_tree().create_timer(char_delay).timeout

func adjust_size() -> void:
	#var fnt := label.get_theme_font("font")
	#var current_text_size: Vector2 = fnt.get_string_size(label.text)
	if label.size.x >= max_width:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.custom_minimum_size.x = min(label.size.x, max_width)
	scroll_container.custom_minimum_size.y = min(label.size.y, max_height)
