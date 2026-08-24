class_name Movable
extends Occupant

signal died(movable: Movable)

@onready var stamina_scene = preload("res://scenes/movables/stamina_bar.tscn")

var map: HexMap
var movable_definition: MovableDefinition: 
	set(new):
		movable_definition = new
		if not sprite_2d:
			await ready
		sprite_2d.texture = movable_definition.texture
		if flag:
			flag.queue_free()
		if banner and movable_definition.swims:
			load_flags_and_banners()
			banner.fall_animation()
			await banner.finished
			banner.queue_free()
			return
		elif banner:
			banner.queue_free()
		load_flags_and_banners()

var units: Array[Unit] = []
var player_owner_id: int

var banner_scene = preload("res://scenes/ui/banner.tscn")
var banner: Banner
var banner_offset: Vector2 = Vector2(5, -6)

var stamina_bar: StaminaBar

var flag_scene = preload("res://scenes/ui/flag.tscn")
var flag: Node2D

var moving: bool = false

var stamina := 0:
	set(value):
		stamina = clamp(value, 0, max_stamina)
		if stamina_bar:
			stamina_bar.set_stamina_percentage(float(stamina) / float(max_stamina))
var max_stamina := 0

var total_damage: int:
	get():
		var total := 0
		for unit in units:
			total += unit.damage
		return total

var sprite_2d: Sprite2D
signal end_move(movable: Movable)
signal end_attack(movable: Movable)


func _init(game_map: HexMap, definition: MovableDefinition, p_owner_id: int):
	map = game_map
	movable_definition = definition
	player_owner_id = p_owner_id

func _ready():
	z_index = 3
	y_sort_enabled = true
	sprite_2d = Sprite2D.new()
	add_child(sprite_2d)
	load_flags_and_banners()
	stamina_bar = stamina_scene.instantiate()
	add_child(stamina_bar)
	stamina_bar.position = Vector2(-8.5, -1.0)

func load_flags_and_banners():
	if movable_definition.walks:
		banner = banner_scene.instantiate()
		add_child(banner)
		banner.position += banner_offset
		banner.modulate = GameState.player_datas[player_owner_id].color
		if not map.tile_contains_structure(map_position) and not moving:
			banner.raise_animation()
	elif movable_definition.swims:
		flag = flag_scene.instantiate()
		add_child(flag)
		flag.modulate = GameState.player_datas[player_owner_id].color

func set_coords(coords: Vector2i):
	map_position = coords

func get_movable_tiles() -> Array[Vector2i]:
	if movable_definition.walks:
		return get_walkable_tiles()
	elif movable_definition.swims:
		return get_swimmable_tiles()
	return []

func add_unit(unit: Unit):
	units.append(unit)
	max_stamina += unit.definition.base_stamina
	stamina += unit.definition.base_stamina

func get_swimmable_tiles() -> Array[Vector2i]:
	var start := map_position
	var start_tile := map.get_tile_resource(start)
	
	var used_stamina := 0

	if not start_tile.swimmable:
		return []

	var visited: Dictionary = {start: null}
	var fringes: Array = [[start]]

	for k in range(1, movable_definition.movement_range + 1):
		used_stamina += 1
		if used_stamina > stamina:
			break
		fringes.append([])

		for hex in fringes[k - 1]:
			for dir in map.DIRECTIONS:
				var neighbour = hex + dir
				if neighbour in visited:
					continue
				var neighbour_tile := map.get_tile_resource(neighbour)
				if not neighbour_tile.swimmable:
					continue
				var movable := map.tile_contains_movable(neighbour)
				if movable:
					# Friendly unit: can't move onto or through it.
					if movable.player_owner_id == player_owner_id:
						continue

					# Enemy unit: can move onto it, but can't move through it.
					visited[neighbour] = null
					continue

				# Empty tile: can move onto it AND continue through it.
				visited[neighbour] = null
				fringes[k].append(neighbour)

	# Add adjacent land tiles for disembarkation
	for dir in map.DIRECTIONS:
		if stamina <= 0:
			break
		var neighbour := start + dir
		if neighbour in visited:
			continue
		var neighbour_tile := map.get_tile_resource(neighbour)
		var movable := map.tile_contains_movable(neighbour)
		var structure := map.tile_contains_structure(neighbour)
		var blocking_movable: bool = movable != null
		var blocking_structure: bool = structure and not structure.player_owner_id == TurnManager.get_current_player_id()
		
		if neighbour_tile.walkable and not blocking_movable and not blocking_structure:
			visited[neighbour] = null

	return visited.keys()

