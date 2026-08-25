extends Node

var player_datas: Dictionary[int, PlayerData] = {}
var players: Dictionary[int, Player] = {}
var player_ids: Array[int] = []

var structures: Dictionary[int, Structure]

var hex_map: HexMap

var current_player_index := 0
var round_number := 1

signal player_died(id: int)
signal structure_added

func server_set_spawn_border(id: int, border: SpawnBorder):
	if !NetworkHandler.is_server: return
	player_datas[id].spawn_border = border
	if !player_datas[id].is_bot:
		BorderInfo.create(BorderInfo.TYPE.SPAWN_BORDER, border.contents.keys()).send(NetworkHandler.client_peers[id])

func get_spawn_border(id: int) -> SpawnBorder:
	return player_datas[id].spawn_border

func add_player(player_data: PlayerData) -> Player:
	var player: Player
	if !player_data.is_bot:
		player = Player.new(player_data)
	else:
		player = Bot.new(player_data)
	var id := player_data.id
	player_ids.append(id)
	player_datas[id] = player_data
	players[id] = player
	return player

func add_structure(structure: Structure):
	structures[structure.id] = structure
	player_datas[structure.player_owner_id].owned_structures.append(structure)
	structure_added.emit()

func get_current_player_id() -> int:
	var id := player_ids[current_player_index]
	return id

func advance_player() -> void:
	current_player_index += 1

	if current_player_index >= player_ids.size():
		current_player_index = 0
		round_number += 1

func on_player_death(id: int):
	players[id].queue_free()
	for movable in player_datas[id].owned_armies:
		hex_map.remove_occupant(movable)
		movable.queue_free()


	players.erase(id)
	player_datas.erase(id)
	if player_ids.find(id) < current_player_index:
		current_player_index -= 1
	player_ids.erase(id)
	
	player_died.emit(id)


func switch_structure_ownership(structure: Structure, new_id: int):
	var old_id := structure.player_owner_id
	structure.player_owner_id = new_id
	structure.color = player_datas[new_id].color
	player_datas[old_id].owned_structures.erase(structure)
	player_datas[new_id].owned_structures.append(structure)
	
	if len(player_datas[old_id].owned_structures) == 0:
		on_player_death(old_id)
