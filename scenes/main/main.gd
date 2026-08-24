extends Node2D

@onready var map: HexMap = $HexMap
@onready var hex_borders: HexBorders = $HexBorders
@onready var camera: MapCamera = $Camera2D
@onready var pick_color_view = $CanvasLayer/PickColor

@onready var info_label = $CanvasLayer/InfoLabel
@onready var follow_cursor = $FollowCursor

@onready var structure_buttons = $CanvasLayer/StructureButtons
@onready var army_buttons = $CanvasLayer/ArmyButtons

@onready var name_generator = $TownNameGenerator

@onready var fog: ColorRect = $Fog

@onready var enter_structure_name = $CanvasLayer/EnterStructureName
@onready var end_turn_button = $CanvasLayer/EndTurnButton
@onready var bot_turn_panel = $CanvasLayer/BotTurnPanel

@export var structure_definitions: Array[StructureDefinition] = []
@export var rings: int = 30

@export var unit_definitions: Dictionary[UnitDefinition.UnitType, UnitDefinition] = {}

var rng = RandomNumberGenerator.new()
var ready_clients: Array[int]

signal all_clients_ready
signal colour_selected

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("select"):
		map.on_select_pressed()

func _enter_tree() -> void:
	if NetworkHandler.is_server:
		ServerNetworkGlobals.handle_game_message.connect(_on_server_game_message)
		ServerNetworkGlobals.handle_tile_selected_info.connect(_on_server_tile_selected_info)
	else:
		ClientNetworkGlobals.handle_structure_info.connect(_on_client_structure_info)

func _ready():
	if NetworkHandler.is_server:
		start_game_server()
	else:
		client_create_player()
		GameMessage.create(GameMessage.MESSAGE.CLIENT_READY).send(NetworkHandler.server_peer)
		if not map.map_is_ready:
			print("Client ", str(ClientNetworkGlobals.id), " awaiting map ready")
			await map.map_ready
		print("Client ", str(ClientNetworkGlobals.id), " map ready, starting game")
		client_start_game()

func _on_server_game_message(peer_id: int, message: GameMessage):
	match message.message:
		GameMessage.MESSAGE.CLIENT_READY:
			if peer_id not in ready_clients:
				ready_clients.append(peer_id)
				if check_all_clients_ready():
					all_clients_ready.emit()

func check_all_clients_ready() -> bool:
	if !NetworkHandler.is_server: return false
	for id in ServerNetworkGlobals.peer_ids:
		if !id in ready_clients:
			return false
	return true

func client_create_player():
	var player_data := PlayerData.new(ClientNetworkGlobals.id)
	var player := GameState.add_player(player_data)
	player.camera = camera
	player.hex_map = map
	player.hex_borders = hex_borders
	player.hex_selected.connect(_on_client_hex_selected)
	add_child(player)

func client_start_game():
	map.draw_map()

func start_game_server():
	const PLAYER_COUNT = 4
	
	if !check_all_clients_ready():
		await all_clients_ready
	
	var players_created := 0
	for id in ServerNetworkGlobals.peer_ids:
		var player_data := PlayerData.new(id)
		var player := GameState.add_player(player_data)
		players_created += 1
		add_child(player)
	
	for i in range(players_created, PLAYER_COUNT):
		var bot_data := PlayerData.new(NetworkHandler.available_peer_ids.pop_back())
		bot_data.is_bot = true
		var bot := GameState.add_player(bot_data)
		bot.hex_map = map
		add_child(bot)
	
	GameState.hex_map = map
	map.create_hexagon_map(rings)
	create_spawn_borders(PLAYER_COUNT)
	
	TurnManager.server_start_turn()

func pick_colour():
	pick_color_view.visible = true

func add_ring(border: Border, radius: int, centre: Vector2i):
	for hex in map.get_hex_ring(centre, radius):
		border.add_hex(hex)

func prepare_camera():
	camera.global_position = map.tile_to_world(Vector2i.ZERO)
	camera.zoom = Vector2i.ONE * 0.35
	
	camera.block_input = true

func pixel_to_axial(pos: Vector2) -> Vector2i:
	var q = (sqrt(3.0) / 3.0 * pos.x - 1.0 / 3.0 * pos.y)
	var r = (2.0 / 3.0 * pos.y)

	return axial_round(q, r)

