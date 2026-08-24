class_name CustomPanel
extends Control

@export var panel_button: TextureButton

signal exit
signal enter

func _ready() -> void:
	if panel_button:
		panel_button.pressed.connect(_on_panel_button_pressed)

func close():
	exit.emit()
	visible = false
	_on_exit()

func _on_bg_gui_input(event: InputEvent) -> void:
	if event.is_action_released("select"):
		close()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("escape"):
		close()

func _on_panel_button_pressed():
	enter.emit()
	visible = true
	_on_enter()

func _on_enter():
	pass

func _on_exit():
	pass
