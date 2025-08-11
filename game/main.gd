class_name Main extends Node2D

@onready var button_feed: Button = %ButtonFeed
@onready var button_wash: Button = %ButtonWash
@onready var button_headpat: Button = %ButtonHeadpat
@onready var button_talk: Button = %ButtonTalk

@onready var button_sound: TextureButton = %ButtonSound
@onready var button_fullscreen: TextureButton = %ButtonFullscreen
@onready var button_exit: TextureButton = %ButtonExit


@onready var label_points_friendship: Label = %LabelPointsFriendship
@onready var anim_friendship_points: UiAnimationComponent = %AnimFriendshipPoints

@onready var bar_friendship: ProgressBar = %BarFriendship
@onready var bar_hunger: StatBar = %BarHunger
@onready var bar_hygiene: StatBar = %BarHygiene
@onready var bar_affection: StatBar = %BarAffection
@onready var bar_chat: StatBar = %BarChat

@onready var sprite_catgirl: TextureRect = %SpriteCatgirl
@onready var anim_catgirl: AnimationPlayer = %AnimCatgirl

@onready var food_container: PanelContainer = %FoodContainer
@onready var base_food_item: FoodItem = %BaseFoodItem
@onready var food_grid_container: GridContainer = %FoodGridContainer

@onready var speech_bubble: SpeechBubble = %SpeechBubble
@onready var chat_container: PanelContainer = %ChatContainer
@onready var text_edit: TextEdit = %TextEdit
@onready var ai_brain: Player2AINPC = %AIBrain
@onready var emote: TextureRect = %Emote

@onready var vfx_bubbles: CPUParticles2D = %VFXBubbles
@onready var vfx_hearts: CPUParticles2D = %VfxHearts
@onready var vfx_crumbs: CPUParticles2D = %VfxCrumbs

@onready var timer_cooldown_notify_on_action: Timer = %TimerCooldownNotifyOnAction

const TEXTURE_SOUND_OFF = preload("uid://dm4ne6hu320fd")
const TEXTURE_SOUND_ON = preload("uid://5dmurf2ts4y6")

#===========================================

## We will load catgirl textures from:[br]
## "res://game/catgirls/art/catgirl_1.png"[br]
## "res://game/catgirls/art/catgirl_2.png"[br]
## "res://game/catgirls/art/catgirl_3.png"[br]
## ...[br]
## This variables says how many catgirl textures are stored in that folder.[br]
## We will choose a random number for new catgirls, but will load the same across sessions.[br]
##[br]
## We could export all textures in an array to avoid doing load() at runtime, but the memory cost would be worse, I think.
@export_range(0, 100) var catgirl_texture_count: int = 25

@export_group("prompts")
@export var prompt_on_feed: String = "You are being fed %s. Give a short response."
@export var prompt_on_wash: String = "You are being washed with a soap at the moment. Give a short response."
@export var prompt_on_headpat: String = "You are being headpatted and feeling affectionate. Give a short response."
@export var prompt_on_poke: String = "You have just been poked. It hurt a bit. Give a short response."

@export_group("resources")
#@export var all_catgirls: Array[CatgirlResource]
@export var all_food: Array[FoodResource]

@export_group("packed_scenes")
#@export var catgirl_card_scene: PackedScene
@export var food_item_scene: PackedScene

@export_group("textures")
@export_subgroup("cursors")
@export var texture_cursor_default: Texture2D
@export var texture_cursor_poke: Texture2D
@export var texture_cursor_headpat: Texture2D
@export var texture_cursor_soap: Texture2D
@export_subgroup("emotes")
@export var texture_emote_affectionate: Texture2D ## Used in Tool Calls.
@export var texture_emote_disbelief: Texture2D ## Used in Tool Calls.
@export var texture_emote_flattered: Texture2D ## Used in Tool Calls.
@export var texture_emote_questioning: Texture2D ## Used in Tool Calls.
@export var texture_emote_thinking: Texture2D ## Used when AI is thinking.

enum Action {NONE, FEED, WASH, HEADPAT, CHAT}
var action_current: Action = Action.NONE

