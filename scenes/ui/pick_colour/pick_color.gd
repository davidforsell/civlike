class_name PickColor
extends Control

@onready var color_box_scene = preload("res://scenes/ui/pick_colour/color_box.tscn")
@onready var grid_container: GridContainer = $PanelContainer/VBoxContainer/PanelContainer/MarginContainer/GridContainer

signal color_picked(color: Color)

func _ready() -> void:
	for i in range(50):
		var color_box: ColorBox = color_box_scene.instantiate()
		var hue = float(i) / 50.0
		var value: float
		match i % 3:
			0:
				value = 1.0
			1:
				value = 0.85
			2:
				value = 0.65
		
		var color := Color.from_hsv(hue, 0.8, value)
		
		color_box.set_color(color)
		grid_container.add_child(color_box)
		color_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		color_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
		color_box.selected.connect(_on_color_selected)

func _on_color_selected(color: Color):
	color_picked.emit(color)
