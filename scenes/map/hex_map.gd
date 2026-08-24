class_name HexMap
extends Node2D

@onready var tile_map_layer: TileMapLayer = $Terrain
@onready var hover_tile: HoverTile = $HoverTile
@onready var border_camera: Camera2D = $BorderOverlay/SubViewportContainer/SubViewport/BorderCamera
@onready var border_overlays: BorderOverlay = $BorderOverlay/SubViewportContainer/SubViewport/Borders
@onready var border_overlay_container: SubViewportContainer = $BorderOverlay/SubViewportContainer

@export var height_noise: FastNoiseLite
@export var temperature_noise: FastNoiseLite

@export var tiles: Dictionary[int, HexTileDefinition] = {} # TileDefinitions by Id
@export var tile_name: Dictionary[String, int] = {} # Tile Ids by name
@export var movables_definitions: Array[MovableDefinition] = []
@export var ocean_level := 0.0
@export var bob_tile_height := 2.0
@export var hex_borders: HexBorders

var rng = RandomNumberGenerator.new()
var highlight_scene := preload("res://scenes/map/highlight/highlight.tscn")
var world_seed: int

signal map_ready
var map_is_ready: bool = false

const TILE_ATLAS_SOURCE_ID := 0
const EMPTY_ATLAS_COORDS := Vector2i(0, 0)
const HEX_COORDS_INF = Vector2i(10000, 10000)
const DARK_ATLAS_COORDS := Vector2i(1, 1)


const HEX_WIDTH_PX: int = 26
const HEX_HEIGHT_PX: int = 24

var highlighted_cells: Dictionary[Vector2i, Occupant] = {}
var occupants: Dictionary[Vector2i, Array] = {}

var carried_occupants: Array[Occupant] = [] # for when a movable is on the hovered tile
var selected_movable: Movable = null
var selected_structure: Structure = null

var map: Dictionary[Vector2i, int] = {}


var upgrading_structure: bool = false
var tile_hovered: bool = false
var block: bool = false

signal hex_selected(coords: Vector2i)

const DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(1, -1),
	Vector2i(0, -1),
	Vector2i(-1, 0),
	Vector2i(-1, 1),
	Vector2i(0, 1)
]

func _enter_tree() -> void:
	ClientNetworkGlobals.handle_terrain_info.connect(client_handle_terrain_info)

func _exit_tree() -> void:
	pass

func client_handle_terrain_info(info: TerrainInfo):
	print("Client ", str(ClientNetworkGlobals.id), ": terrain info recieved")
	set_map(info.coordinates, info.terrain_ids)

func _ready() -> void:
	if !NetworkHandler.is_server: return
	height_noise.seed = rng.randi()
	temperature_noise.seed = rng.randi()
	world_seed = rng.randi()

func _process(_delta: float):
	if block:
		return
	var mouse_coords := get_mouse_coords()
	if hover_tile.hex_coords != mouse_coords:
		if tile_hovered:
			draw_tile(hover_tile.hex_coords)
		hover_cell(mouse_coords)
		tile_hovered = true

func set_border_overlay(coords: Vector2i, color: Color):
	border_overlays.modulate_cell(coords, color)

func _on_movable_death(movable: Movable):
	remove_occupant(movable)
	GameState.player_datas[movable.player_owner_id].owned_armies.erase(movable)
	movable.queue_free()

func add_movable(definition: MovableDefinition, coords: Vector2i, p_owner_id: int) -> Movable:
	if coords in occupants:
		push_warning("Tiles should not contain multiple occupants!")
	var movable = Movable.new(self, definition, p_owner_id)
	GameState.player_datas[p_owner_id].owned_armies.append(movable)
	movable.set_coords(coords)
	movable.died.connect(_on_movable_death)
	if not coords in occupants:
		occupants[coords] = []
	occupants[coords].append(movable)
	add_child(movable)
	
	if hide_hover_tile:
		hide_hover_tile()
	
	movable.global_position = tile_to_world(coords)
	return movable

func highlight_cells(coords: Array[Vector2i]):
	for coord in coords:
		highlight_cell(coord)

func add_unit(type: UnitDefinition, coords: Vector2i, p_owner_id: int):
	var movable: Movable = null
	if coords in occupants:
		for occupant in occupants[coords]:
			if occupant is Movable:
				movable = occupant
				break
	if not movable:
		movable = add_movable(movables_definitions[0], coords, p_owner_id)
		
	var unit := Unit.new(type)
	movable.add_unit(unit)
	GameState.player_datas[p_owner_id].selected_movable = movable
	

func add_structure(definition: StructureDefinition, coords: Vector2i, p_owner_id: int, hide_hover: bool = false) -> Structure:
	if coords in occupants:
		push_warning("Tiles should not contain multiple occupants!")
	var structure = Structure.new(self, definition, coords, p_owner_id)
	if coords not in occupants:
		occupants[coords] = []
	occupants[coords].append(structure)
	add_child(structure)
	structure.global_position = tile_to_world(coords)
	if hide_hover:
		hide_hover_tile()
	
	return structure