func get_walkable_tiles() -> Array[Vector2i]:
	var start := map_position
	var start_tile := map.get_tile_resource(start)
	var used_stamina := 0
	
	if not start_tile.walkable:
		return []

	var visited: Dictionary = {start: null}
	var fringes: Array = [[start]]

	for k in range(1, movable_definition.movement_range + 1):
		used_stamina += 1
		if used_stamina > stamina:
			break
		fringes.append([])
		for hex in fringes[k - 1]:
			for dir in map.DIRECTIONS:
				var neighbour = hex + dir
				if neighbour in visited:
					continue
				var neighbour_tile := map.get_tile_resource(neighbour)
				if not neighbour_tile.walkable:
					continue
				var movable := map.tile_contains_movable(neighbour)
				var structure := map.tile_contains_structure(neighbour)
				if movable:
					# Friendly unit: can't move onto or through it.
					if movable.player_owner_id == player_owner_id:
						continue
					# Enemy unit: can move onto it, but can't move through it.

					visited[neighbour] = null
					continue
				if structure:
					if structure.player_owner_id != player_owner_id:
						visited[neighbour] = null
						continue
				# Empty tile: can move onto it AND continue through it.
				visited[neighbour] = null
				fringes[k].append(neighbour)
	# Add adjacent water tiles for disembarkation
	for dir in map.DIRECTIONS:
		if stamina <= 0:
			break
		var neighbour := start + dir
		if neighbour in visited:
			continue
		var neighbour_tile := map.get_tile_resource(neighbour)
		var movable := map.tile_contains_movable(neighbour)
		var structure := map.tile_contains_structure(neighbour)
		var blocking_movable: bool = movable != null
		var blocking_structure: bool = structure and not structure.player_owner_id == TurnManager.get_current_player_id()
		
		if neighbour_tile.swimmable and not blocking_movable and not blocking_structure:
			visited[neighbour] = null
	return visited.keys()

func can_move_to(end: Vector2i) -> bool:
	var movable_tiles := get_movable_tiles() as Array
	if end in movable_tiles and end != map_position:
			return true
	return false

