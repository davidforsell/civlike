class_name Structure
extends Occupant

static var server_next_id := 1
var id: int:
	set(new):
		if is_id_set: return
		id = new
		is_id_set = true
		id_set.emit()

var map: HexMap
var player_owner_id: int
var definition: StructureDefinition
var banner_scene = preload("res://scenes/ui/banner.tscn")

var banner: Banner
var banner_offset: Vector2 = Vector2(-4, -5)

var sprite_2d: Sprite2D
var label: StructureLabel

var border: Border = Border.new()

var is_id_set: bool = false
signal id_set

var hp := 0
var defense := 0

var color: Color = Color.WHITE:
	set(new):
		color = new
		border.color = new
		map.set_border_overlay(map_position, new)
		map.hex_borders.update_borders()
		if !banner:
			await ready
		banner.modulate = color

var structure_name: String = "":
	set(value):
		structure_name = value
		label.set_structure_name(value)
		if NetworkHandler.is_server:
			StructureInfo.create_name_updated(id, structure_name).broadcast(NetworkHandler.connection)

var population: int:
	set(value):
		population = value
		label.set_population(value)

var money: int:
	set(value):
		money = value
		label.set_coins(value)

var upgrade_counter: int = 0

var label_scene = preload("res://scenes/structures/structure_label.tscn")

func _init(game_map: HexMap, my_definition: StructureDefinition, coords, p_owner_id: int):
	map = game_map
	definition = my_definition
	map_position = coords
	player_owner_id = p_owner_id
	hp = definition.base_hp
	defense = definition.base_defense
	if NetworkHandler.is_server:
		id = server_next_id
		server_next_id += 1

func take_damage(movable: Movable):
	var dmg = movable.total_damage - defense
	hp = clampi(hp - dmg, 0, definition.base_hp)
	DamageNumbers.show_damage(self, dmg)
	if hp <= 0:
		banner.fall_animation()
		await banner.finished
		GameState.switch_structure_ownership(self, movable.player_owner_id)
		banner.raise_animation()
		hp = 1

func _ready() -> void:
	if !is_id_set:
		await id_set
	
	GameState.add_structure(self)
	border.add_hex(map_position)
	
	sprite_2d = Sprite2D.new()
	z_index = 3
	label = label_scene.instantiate()
	label.scale = Vector2(1.0 / map.scale.x, 1.0 / map.scale.y)
	y_sort_enabled = true
	add_child(label)
	add_child(sprite_2d)
	banner = banner_scene.instantiate()
	add_child(banner)
	banner.position += banner_offset
	banner.raise_animation(0.1)
	sprite_2d.texture = definition.texture
	label.position.y -= sprite_2d.get_rect().size.y / 2 + 2
	border.add_hex(map_position)
	money = definition.starting_money
	population = definition.starting_population
	border.color_updated.connect(_on_border_color_update)
	
	if NetworkHandler.is_server:
		structure_name = TownNameGenerator.generate_name()

func _on_border_color_update(new_color: Color):
	label.set_structure_name_color(new_color)

func upgrade_structure():
	upgrade_counter = 6
	map.hex_selected.connect(_on_upgrade_location_selected)
	map.clear_highlights()
	highlight_upgradable_tiles()
	map.upgrading_structure = true
	draw_border()

func highlight_upgradable_tiles():
	var highlighted: Array[Vector2i] = []
	
	var existing_borders: Array[Vector2i] = map.get_existing_borders()
	
	for hex in border.contents:
		for dir in map.DIRECTIONS:
			var new_coords := hex + dir
			if new_coords in border.contents or new_coords in highlighted or new_coords in existing_borders:
				continue
			
			map.highlight_cell(new_coords)

func draw_border():
	map.hide_hover_tile()
	map.hex_borders.update_borders()

func select():
	if NetworkHandler.is_server: return
	GameState.player_datas[ClientNetworkGlobals.id].selected_structure = self

func _on_upgrade_location_selected(coords: Vector2i):
	if coords in border.contents:
		highlight_upgradable_tiles()
		draw_border()
		return
	var valid: bool = false
	var existing_borders: Array[Vector2i] = map.get_existing_borders()
	
	for dir in map.DIRECTIONS:
		if coords + dir in border.contents and not coords in existing_borders:
			valid = true
	if not valid:
		highlight_upgradable_tiles()
		draw_border()
		return
	upgrade_counter -= 1
	
	border.add_hex(coords)
	map.set_border_overlay(coords, color)
	
	if upgrade_counter <= 0:
		map.hex_selected.disconnect(_on_upgrade_location_selected)
		map.upgrading_structure = false
		map.clear_highlights()
		draw_border()
		return
	highlight_upgradable_tiles()
	draw_border()
