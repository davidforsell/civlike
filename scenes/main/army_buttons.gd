class_name ArmyButtons extends HBoxContainer

@onready var info_button = $InfoButton

func set_owner_buttons_visible():
	info_button.visible = true

func set_non_owner_buttons_visible():
	info_button.visible = true

func hide_buttons():
	info_button.visible = false
