class_name StatBar extends ProgressBar

@onready var icon: TextureRect = %Icon
@onready var label: Label = %Label
@onready var label_anim: UiAnimationComponent = %LabelAnim

@export var stat_name: String = ""
@export var stat_icon: Texture2D
@export var icon_size: Vector2 = Vector2(45, 45)
@export var enable_lable: bool = true
@export var gradient_red_green: GradientTexture1D

func _ready() -> void:
	if stat_icon:
		icon.texture = stat_icon
		icon.custom_minimum_size = icon_size
		icon.size = icon_size
	if enable_lable:
		label.self_modulate = Color.TRANSPARENT
		label.scale = Vector2.ZERO
		label_anim.init()
	else:
		label.hide()
	hide()

func set_values(_max_value: float, _value: float) -> void:
	max_value = _max_value
	value = clamp(_value, 0 , _max_value)
	var percent := value / max_value
	label.text = "%s: %d%%" % [stat_name.to_pascal_case(), int(100 * percent)]
	get_theme_stylebox("fill").bg_color = gradient_red_green.gradient.sample(percent)
	show()
