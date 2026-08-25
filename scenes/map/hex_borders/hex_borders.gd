class_name HexBorders
extends Node2D

@export var map: HexMap

var textures: Dictionary[Vector2i, CompressedTexture2D] = {
	HexMap.DIRECTIONS[0]: preload("res://assets/sprites/bottom_right_border.png"),
	HexMap.DIRECTIONS[1]: preload("res://assets/sprites/right_border.png"),
	HexMap.DIRECTIONS[2]: preload("res://assets/sprites/top_right_border.png"),
	HexMap.DIRECTIONS[3]: preload("res://assets/sprites/top_left_border.png"),
	HexMap.DIRECTIONS[4]: preload("res://assets/sprites/left_border.png"),
	HexMap.DIRECTIONS[5]: preload("res://assets/sprites/bottom_left_border.png")
}

var border_line_scene = preload("res://scenes/map/hex_borders/border_line.tscn")
var border_sprites: Array[BorderLine] = []

func clear_borders():
	for sprite in border_sprites:
		map.remove_occupant(sprite)
		sprite.queue_free()
	border_sprites.clear()

func draw_border_line(hex_coords: Vector2i, dir: Vector2i, color: Color):
	var scene: BorderLine = border_line_scene.instantiate()
	add_child(scene)
	scene.global_position = map.tile_to_world(hex_coords)
	scene.set_texture(textures[dir])
	scene.modulate = color
	scene.map_position = hex_coords
	map.add_occupant(scene)
	border_sprites.append(scene)

func draw_border(border: Border):
	for hex in border.contents:
		for dir in HexMap.DIRECTIONS:
			if not hex + dir in border.contents:
				draw_border_line(hex, dir, border.color)

func update_borders():
	clear_borders()
	draw_all_player_borders()

func draw_all_player_borders():
	for structure_id in GameState.structures:
		var structure := GameState.structures[structure_id]
		draw_border(structure.border)