func axial_round(q: float, r: float) -> Vector2i:
	var x = q
	var z = r
	var y = -x - z

	var rx = round(x)
	var ry = round(y)
	var rz = round(z)

	var x_diff = abs(rx - x)
	var y_diff = abs(ry - y)
	var z_diff = abs(rz - z)

	if x_diff > y_diff and x_diff > z_diff:
		rx = -ry - rz
	elif y_diff > z_diff:
		ry = -rx - rz
	else:
		rz = -rx - ry

	return Vector2i(rx, rz)


func create_spawn_borders(amount: int, distance: int = 20):
	for i in range(amount):
		var angle = TAU * float(i) / amount

		var centre = Vector2(
			cos(angle) * distance,
			sin(angle) * distance
		)

		var id = GameState.player_ids[i]

		GameState.server_set_spawn_border(id, create_spawn_border(pixel_to_axial(centre), 6))

func find_best_spawn_position(start: Vector2i, max_radius: int) -> Vector2i:
	for radius in range(max_radius + 1):
		for coords in map.get_hex_ring(start, radius):
			if map.get_tile_resource(coords).walkable:
				return coords

	return start

func create_spawn_border(centre: Vector2i, radius: int) -> SpawnBorder:
	var new_centre: Vector2i
	new_centre = find_best_spawn_position(centre, 10)
	
	var border: SpawnBorder = SpawnBorder.new()
	border.color = Color.RED
	border.add_hex(new_centre)
	border.centre = new_centre
	for i in range(1, radius):
		add_ring(border, i, new_centre)
	return border

func _on_client_hex_selected(coords: Vector2i, player_data: PlayerData):
	if NetworkHandler.is_server: return
	if player_data.is_bot: return
	if player_data.owned_structures == []:
		_on_client_hex_spawn_selected(coords, player_data)

func _on_client_hex_spawn_selected(coords: Vector2i, player_data: PlayerData):
	if !coords in player_data.spawn_border.contents: return # invalid spawn
	if !map.get_tile_resource(coords).walkable: return
	TileSelectedInfo.create(TileSelectedInfo.TYPE.SPAWN_TILE, coords).send(NetworkHandler.server_peer)

func _on_server_tile_selected_info(peer_id: int, tile_selected_info: TileSelectedInfo):
	if TurnManager.get_current_player_id() != peer_id: return
	match tile_selected_info.type:
		TileSelectedInfo.TYPE.SPAWN_TILE:
			_on_server_hex_spawn_selected(tile_selected_info.coordinates, GameState.player_datas[peer_id])

func _on_server_hex_spawn_selected(coords: Vector2i, player_data: PlayerData):
	var id := player_data.id
	if TurnManager.get_current_player_id() != id: return
	if !coords in GameState.get_spawn_border(id).contents or !map.get_tile_resource(coords).walkable: return
	
	var spawn_structure = map.add_structure(structure_definitions[0], coords, id, true)
	spawn_structure.color = GameState.player_datas[0].color
	StructureInfo.create(StructureInfo.TYPE.STRUCTURE_CREATED, coords, id, 0).broadcast(NetworkHandler.connection)
	TurnManager.server_end_turn()

func _on_client_structure_info(info: StructureInfo):
	match info.type:
		StructureInfo.TYPE.STRUCTURE_CREATED:
			map.add_structure(structure_definitions[info.structure_resource_id], info.coords, info.owner_id)

#func _on_hex_spawn_selected(player_data: PlayerData, coords: Vector2i):
	#var id := player_data.id
	#if TurnManager.get_current_player_id() != id:
		#return
	#if not coords in GameState.get_spawn_border(id).contents or not map.get_tile_resource(coords).walkable:
		#return
		#
	#var spawn_structure = map.add_structure(structure_definitions[0], coords, id, true)
	#spawn_structure.color = GameState.player_datas[id].color
	#camera.block_input = false
	#hex_borders.update_borders()
	#
	#GameState.player_datas[id].selected_structure = spawn_structure
	#GameState.player_datas[id].owned_structures.append(spawn_structure)
	#if not GameState.player_datas[id].is_bot:
		#enter_structure_name.visible = true
	#
	#info_label.visible = false
	#structure_buttons.set_owner_buttons_visible()
	#
	#spawn_structure.select()
	#
	#spawn_picked.emit()
	#TurnManager.end_turn()

