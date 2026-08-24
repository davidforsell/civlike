extends Node

signal handle_player_info(peer_id: int, player_info: PlayerInfo)
signal handle_game_message(peer_id: int, message: GameMessage)
signal handle_tile_selected_info(peer_id: int, tile_selected_info: TileSelectedInfo)

var peer_ids: Array[int]

func _ready() -> void:
	NetworkHandler.on_peer_connected.connect(_on_peer_connected)
	NetworkHandler.on_peer_disconnected.connect(_on_peer_disconnected)
	NetworkHandler.on_server_packet.connect(_on_server_packet)


func _on_peer_connected(peer_id: int) -> void:
	peer_ids.append(peer_id)
	
	IdAssignment.create(peer_id, peer_ids).broadcast(NetworkHandler.connection)

func _on_peer_disconnected(peer_id: int) -> void:
	peer_ids.erase(peer_id)
	
	# Create IDUnassignment to broadcast to all still connected peers

func _on_server_packet(peer_id: int, data: PackedByteArray) -> void:
	var packet_type: int = data.decode_u8(0)
	match packet_type:
		PacketInfo.PACKET_TYPE.GAME_MESSAGE:
			handle_game_message.emit(peer_id, GameMessage.create_from_data(data))
		PacketInfo.PACKET_TYPE.PLAYER_INFO:
			handle_player_info.emit(peer_id, PlayerInfo.create_from_data(data))
		PacketInfo.PACKET_TYPE.TILE_SELECTED_INFO:
			handle_tile_selected_info.emit(peer_id, TileSelectedInfo.create_from_data(data))
		_:
			push_error("Packet type with index ", data[0], " unhandled!")