var cached_friendship_points: int = -1
var catgirl_current: CatgirlResource
var can_poke: bool = false
var food_current: FoodResource
var ai_is_thinking: bool = false
var can_notify_on_action: bool = true

func set_catgirl_current(_player2_character: Dictionary) -> void:
	if _player2_character.is_empty():
		return
	catgirl_current = CatgirlResource.new()
	catgirl_current.init(_player2_character)
	
	# This catgirl_name and texture_id initialization should happen only first time, otherwise we should get them from deserialization.
	if catgirl_current.catgirl_name.is_empty():
		catgirl_current.catgirl_name = _player2_character["short_name"]
	if catgirl_current.texture_id <= -1:
		randomize()
		catgirl_current.texture_id = randi_range(1, catgirl_texture_count)
	
	if !catgirl_current.changed.is_connected(_on_catgirl_changed):
		catgirl_current.changed.connect(_on_catgirl_changed)
	cached_friendship_points = -1
	
	sprite_catgirl.texture = load("res://game/catgirls/art/catgirl_%d.png" % catgirl_current.texture_id)
	update_all_ui()
	anim_catgirl.play("idle")

func init_all_food() -> void:
	food_container.hide()
	food_current = null
	base_food_item.item_clicked.connect(_on_food_item_clicked)
	for food in all_food:
		var food_item: FoodItem = food_item_scene.instantiate()
		food_item.food_resource = food
		food_item.item_clicked.connect(_on_food_item_clicked)
		food_grid_container.add_child(food_item)

func _ready() -> void:
	init_all_food()
	
	chat_container.hide()
	speech_bubble.hide()
	
	update_all_ui()
	
	var current_volume: float = SaveFileHandler.get_volume("master") 
	if current_volume > 0.0:
		button_sound.texture_normal = TEXTURE_SOUND_ON
	else:
		button_sound.texture_normal = TEXTURE_SOUND_OFF
		
	if texture_cursor_default:
		Input.set_custom_mouse_cursor(texture_cursor_default, Input.CURSOR_ARROW, texture_cursor_default.get_size() * 0.5)

func _process(_delta: float) -> void:
	if !catgirl_current && !ai_brain._selected_character.is_empty():
		# Wait until Player2 initialized _selected_character, then initialize CatgirlResource.
		set_catgirl_current(ai_brain._selected_character)
	
	if catgirl_current:
		if action_current == Action.WASH:
			vfx_bubbles.global_position = get_global_mouse_position()
		elif action_current == Action.HEADPAT:
			vfx_hearts.global_position = get_global_mouse_position()
		elif action_current == Action.FEED:
			vfx_crumbs.global_position = get_global_mouse_position()

func update_all_ui() -> void:
	if !catgirl_current:
		bar_friendship.hide()
		bar_hunger.hide()
		bar_hygiene.hide()
		bar_affection.hide()
		bar_chat.hide()
		return
	
	bar_friendship.show()
	bar_friendship.max_value = catgirl_current.MAX_FRIENDSHIP
	bar_friendship.value = catgirl_current.progress_friendship
	if cached_friendship_points != catgirl_current.points_friendship:
		cached_friendship_points = catgirl_current.points_friendship
		label_points_friendship.text = "%d" % catgirl_current.points_friendship
		if !anim_friendship_points.is_doing_enter_animation:
			anim_friendship_points.init()
	
	bar_hunger.set_values(catgirl_current.MAX_HUNGER, catgirl_current.progress_hunger)
	bar_hygiene.set_values(catgirl_current.MAX_HYGIENE, catgirl_current.progress_hygiene)
	bar_affection.set_values(catgirl_current.MAX_AFFECTION, catgirl_current.progress_affection)
	bar_chat.set_values(catgirl_current.MAX_CHAT, catgirl_current.progress_chat)
	
	for food in food_grid_container.get_children():
		if food is FoodItem:
			if catgirl_current.points_friendship < food.food_resource.price:
				food.icon.self_modulate = Color(0.5, 0.5, 0.5, 0.6)
			else:
				food.icon.self_modulate = Color.WHITE