func get_mouse_coords() -> Vector2i:
	return tile_map_layer.local_to_map(get_global_mouse_position() / scale.x)

func hover_cell(coords: Vector2i):
	drop_carried_occupants()
	
	var atlas_coords := tile_map_layer.get_cell_atlas_coords(coords)
	hover_tile.hex_coords = coords
	hover_tile.set_atlas_position(atlas_coords, get_tile_resource(coords).atlas_source)
	hover_tile.global_position = tile_to_world(coords)
	hover_tile.reset_bob(bob_tile_height)
	
	tile_map_layer.set_cell(
		coords,
		0,
		EMPTY_ATLAS_COORDS)
	
	if coords in occupants:
		for occupant in occupants[coords]:
			occupant.reparent(hover_tile, true)
			carried_occupants.append(occupant)

func add_occupant(occupant: Occupant):
	var coords := occupant.map_position
	if not coords in occupants:
		occupants[coords] = []
	occupants[coords].append(occupant)

func get_hex_ring(centre: Vector2i, radius: int) -> Array[Vector2i]:
	var coords := DIRECTIONS[4] * radius + centre
	var ring: Array[Vector2i] = []
	for i in range(6):
		for _i in range(radius):
			coords += DIRECTIONS[i]
			ring.append(coords)
	return ring

func remove_occupant(occupant: Occupant):
	var coords := occupant.map_position
	carried_occupants.erase(occupant)
	
	if coords not in occupants:
		return
	occupants[coords].erase(occupant)
	if occupants[coords].is_empty():
		occupants.erase(coords)

func drop_carried_occupants():
	for occupant in carried_occupants:
		occupant.reparent(self)
		var coords := occupant.map_position
		occupant.global_position = tile_to_world(coords)
	carried_occupants = []

func create_hexagon_map(radius: int):
	create_tile(Vector2i.ZERO)
	for i in range(1, radius + 1):
		create_ring(i)
	map_ready.emit()
	map_is_ready = true
	server_broadcast_terrain_info()

func server_broadcast_terrain_info():
	if !NetworkHandler.is_server: return
	
	var coordinates: Array[Vector2i]
	var terrain_ids: Array[int]
	
	var keys := map.keys()
	
	for i in range(keys.size()):
		var key = keys[i]
		coordinates.append(key)
		terrain_ids.append(map[key])

	TerrainInfo.create(coordinates, terrain_ids).broadcast(NetworkHandler.connection)

func draw_map():
	for tile in map:
		draw_tile(tile)

func create_ring(radius: int):
	var coords := DIRECTIONS[4] * radius
	for i in range(6):
		for _i in range(radius):
			coords += DIRECTIONS[i]
			create_tile(coords)

func create_tile(coords: Vector2i):
	var tile := generate_tile(coords)
	map[coords] = tile.id

func set_tile(coords: Vector2i, tile_resource_id: int):
	map[coords] = tile_resource_id
	border_overlays.set_cell(coords, TILE_ATLAS_SOURCE_ID, DARK_ATLAS_COORDS)

func set_map(coords: Array[Vector2i], ids: Array[int]):
	for i in range(coords.size()):
		set_tile(coords[i], ids[i])
	draw_map()
	map_ready.emit()
	map_is_ready = true

func get_tile_resource(coords: Vector2i) -> HexTileDefinition:
	if not coords in map:
		return tiles[tile_name["empty"]]
	return tiles[map[coords]]

func draw_tile(coords: Vector2i):
	var tile_resource_id: int
	if coords not in map:
		tile_resource_id = tile_name["empty"]
	else:
		tile_resource_id = map[coords]
	var tile := tiles[tile_resource_id]
	tile_map_layer.set_cell(coords, tile.atlas_source, tile.atlas_coords)

func generate_tile(coords: Vector2i) -> HexTileDefinition:
	var height = height_noise.get_noise_2d(coords.x, coords.y)
	var temperature = temperature_noise.get_noise_2d(coords.x, coords.y)
	var random := generate_tile_random(coords)
	
	if height < ocean_level:
		return tiles[tile_name["water"]]
	elif height > ocean_level + 0.6:
		return tiles[tile_name["mountain"]]
	elif temperature < -0.6:
		return tiles[tile_name["snow"]]
	else:
		if random < 0.05:
			return tiles[tile_name["rock"]]
		elif random < 0.1:
			return tiles[tile_name["forest"]]
		else:
			return tiles[tile_name["grass"]]

func generate_tile_random(coords: Vector2i) -> float:
	rng.seed = hash(Vector3i(coords.x, coords.y, world_seed))
	return rng.randf()

func highlight_cell(coords: Vector2i, color: Color = Color.WHITE):
	if coords in highlighted_cells:
		return
	
	var scene: Occupant = highlight_scene.instantiate()
	highlighted_cells[coords] = scene
	add_child(scene)
	scene.map_position = coords
	scene.global_position = tile_to_world(coords)
	scene.modulate = color
	if not coords in occupants:
		occupants[coords] = []
	occupants[coords].append(scene)

