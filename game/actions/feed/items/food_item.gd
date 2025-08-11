class_name FoodItem extends Control

signal item_clicked(food_item: FoodItem)

@onready var item_info: Panel = %ItemInfo
@onready var label_name: Label = %LabelName
@onready var label_price: Label = %LabelPrice
@onready var label_consume: Label = %LabelConsume
@onready var icon: TextureRect = %Icon

@export var food_resource: FoodResource

func _ready() -> void:
	item_info.hide()
	if food_resource:
		icon.texture = food_resource.item_icon
		label_name.text = food_resource.item_name
		label_price.text = "Cost: %d" % food_resource.price
		label_consume.text = "Value: %.1f" % food_resource.consume_reward

func _on_mouse_entered() -> void:
	item_info.show()

func _on_mouse_exited() -> void:
	item_info.hide()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		item_clicked.emit(self)
		accept_event()
