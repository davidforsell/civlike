class_name GameMessage extends PacketInfo

enum MESSAGE {
	INVALID,
	START_GAME,
	START_TURN,
	END_TURN,
	CLIENT_READY,
}

var message: MESSAGE

@warning_ignore("shadowed_variable")
static func create(message: MESSAGE) -> GameMessage:
	var info := GameMessage.new()
	info.packet_type = PacketInfo.PACKET_TYPE.GAME_MESSAGE
	info.flag = ENetPacketPeer.FLAG_RELIABLE
	info.message = message
	return info

static func create_from_data(data: PackedByteArray) -> GameMessage:
	var info := GameMessage.new()
	info.decode(data)
	return info

func encode() -> PackedByteArray:
	var data := super.encode()
	data.resize(3)
	data.encode_u8(1, message)
	return data

func decode(data: PackedByteArray) -> void:
	super.decode(data)
	message = data.decode_u8(1) as MESSAGE