func clear_highlights():
	for coords in highlighted_cells:
		var scene := highlighted_cells[coords]
		remove_occupant(scene)
		scene.queue_free()
	
	highlighted_cells = {}

func tile_to_world(coords: Vector2i):
	var global_pos = tile_map_layer.to_global(
		tile_map_layer.map_to_local(coords))
	global_pos.y += 4
	return global_pos

func on_select_pressed():
	if block:
		return
	
	var coords := get_mouse_coords()
	
	clear_highlights()
	
	hex_selected.emit(coords)
	
	if upgrading_structure:
		return
	if selected_structure:
		selected_structure.deselect()
	if selected_movable:
		var movable := selected_movable
		if movable.can_move_to(coords):
			move_movable(coords, movable)
		selected_movable = null
	elif coords in occupants:
		for occupant in occupants[coords]:
			if occupant is Movable and occupant.player_owner_id == TurnManager.get_current_player_id():
				select_movable(occupant, coords)
			elif occupant is Structure:
				occupant.select()
				selected_structure = occupant
	else:
		selected_movable = null
		if selected_structure:
			selected_structure.deselect()
			selected_structure = null

func attack_structure(movable: Movable, structure: Structure):
	_on_blocking_action_start()
	occupants[movable.map_position].erase(movable)
	movable.attack(structure)
	movable.end_attack.connect(_on_end_attack)

func attack_movable(movable: Movable, other: Movable):
	_on_blocking_action_start()
	occupants[movable.map_position].erase(movable)
	movable.attack(other)
	movable.end_attack.connect(_on_end_attack)

func _on_end_attack(movable: Movable):
	add_occupant(movable)
	movable.end_attack.disconnect(_on_end_attack)
	_on_blocking_action_end()

func _on_end_move(movable: Movable):
	movable.end_move.disconnect(_on_end_move)
	_on_blocking_action_end()

func move_movable(coords: Vector2i, movable: Movable):
	if coords in occupants:
		for occupant in occupants[coords]:
			if occupant is Structure:
				var structure := occupant as Structure
				if structure.player_owner_id != movable.player_owner_id:
					attack_structure(movable, structure)
					return
			elif occupant is Movable:
				var other_movable := occupant as Movable
				if other_movable.player_owner_id != movable.player_owner_id:
					attack_movable(movable, other_movable)
					return
	
	_on_blocking_action_start()
	occupants[movable.map_position].erase(movable)
	if coords not in occupants:
		occupants[coords] = []
	occupants[coords].append(movable)
	movable.move_to(coords)
	if movable.movable_definition.walks and get_tile_resource(coords).swimmable:
		movable.movable_definition = movables_definitions[1]
	elif movable.movable_definition.swims and get_tile_resource(coords).walkable:
		movable.movable_definition = movables_definitions[0]
	movable.end_move.connect(_on_end_move)

func select_movable(movable: Movable, coords: Vector2i):
	selected_movable = movable
	var walkable_tiles = movable.get_movable_tiles()
	for tile in walkable_tiles:
		if tile == coords:
			continue
		var color: Color = Color.WHITE
		if tile in occupants:
			for occupant in occupants[tile]:
				if occupant is Structure:
					var structure := occupant as Structure
					if structure.player_owner_id != movable.player_owner_id:
						color = Color.RED
				elif occupant is Movable:
					var other_movable := occupant as Movable
					if other_movable.player_owner_id != movable.player_owner_id:
						color = Color.RED
		highlight_cell(tile, color)

func tile_contains_movable(coords: Vector2i) -> Movable:
	if not coords in occupants:
		return null
	for occupant in occupants[coords]:
		if occupant is Movable:
			return occupant
	return null

func tile_contains_structure(coords: Vector2i) -> Structure:
	if not coords in occupants:
		return null
	for occupant in occupants[coords]:
		if occupant is Structure:
			return occupant
	return null

func _on_blocking_action_start():
	hide_hover_tile()
	block = true

func hide_hover_tile():
	drop_carried_occupants()
	if tile_hovered:
		draw_tile(hover_tile.hex_coords)
	tile_hovered = false
	hover_tile.set_atlas_position(Vector2i.ZERO, 0)
	hover_tile.hex_coords = HEX_COORDS_INF

func _on_blocking_action_end():
	block = false

func get_existing_borders() -> Array[Vector2i]:
	var existing_borders: Array[Vector2i] = []
	for coords in occupants:
		for occupant in occupants[coords]:
			if occupant is Structure:
				var structure := occupant as Structure
				var border := structure.border
				for tile in border.contents:
					if not tile in existing_borders:
						existing_borders.append(tile)
	
	return existing_borders

func update_border_camera(new_global_position: Vector2, zoom: Vector2):
	border_camera.global_position = new_global_position
	border_camera.zoom = zoom
