extends Node

@onready var emote: TextureRect = %Emote

@export var main: Main

func feeling_affectionate() -> void:
	emote.texture = main.texture_emote_affectionate
func feeling_disbelief() -> void:
	emote.texture = main.texture_emote_disbelief
func feeling_flattered() -> void:
	emote.texture = main.texture_emote_flattered
func feeling_questioning() -> void:
	emote.texture = main.texture_emote_questioning

func comment_on_hunger_maybe() -> String:
	if main.catgirl_current:
		var percent: float = main.catgirl_current.progress_hunger / main.catgirl_current.MAX_HUNGER
		if percent < 0.4:
			return "true"
	return "false"
func comment_on_hygiene_maybe() -> String:
	if main.catgirl_current:
		var percent: float = main.catgirl_current.progress_hygiene / main.catgirl_current.MAX_HYGIENE
		if percent < 0.4:
			return "true"
	return "false"
func comment_on_affection_maybe() -> String:
	if main.catgirl_current:
		var percent: float = main.catgirl_current.progress_affection / main.catgirl_current.MAX_AFFECTION
		if percent < 0.4:
			return "true"
	return "false"
func comment_on_chat_maybe() -> String:
	if main.catgirl_current:
		var percent: float = main.catgirl_current.progress_chat / main.catgirl_current.MAX_CHAT
		if percent < 0.4:
			return "true"
	return "false"