#func _on_hex_selected(player_data: PlayerData, coords: Vector2i):
	#var id := player_data.id
	#if TurnManager.get_current_player_id() != id:
		#return
	#if player_data.owned_structures == []:
		#_on_hex_spawn_selected(player_data, coords)
		#return
	
	#var set_structure_info_visible: bool = false
	#var set_army_info_visible: bool = false
	#
	#if coords in map.occupants:
		#for occupant in map.occupants[coords]:
			#if occupant is Structure and occupant:
				#if occupant.player_owner_id == id:
					#structure_buttons.set_owner_buttons_visible()
				#else:
					#structure_buttons.set_non_owner_buttons_visible()
				#set_structure_info_visible = true
				#GameState.player_datas[id].selected_structure = occupant
			#elif occupant is Movable:
				#army_buttons.visible = true
				#set_army_info_visible = true
				#GameState.player_datas[id].selected_movable = occupant
	#
	#if not set_structure_info_visible:
		#structure_buttons.hide_buttons()
	#if not set_army_info_visible:
		#army_buttons.visible = false

func _on_pick_color_color_picked(color: Color) -> void:
	GameState.player_datas[1].color = color
	pick_color_view.visible = false
	colour_selected.emit()

func _on_name_picked(id: int, name: String) -> void:
	var player_data := GameState.player_datas[id]
	var structure := player_data.selected_structure
	if not structure:
		return
	if not player_data.is_bot:
		end_turn_button.visible = true
	structure.structure_name = name

func _on_panel_enter():
	map.block = true
	camera.block_input = true

func _on_panel_exit():
	map.block = false
	camera.block_input = false

func _structure_upgade_pressed() -> void:
	var id := TurnManager.get_current_player_id()
	GameState.player_datas[id].selected_structure.upgrade_structure()

func _on_change_name_button_pressed() -> void:
	enter_structure_name.visible = true

func _on_place_troop(data: PlayerData, coords: Vector2i):
	var id := data.id
	var selected_structure = GameState.player_datas[id].selected_structure
	var valid_troop_positions = get_valid_troop_positions(selected_structure)
	
	if not coords in valid_troop_positions:
		map.highlight_cells(valid_troop_positions)
		return
	
	var selected_unit := GameState.player_datas[id].selected_unit
	var unit := unit_definitions[selected_unit]
	selected_structure.money -= unit.base_money_cost
	selected_structure.population -= unit.base_population_cost

	map.add_unit(unit_definitions[selected_unit], coords, id)
	if not data.is_bot:
		follow_cursor.visible = false
		army_buttons.visible = true
		var player := GameState.players[TurnManager.get_current_player_id()]
		player.hex_selected.disconnect(_on_place_troop)

func get_valid_troop_positions(structure: Structure) -> Array[Vector2i]:
	var coords := structure.map_position
	var valid_troop_positions: Array[Vector2i] = [coords]
	for dir in map.DIRECTIONS:
		var movable := map.tile_contains_movable(coords + dir)
		if map.get_tile_resource(coords + dir).walkable and ((not movable) or movable.player_owner_id == TurnManager.get_current_player_id()):
			valid_troop_positions.append(coords + dir)
	return valid_troop_positions

func _on_train_troop_button_pressed(unit_type: UnitDefinition.UnitType) -> void:
	var id := TurnManager.get_current_player_id()
	GameState.player_datas[id].selected_unit = unit_type
	map.clear_highlights()
	hex_borders.update_borders()
	var selected_structure := GameState.player_datas[id].selected_structure
	var unit := unit_definitions[unit_type]
	if selected_structure.money < unit.base_money_cost or selected_structure.population < unit.base_population_cost:
		return
	
	map.highlight_cells(get_valid_troop_positions(selected_structure))
	follow_cursor.visible = true
	var player := GameState.players[TurnManager.get_current_player_id()]
	player.hex_selected.connect(_on_place_troop)

func _on_end_turn_button_pressed():
	_on_end_turn(TurnManager.get_current_player_id())

func _on_end_turn(id: int) -> void:
	if id != TurnManager.get_current_player_id():
		return
	TurnManager.end_turn()
	var new_id = TurnManager.get_current_player_id()
	if GameState.player_datas[new_id].is_bot:
		end_turn_button.visible = false
		bot_turn_panel.visible = true
	else:
		end_turn_button.visible = true
		bot_turn_panel.visible = false
