class_name Bot extends Player

func start_turn():
	print("Bot ", str(data.id), ": Turn started")
	if data.owned_structures == []:
		pick_spawn()

func pick_spawn():
	var timer := Timer.new()
	add_child(timer)
	timer.start(0.5)
	await timer.timeout
	timer.queue_free()
	var hex = data.spawn_border.contents.keys().pick_random()
	while !hex_map.get_tile_resource(hex).walkable:
		hex = data.spawn_border.contents.keys().pick_random()
	print("Bot ", str(data.id), ": Spawn hex selected successfully")
	hex_selected.emit(hex, data)

func end_turn():
	pass

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
			#train_unit(UnitDefinition.UnitType.SWORDSMAN, hex)
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
