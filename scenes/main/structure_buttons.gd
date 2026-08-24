class_name StructureButtons
extends HBoxContainer

@onready var build_button = $BuildButton
@onready var train_button = $TrainButton
@onready var info_button = $InfoButton

func set_owner_buttons_visible():
	build_button.visible = true
	train_button.visible = true
	info_button.visible = true

func set_non_owner_buttons_visible():
	info_button.visible = true
	build_button.visible = false
	train_button.visible = false

func hide_buttons():
	info_button.visible = false
	build_button.visible = false
	train_button.visible = false
