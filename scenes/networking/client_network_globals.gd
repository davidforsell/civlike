extends Node

signal handle_local_id_assignment(local_id: int)
signal handle_remote_id_assignment(local_id: int)
signal handle_terrain_info(terrain_info: TerrainInfo)
signal handle_game_message(game_message: GameMessage)
signal handle_player_info(player_info: PlayerInfo)
signal handle_border_info(border_info: BorderInfo)
signal handle_structure_info(structure_info: StructureInfo)


var id: int = -1
var remote_ids: Array[int]

func _ready() -> void:
	NetworkHandler.on_client_packet.connect(on_client_packet)

func on_client_packet(data: PackedByteArray) -> void:
	var packet_type: int = data.decode_u8(0)
	
	match packet_type:
		PacketInfo.PACKET_TYPE.TERRAIN_INFO:
			handle_terrain_info.emit(TerrainInfo.create_from_data(data))
		PacketInfo.PACKET_TYPE.ID_ASSIGNMENT:
			manage_ids(IdAssignment.create_from_data(data))
		PacketInfo.PACKET_TYPE.GAME_MESSAGE:
			handle_game_message.emit(GameMessage.create_from_data(data))
		PacketInfo.PACKET_TYPE.PLAYER_INFO:
			handle_player_info.emit(PlayerInfo.create_from_data(data))
		PacketInfo.PACKET_TYPE.BORDER_INFO:
			handle_border_info.emit(BorderInfo.create_from_data(data))
		PacketInfo.PACKET_TYPE.STRUCTURE_INFO:
			handle_structure_info.emit(StructureInfo.create_from_data(data))
		_:
			push_error("Packet type with index ", data[0], " unhandled!")

func manage_ids(id_assignment: IdAssignment) -> void:
	if id == -1:
		id = id_assignment.id
		handle_local_id_assignment.emit(id_assignment.id)
		
		remote_ids = id_assignment.remote_ids
		for remote_id in id_assignment.remote_ids:
			if remote_id == id: continue
			handle_remote_id_assignment.emit(remote_id)
	
	else:
		remote_ids.append(id_assignment.id)
		handle_remote_id_assignment.emit(id_assignment.id)
