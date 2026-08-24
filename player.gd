class_name Player
extends Node

enum Phase { WAIT, SPAWN, MOVE }

signal hex_selected(hex_coords: Vector2i, player_data: PlayerData)

var data: PlayerData
var phase: Phase = Phase.WAIT
var hex_map: HexMap
var hex_borders: HexBorders
var camera: MapCamera

var target_player_id: int

func _enter_tree() -> void:
	ClientNetworkGlobals.handle_game_message.connect(_on_client_game_message)
	ClientNetworkGlobals.handle_border_info.connect(_on_client_border_info)

func _init(player_data):
	data = player_data

func _on_client_game_message(message: GameMessage):
	if NetworkHandler.is_server: return
	match message.message:
		GameMessage.MESSAGE.START_TURN:
			_on_client_turn_start()
		GameMessage.MESSAGE.END_TURN:
			_on_client_turn_end()

func _on_client_border_info(info: BorderInfo):
	if NetworkHandler.is_server: return
	match info.type:
		BorderInfo.TYPE.SPAWN_BORDER:
			data.spawn_border = SpawnBorder.create_from_array(info.coordinates)

func _on_client_turn_start():
	print("Client ", str(ClientNetworkGlobals.id), ": Turn started")
	if data.owned_structures == []:
		# Start of game since own no structures (or dead...)
		phase = Phase.SPAWN
		client_pick_spawn()

func _on_client_turn_end():
	pass

func client_pick_spawn():
	if !data.spawn_border:
		print("Client ", str(ClientNetworkGlobals.id), ": Awaiting spawn border")
		await data.spawn_border_ready
	camera.global_position = hex_map.tile_to_world(data.spawn_border.centre)
	camera.zoom = Vector2i.ONE * 0.35
	hex_borders.draw_border(data.spawn_border)
	camera.block_input = true

func _unhandled_input(event: InputEvent) -> void:
	if NetworkHandler.is_server: return
	if data.is_bot: return
	if event.is_action_pressed("select"):
		hex_selected.emit(hex_map.get_mouse_coords(), data)

func _on_server_turn_start():
	reset_movable_stamina()
	
	if data.owned_structures == []:
		phase = Phase.SPAWN
		if data.is_bot:
			_bot_pick_spawn()
			target_player_id = GameState.player_ids.pick_random()
			while target_player_id == data.id:
				target_player_id = GameState.player_ids.pick_random()
	else:
		phase = Phase.MOVE
		if data.is_bot:
			_bot_move()

func reset_movable_stamina():
	for movable in data.owned_armies:
		movable.stamina = movable.max_stamina

func _on_turn_end():
	phase = Phase.WAIT

func _bot_pick_spawn():
	for hex in data.spawn_border.contents:
		if phase == Phase.WAIT:
			return
		#hex_selected.emit(data, hex)
		#name_picked.emit(data.id, TownNameGenerator.generate_name(5, 10))


func _bot_move():
	var timer := Timer.new()
	add_child(timer)
	
	# Train troops:
	for structure in data.owned_structures:
		data.selected_structure = structure
		for i in range(3):
			if structure.money <= 0 or structure.population <= 0:
				break
			var hex: Vector2i
			var hex_found := false
			
			var dirs = hex_map.DIRECTIONS.duplicate()
			dirs.shuffle()
			
			for dir in dirs:
				hex = structure.map_position + dir
				if hex_map.get_tile_resource(hex).walkable:
					hex_found = true
					break
			if not hex_found:
				hex = structure.map_position
			train_unit(UnitDefinition.UnitType.SWORDSMAN, hex)
			timer.start(0.5)
			await timer.timeout
	
	for army in data.owned_armies:
		data.selected_movable = army
		var target_structure := GameState.player_datas[target_player_id].owned_structures[0]
		var movable_on_structure := hex_map.tile_contains_movable(target_structure.map_position)
		if movable_on_structure and movable_on_structure.player_owner_id == data.id:
			break
		var path := army.get_direct_hex_path(data.id, army.map_position, target_structure.map_position)
		while army.stamina > 0:
			var index = path.find(army.map_position) + 1
			if index >= len(path):
				break
			var target_tile := path[index]
			if hex_map.get_tile_resource(target_tile).walkable and hex_map.get_tile_resource(army.map_position).swimmable and (hex_map.tile_contains_movable(target_tile) or hex_map.tile_contains_structure(target_tile)):
				target_tile = find_nearest_land(target_tile)
				path = army.get_direct_hex_path(data.id, army.map_position, target_tile, true)
				index = path.find(army.map_position) + 1
				target_tile = path[index]
			var structure := hex_map.tile_contains_structure(target_tile)
			var attacking: bool = hex_map.tile_contains_movable(target_tile) or (structure and structure.player_owner_id != data.id)
			
			hex_map.move_movable(target_tile, army)
			if attacking:
				await army.end_attack
			else:
				await army.end_move
	
	timer.queue_free()
	#end_turn.emit(data.id)

func find_nearest_land(coords: Vector2i):
	var land_tile := coords
	var radius := 1
	while (not hex_map.get_tile_resource(land_tile).walkable) or hex_map.tile_contains_structure(land_tile) or hex_map.tile_contains_movable(land_tile):
		var ring := hex_map.get_hex_ring(coords, radius)
		for hex in ring:
			land_tile = hex
			if hex_map.get_tile_resource(land_tile).walkable and (not hex_map.tile_contains_movable(land_tile)) and (not hex_map.tile_contains_structure(land_tile)):
				return land_tile
		radius += 1


func train_unit(type: UnitDefinition.UnitType, coords: Vector2i):
	data.selected_unit = type
	#train_troop.emit(data, coords)
