extends Control

@onready var logo: TextureRect = %Logo
const MAIN = preload("uid://dcf8a4pnler2o")

var t: float = 0.0
var orig_logo_position: Vector2

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT && event.is_pressed():
		get_tree().change_scene_to_packed(MAIN)

func _ready() -> void:
	orig_logo_position = logo.global_position

func _process(delta: float) -> void:
	const dist_max := 20
	var dist_mouse_to_center := (get_viewport_rect().get_center() - get_global_mouse_position()).limit_length(dist_max)
	logo.global_position = Global.elerp(logo.global_position, orig_logo_position + dist_mouse_to_center, 16, delta)
	
	t += delta
	var s = sin(t * 3) * 0.001
	logo.scale += Vector2(s, s)