#
# Signals
#
func _on_catgirl_changed() -> void:
	if !catgirl_current:
		return
	SaveFileHandler.save_all()
	ai_brain.save_conversation_history()
	update_all_ui()

# Settings
#
func _on_button_sound_pressed() -> void:
	# Toggle volume
	var current_volume: float = SaveFileHandler.get_volume("master")
	if current_volume > 0.0:
		SaveFileHandler.set_volume("master", 0.0)
		if TEXTURE_SOUND_OFF:
			button_sound.texture_normal = TEXTURE_SOUND_OFF
	else:
		SaveFileHandler.set_volume("master", 1.0)
		if TEXTURE_SOUND_ON:
			button_sound.texture_normal = TEXTURE_SOUND_ON
func _on_button_fullscreen_pressed() -> void:
	var current_fullscreen_state = SaveFileHandler.load_data("video").fullscreen
	SaveFileHandler.set_fullscreen(!current_fullscreen_state)
func _on_button_exit_pressed() -> void:
	SaveFileHandler.save_all()
	get_tree().quit()

func _on_food_item_clicked(food_item: FoodItem) -> void:
	if !catgirl_current:
		return
	if action_current == Action.FEED && food_current == food_item.food_resource:
		action_current = Action.NONE
		if texture_cursor_default:
			Input.set_custom_mouse_cursor(texture_cursor_default, Input.CURSOR_ARROW, texture_cursor_default.get_size() * 0.5)
		else:
			Input.set_custom_mouse_cursor(null)
	else:
		action_current = Action.FEED
		if food_item && food_item.food_resource && catgirl_current.points_friendship >= food_item.food_resource.price:
			food_current = food_item.food_resource
			Input.set_custom_mouse_cursor(food_item.food_resource.item_icon, Input.CURSOR_ARROW, food_item.food_resource.item_icon.get_size() * 0.5)
			food_container.hide()

# Catgirl sprite
#
func _on_sprite_catgirl_gui_input(event: InputEvent) -> void:
	if !catgirl_current:
		return
	if event is InputEventMouseMotion:
		if action_current == Action.WASH && event.relative > Vector2.ONE:
			var reward: float = catgirl_current.MAX_HYGIENE / 500.0
			var before := catgirl_current.progress_hygiene
			catgirl_current.progress_hygiene += reward
			if before != catgirl_current.progress_hygiene:
				catgirl_current.progress_friendship += reward
				vfx_bubbles.set_emitting(true)
				anim_catgirl.play("wash")
				if can_notify_on_action:
					ai_brain.notify(prompt_on_wash)
					can_notify_on_action = false
					timer_cooldown_notify_on_action.start()
	
	if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT && event.is_pressed():
		if action_current == Action.NONE && can_poke:
			anim_catgirl.play("poke")
			if can_notify_on_action:
				ai_brain.notify(prompt_on_poke)
				can_notify_on_action = false
				timer_cooldown_notify_on_action.start()
		elif action_current == Action.HEADPAT:
			if !vfx_hearts.is_emitting():
				var reward: float = catgirl_current.MAX_AFFECTION / 15.0 # divide by number of headpats to max affection.
				var before := catgirl_current.progress_affection
				catgirl_current.progress_affection += reward
				if before != catgirl_current.progress_affection:
					catgirl_current.progress_friendship += reward
					vfx_hearts.set_emitting(true)
					anim_catgirl.play("headpat")
					if can_notify_on_action:
						ai_brain.notify(prompt_on_headpat)
						can_notify_on_action = false
						timer_cooldown_notify_on_action.start()
		elif action_current == Action.FEED && food_current:
			if !vfx_crumbs.is_emitting():
				var before := catgirl_current.progress_hunger
				catgirl_current.progress_hunger += food_current.consume_reward
				if before != catgirl_current.progress_hunger:
					catgirl_current.progress_friendship += food_current.consume_reward
					vfx_crumbs.set_emitting(true)
					anim_catgirl.play("feed")
					if can_notify_on_action:
						ai_brain.notify(prompt_on_feed % food_current.item_name)
						can_notify_on_action = false
						timer_cooldown_notify_on_action.start()

