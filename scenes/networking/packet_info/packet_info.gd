class_name PacketInfo

enum PACKET_TYPE {
	ID_ASSIGNMENT = 0,
	TERRAIN_INFO = 10,
	GAME_MESSAGE = 20,
	PLAYER_INFO = 30,
	BORDER_INFO = 40,
	TILE_SELECTED_INFO = 50,
	STRUCTURE_INFO = 60,
}

var packet_type: PACKET_TYPE
var flag: int

func encode() -> PackedByteArray:
	var data: PackedByteArray
	data.resize(1)
	data.encode_u8(0, packet_type)
	return data

func decode(data: PackedByteArray) -> void:
	packet_type = data.decode_u8(0) as PACKET_TYPE

func send(target: ENetPacketPeer) -> void:
	target.send(0, encode(), flag)

func broadcast(server: ENetConnection) -> void:
	server.broadcast(0, encode(), flag)
