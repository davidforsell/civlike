class_name BorderInfo extends PacketInfo

enum TYPE {
	SPAWN_BORDER,
	STRUCTURE_BORDER,
}

var type: TYPE
var coordinates: Array[Vector2i]

@warning_ignore("shadowed_variable")
static func create(type: TYPE, coordinates: Array[Vector2i]) -> BorderInfo:
	var info := BorderInfo.new()
	info.packet_type = PacketInfo.PACKET_TYPE.BORDER_INFO
	info.flag = ENetPacketPeer.FLAG_RELIABLE
	info.type = type
	info.coordinates = coordinates
	return info

static func create_from_data(data: PackedByteArray) -> BorderInfo:
	var info := BorderInfo.new()
	info.decode(data)
	return info

func encode() -> PackedByteArray:
	var data := super.encode()
	data.resize(2 + coordinates.size() * 8)
	data.encode_u8(1, type)
	for i in range(coordinates.size()):
		var coords := coordinates[i]
		data.encode_s32(2 + 8*i, coords.x)
		data.encode_s32(6 + 8*i, coords.y)
	return data

func decode(data: PackedByteArray) -> void:
	super.decode(data)
	type = data.decode_u8(1) as TYPE
	for i in range(2, data.size(), 8):
		coordinates.append(Vector2i(data.decode_s32(i), data.decode_s32(i+4)))
