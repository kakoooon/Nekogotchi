class_name UiAnimationComponent extends Node

#
# Reference: StayAtHomeDev:
# https://youtu.be/BdW62b3GUoY?si=oFvpON9VP4CdyaXT
#

signal animation_enter_finished

@export var init_on_tree_entry: bool = true
@export var centered: bool = true ## If false, animations will apply from top-left corner.
@export var use_hover_animation: bool = true
@export var use_enter_animation: bool = false
@export var parallel_animations: bool = true ## If false, animations will player in serial order. 
@export var properties: Array = ["scale", "position", "rotation", "size", "self_modulate"]

@export_group("Hover Settings")
@export var hover_node: Control ## In case you want target node to animate according to a different hover node.
@export var hover_time: float = 0.1 ## Time (in seconds) to reach desired hovered state.
@export var hover_delay: float = 0.0 ## Delay (in seconds) before starting animation.
@export var hover_transition: Tween.TransitionType
@export var hover_easing: Tween.EaseType
@export var hover_scale: Vector2 = Vector2.ONE
@export var hover_position_offset: Vector2 = Vector2.ZERO
@export_range(-180, 180) var hover_rotation_offset: float = 0.0
@export var hover_size_offset: Vector2 = Vector2.ZERO
@export var hover_modulate: Color = Color.WHITE

# Enter values (scale, position, etc.) are set immediately. We then transition to default values.
@export_group("Enter Settings")
@export var wait_for: UiAnimationComponent ## If this is valid, we will wait for it to finish its animation before starting our own.
@export var enter_time: float = 0.1 ## Time (in seconds) to reach default state.
@export var enter_delay: float = 0.0 ## Delay (in seconds) before starting animation.
@export var enter_transition: Tween.TransitionType
@export var enter_easing: Tween.EaseType
@export var enter_scale: Vector2 = Vector2.ONE
@export var enter_position_offset: Vector2 = Vector2.ZERO
@export_range(-180, 180) var enter_rotation_offset: float = 0.0
@export var enter_size_offset: Vector2 = Vector2.ZERO
@export var enter_modulate: Color = Color.WHITE

var target_node: Control ## Parent node assumed.
var default_values: Dictionary
var hover_values: Dictionary
var enter_values: Dictionary

var is_doing_enter_animation: bool = false

func _ready() -> void:
	target_node = get_parent()
	
	# Parents get initialized AFTER children, we want to use some of our parent's initial values, so we use call_deferred to ensure parent is initialized by then.
	if init_on_tree_entry:
		call_deferred("init")
	
func init() -> void:
	if centered:
		target_node.pivot_offset = target_node.size * 0.5
	default_values = {
		"scale": target_node.scale, 
		"position": target_node.position, 
		"rotation": target_node.rotation, 
		"size": target_node.size, 
		"self_modulate": target_node.self_modulate,
	}
	hover_values = {
		"scale": hover_scale, 
		"position": target_node.position + hover_position_offset, 
		"rotation": target_node.rotation + deg_to_rad(hover_rotation_offset), 
		"size": target_node.size + hover_size_offset, 
		"self_modulate": hover_modulate,
	}
	enter_values = {
		"scale": enter_scale, 
		"position": target_node.position + enter_position_offset, 
		"rotation": target_node.rotation + deg_to_rad(enter_rotation_offset), 
		"size": target_node.size + enter_size_offset, 
		"self_modulate": enter_modulate,
	}
	
	if wait_for:
		await wait_for.animation_enter_finished
	
	if use_enter_animation:
		# Start with enter properties.
		for property in properties:
			target_node.set(property, enter_values[property])
		add_tween(default_values, parallel_animations, enter_time, enter_delay, enter_transition, enter_easing, true)
		is_doing_enter_animation = true
		await animation_enter_finished
		is_doing_enter_animation = false
	else:
		animation_enter_finished.emit()
	
	if use_hover_animation:
		if hover_node:
			hover_node.mouse_entered.connect(add_tween.bind(
				hover_values,
				parallel_animations,
				hover_time,
				hover_delay,
				hover_transition,
				hover_easing,
				false,
			))
			hover_node.mouse_exited.connect(add_tween.bind(
				default_values,
				parallel_animations,
				hover_time,
				hover_delay,
				hover_transition,
				hover_easing,
				false,
			))
		else:
			target_node.mouse_entered.connect(add_tween.bind(
				hover_values,
				parallel_animations,
				hover_time,
				hover_delay,
				hover_transition,
				hover_easing,
				false,
			))
			target_node.mouse_exited.connect(add_tween.bind(
				default_values,
				parallel_animations,
				hover_time,
				hover_delay,
				hover_transition,
				hover_easing,
				false,
			))

func add_tween(values: Dictionary, parallel: bool, seconds: float, delay: float, transition: Tween.TransitionType, easing: Tween.EaseType, is_entering_animation: bool = false) -> void:
	if !is_inside_tree(): 
		return
	var tween: Tween = get_tree().create_tween()
	tween.set_parallel(parallel)
	tween.pause()
	for property in properties:
		tween.tween_property(target_node, property, values[property], seconds).set_trans(transition).set_ease(easing)
	await get_tree().create_timer(delay).timeout
	tween.play()
	if is_entering_animation:
		await tween.finished
		animation_enter_finished.emit()
