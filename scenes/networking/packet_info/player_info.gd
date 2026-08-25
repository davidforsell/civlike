class_name PlayerInfo extends PacketInfo

enum TYPE {
	COLOR,
	NAME
}

var type: TYPE
var player_id: int
var player_data: PackedByteArray 

@warning_ignore("shadowed_variable")
static func create(type: TYPE, player_id: int, data: PackedByteArray) -> PlayerInfo:
	var info := PlayerInfo.new()
	info.packet_type = PacketInfo.PACKET_TYPE.PLAYER_INFO
	info.flag = ENetPacketPeer.FLAG_RELIABLE
	info.type = type
	info.player_id = player_id
	info.player_data = data
	return info

static func create_from_color(color: Color, player_id: int) -> PlayerInfo:
	var data := PackedByteArray()
	data.resize(4)
	data.encode_u32(0, color.to_rgba32())
	return create(TYPE.COLOR, player_id, data)

static func create_from_string(player_name: String, player_id: int) -> PlayerInfo:
	return create(TYPE.NAME, player_id, player_name.to_utf8_buffer())

static func create_from_data(data: PackedByteArray) -> PlayerInfo:
	var info := PlayerInfo.new()
	info.decode(data)
	return info

func encode() -> PackedByteArray:
	var data := super.encode()
	data.resize(3 + player_data.size())
	data.encode_u8(1, type)
	data.encode_u8(2, player_id)
	for i in range(player_data.size()):
		data[3 + i] = player_data[i]
	return data

func decode(data: PackedByteArray) -> void:
	super.decode(data)
	@warning_ignore("integer_division")
	type = data.decode_u8(1) as TYPE
	player_id = data.decode_u8(2)
	player_data.resize(data.size() - 3)
	for i in range(3, data.size()):
		player_data[i - 3] = data[i]

func get_color() -> Color:
	assert(type == TYPE.COLOR, "PlayerInfo does not contain a color")
	return Color.hex(player_data.decode_u32(0))

func get_name() -> String:
	assert(type == TYPE.NAME, "PlayerInfo does not contain a name")
	return player_data.get_string_from_utf8()