func _on_sprite_catgirl_mouse_entered() -> void:
	if catgirl_current && action_current == Action.NONE && texture_cursor_poke:
		can_poke = true
		Input.set_custom_mouse_cursor(texture_cursor_poke, Input.CURSOR_ARROW, texture_cursor_poke.get_size() * 0.5)

func _on_sprite_catgirl_mouse_exited() -> void:
	can_poke = false
	if action_current == Action.NONE:
		if texture_cursor_default:
			Input.set_custom_mouse_cursor(texture_cursor_default, Input.CURSOR_ARROW, texture_cursor_default.get_size() * 0.5)
		else:
			Input.set_custom_mouse_cursor(null)

# Actions.
#
func _on_button_feed_pressed() -> void:
	food_container.visible = !food_container.visible
	chat_container.hide()
	#speech_bubble.hide()
	action_current = Action.FEED
	if texture_cursor_default:
		Input.set_custom_mouse_cursor(texture_cursor_default, Input.CURSOR_ARROW, texture_cursor_default.get_size() * 0.5)
	else:
		Input.set_custom_mouse_cursor(null)

func _on_button_wash_pressed() -> void:
	food_container.hide()
	food_current = null
	chat_container.hide()
	#speech_bubble.hide()
	if action_current == Action.WASH:
		action_current = Action.NONE
		if texture_cursor_default:
			Input.set_custom_mouse_cursor(texture_cursor_default, Input.CURSOR_ARROW, texture_cursor_default.get_size() * 0.5)
		else:
			Input.set_custom_mouse_cursor(null)
	else:
		action_current = Action.WASH
		if texture_cursor_soap:
			Input.set_custom_mouse_cursor(texture_cursor_soap, Input.CURSOR_ARROW, texture_cursor_soap.get_size() * 0.5)

func _on_button_headpat_pressed() -> void:
	food_container.hide()
	food_current = null
	chat_container.hide()
	#speech_bubble.hide()
	if action_current == Action.HEADPAT:
		action_current = Action.NONE
		if texture_cursor_default:
			Input.set_custom_mouse_cursor(texture_cursor_default, Input.CURSOR_ARROW, texture_cursor_default.get_size() * 0.5)
		else:
			Input.set_custom_mouse_cursor(null)
	else:
		action_current = Action.HEADPAT
		if texture_cursor_headpat:
			Input.set_custom_mouse_cursor(texture_cursor_headpat, Input.CURSOR_ARROW, texture_cursor_headpat.get_size() * 0.5)

func _on_button_talk_pressed() -> void:
	if !catgirl_current: 
		return
	food_container.hide()
	food_current = null
	chat_container.visible = !chat_container.visible
	action_current = Action.CHAT
	if texture_cursor_default:
		Input.set_custom_mouse_cursor(texture_cursor_default, Input.CURSOR_ARROW, texture_cursor_default.get_size() * 0.5)
	else:
		Input.set_custom_mouse_cursor(null)

func _on_anim_catgirl_animation_finished(_anim_name: StringName) -> void:
	anim_catgirl.play("idle")

# AI
#
func _on_button_send_pressed() -> void:
	if !catgirl_current: return
	ai_brain.chat(text_edit.text)
func _on_ai_brain_chat_received(message: String) -> void:
	if !catgirl_current: return
	speech_bubble.show()
	speech_bubble.show_text(message)
	if action_current == Action.CHAT:
		var reward: float = catgirl_current.MAX_CHAT / 5.0 # Talk {denom} times to maximize chat.
		var before := catgirl_current.progress_chat
		catgirl_current.progress_chat += reward
		if before != catgirl_current.progress_chat:
			catgirl_current.progress_friendship += reward
func _on_ai_brain_chat_failed(error_code: int) -> void:
	push_error("Player2AINPC chat failed! Error code: %d" % error_code)
func _on_ai_brain_thinking_began() -> void:
	ai_is_thinking = true
	if emote:
		emote.texture = texture_emote_thinking
func _on_ai_brain_thinking_ended() -> void:
	ai_is_thinking = false
	if emote:
		emote.texture = null

# Timers
#
func _on_timer_cooldown_notify_on_action_timeout() -> void:
	can_notify_on_action = true
