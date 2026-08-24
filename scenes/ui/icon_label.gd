class_name IconLabel
extends HBoxContainer

@export var icon: CompressedTexture2D
@export var text: String
@export var font_size: int
@export var icon_size: int

@onready var texture_rect: TextureRect = $TextureRect
@onready var label: Label = $Label

func _ready() -> void:
	texture_rect.texture = icon
	label.text = text
	if font_size != 0:
		label.add_theme_font_size_override("font_size", font_size)
	if icon_size != 0:
		texture_rect.custom_minimum_size.x = icon_size
		texture_rect.custom_minimum_size.y = icon_size

func update():
	if not is_node_ready():
		await ready
	texture_rect.texture = icon
	label.text = text
