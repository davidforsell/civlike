class_name HoverTile
extends Node2D

@export var tile_width: int = 26
@export var tile_height: int = 34

@export var bob_height: float = 5.0
@export var bob_speed: float = 4.0

@onready var sprite: Sprite2D = $Sprite2D

var bob_time: float = 0.0
var base_y: float
var atlas_coords: Vector2i = Vector2i.ZERO
var hex_coords: Vector2i = Vector2i(1000, 1000)
var paused: bool = false
var tween: Tween = create_tween()

var atlas_source_0 = preload("res://assets/tilemaps/isometric_atlas.png")
var atlas_source_1 = preload("res://assets/tilemaps/isometric_tiles_2.png")

var current_atlas_source := 0

func _ready() -> void:
	base_y = position.y

func _process(delta: float):
	if paused:
		return
	bob_time += delta
	position.y = base_y + sin(bob_time * bob_speed) * bob_height

func update_source():
	var texture := sprite.texture as AtlasTexture
	match current_atlas_source:
		0:
			texture.atlas = atlas_source_0
			sprite.position.y += 2
		1:
			texture.atlas = atlas_source_1
			sprite.position.y -= 2

func set_atlas_position(coords: Vector2i, source: int):
	if source != current_atlas_source:
		current_atlas_source = source
		update_source()
	atlas_coords = coords
	var texture := sprite.texture as AtlasTexture
	texture.region.position.x = coords.x * tile_width
	texture.region.position.y = coords.y * tile_height


func reset_bob(height):
	paused = true
	var target_y = position.y - height
	tween.kill()
	tween = create_tween()
	tween.tween_property(
		self,
		"position:y",
		target_y,
		0.15
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	base_y = position.y
	bob_time = 0.0
	paused = false