func get_hex_path(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	if movable_definition.walks:
		return get_walkable_hex_path(start, end)
	elif movable_definition.swims:
		return get_swimmable_hex_path(start, end)
	return []

func get_direct_hex_path(id: int, start: Vector2i, end: Vector2i, avoid_structures: bool = false, avoid_movables: bool = false) -> Array[Vector2i]:
	var came_from := {start: null}
	var queue: Array[Vector2i] = [start]
	var current: Vector2i
	
	while not queue.is_empty():
		current = queue.pop_front()
		if current == end:
			break
		for dir in map.DIRECTIONS:
			var neighbour := current + dir
			if neighbour in came_from:
				continue
			var tile := map.get_tile_resource(neighbour)
			var movable := map.tile_contains_movable(neighbour)
			var structure := map.tile_contains_structure(neighbour)
			
			
			var blocking_movable: bool = movable != null and (movable.player_owner_id == id or map.get_tile_resource(movable.map_position).swimmable)
			if avoid_movables:
				blocking_movable = blocking_movable or movable != null
			var blocking_structure: bool = avoid_structures and structure
			
			
			if (tile.swimmable or tile.walkable) and not blocking_movable and not blocking_structure:
				came_from[neighbour] = current
				queue.append(neighbour)
			
	if end not in came_from:
		return []
	
	var path: Array[Vector2i] = []
	current = end
	while came_from[current] != null:
		path.push_front(current)
		current = came_from[current]
	path.push_front(start)
	return path

func get_swimmable_hex_path(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	var came_from := {start: null}
	var queue: Array[Vector2i] = [start]
	var current: Vector2i
	
	while not queue.is_empty():
		current = queue.pop_front()
		if current == end:
			break
		for dir in map.DIRECTIONS:
			var neighbour := current + dir
			if neighbour in came_from:
				continue
			var tile := map.get_tile_resource(neighbour)
			
			var movable := map.tile_contains_movable(neighbour)
			var structure := map.tile_contains_structure(neighbour)
			var blocking_movable: bool = movable != null
			var blocking_structure: bool = structure and not structure.player_owner_id == TurnManager.get_current_player_id()
			
			if tile.swimmable and not blocking_movable and not blocking_structure:
				came_from[neighbour] = current
				queue.append(neighbour)
			
			# Embark directly from the starting tile
			elif tile.walkable and current == start and neighbour == end and not blocking_structure:
				came_from[neighbour] = current
				queue.append(neighbour)
				
			elif neighbour == end and tile.swimmable:
				came_from[neighbour] = current
				queue.append(neighbour)
			
	if end not in came_from:
		return []
	
	var path: Array[Vector2i] = []
	current = end
	while came_from[current] != null:
		path.push_front(current)
		current = came_from[current]
	path.push_front(start)
	return path

func _on_end_turn():
	pass

func get_walkable_hex_path(start: Vector2i, end: Vector2i) -> Array[Vector2i]:
	var came_from := {start: null}
	var queue: Array[Vector2i] = [start]
	var current: Vector2i
	
	while not queue.is_empty():
		current = queue.pop_front()
		if current == end:
			break
		for dir in map.DIRECTIONS:
			var neighbour := current + dir
			if neighbour in came_from:
				continue
			var tile := map.get_tile_resource(neighbour)
			var movable := map.tile_contains_movable(neighbour)
			var structure := map.tile_contains_structure(neighbour)
			var blocking_movable: bool = movable != null
			var blocking_structure: bool = structure and not structure.player_owner_id == TurnManager.get_current_player_id()
			
			if tile.walkable and not blocking_movable and not blocking_structure:
				came_from[neighbour] = current
				queue.append(neighbour)
			
			# Embark directly from the starting tile
			elif tile.swimmable and current == start and neighbour == end and not blocking_structure and not blocking_structure:
				came_from[neighbour] = current
				queue.append(neighbour)
			
			elif neighbour == end and tile.walkable:
				came_from[neighbour] = current
				queue.append(neighbour)
			
	if end not in came_from:
		return []
	
	var path: Array[Vector2i] = []
	current = end
	while came_from[current] != null:
		path.push_front(current)
		current = came_from[current]
	
	path.push_front(start)
	return path

func move_to(coords: Vector2i, leave_banner: bool = false):
	moving = true
	var path = get_hex_path(map_position, coords)
	stamina -= len(path) - 1
	if movable_definition.walks:
		banner.reparent(get_parent())
		banner.z_index = z_index
		if not leave_banner:
			banner.fall_animation(0.25)
	
	for hexes in path.slice(1):
		var target_position = map.tile_to_world(hexes)

		var tween := create_tween()
		tween.tween_property(
			self,
			"global_position",
			target_position,
			0.3
		)

		await tween.finished
	
	map_position = coords
	
	var structure := map.tile_contains_structure(coords)
	if movable_definition.walks and not structure:
		banner.reparent(self)
		banner.z_index = 0
		if not leave_banner:
			banner.position = banner_offset
			banner.raise_animation(0.2)

	end_move.emit(self)
	moving = false

func attack(occupant: Occupant):
	if occupant is Structure:
		attack_structure(occupant)
	elif occupant is Movable:
		attack_movable(occupant)

func attack_structure(structure: Structure):
	var path := get_walkable_hex_path(map_position, structure.map_position)
	if path[len(path) - 2] == map_position:
		move_to(structure.map_position, true)
	else:
		move_to(path[len(path) - 2])
		await end_move
		move_to(structure.map_position, true)
	await end_move
	structure.take_damage(self)
	if structure.player_owner_id != player_owner_id:
		banner.reparent(self)
		banner.z_index = 0
		move_to(path[len(path) - 2], true)
		await end_move
	else:
		banner.fall_animation()
		await banner.finished
		banner.reparent(self)
		banner.position = banner_offset
		banner.z_index = 0
	end_attack.emit(self)

func take_damage(movable: Movable) -> bool:
	var target_unit: Unit = units.pick_random()
	
	var dmg = movable.total_damage - target_unit.defense
	target_unit.hp = clampi(target_unit.hp - dmg, 0, target_unit.definition.base_hp)
	DamageNumbers.show_damage(self, dmg)
	if target_unit.hp <= 0:
		max_stamina -= target_unit.definition.base_stamina
		stamina = clampi(stamina, 0, max_stamina)
		units.erase(target_unit)
		if len(units) <= 0:
			died.emit(self)
			banner.reparent(get_parent())
			banner.fall_animation(0.5, true)
			return true
	return false

func attack_movable(movable: Movable):
	var path := get_walkable_hex_path(map_position, movable.map_position)
	if path[len(path) - 2] == map_position:
		move_to(movable.map_position, true)
	else:
		move_to(path[len(path) - 2])
		await end_move
		move_to(movable.map_position, true)
	await end_move
	var just_died: bool = movable.take_damage(self)
	if !just_died:
		move_to(path[len(path) - 2], true)
		await end_move
	else:
		banner.fall_animation()
		await banner.finished
		banner.reparent(self)
		banner.z_index = 0
		banner.position = banner_offset
		banner.raise_animation()
	end_attack.emit(self)
