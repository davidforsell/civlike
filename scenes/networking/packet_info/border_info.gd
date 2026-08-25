class_name BorderInfo extends PacketInfo

enum TYPE {
	SPAWN_BORDER,
	STRUCTURE_BORDER,
}

var type: TYPE
var coords: Array[Vector2i]

var owner_id: int

@warning_ignore("shadowed_variable")
static func create(type: TYPE, coords: Array[Vector2i], owner_id: int = 0) -> BorderInfo:
	var info := BorderInfo.new()
	info.packet_type = PacketInfo.PACKET_TYPE.BORDER_INFO
	info.flag = ENetPacketPeer.FLAG_RELIABLE
	info.type = type
	info.coords = coords
	info.owner_id = owner_id
	return info

static func create_from_data(data: PackedByteArray) -> BorderInfo:
	var info := BorderInfo.new()
	info.decode(data)
	return info

func encode() -> PackedByteArray:
	var data := super.encode()
	data.resize(3 + coords.size() * 8)
	data.encode_u8(1, type)
	for i in range(coords.size()):
		var current_coords := coords[i]
		data.encode_s32(2 + 8*i, current_coords.x)
		data.encode_s32(6 + 8*i, current_coords.y)
	data.encode_u8(data.size() - 1, owner_id)
	
	return data

func decode(data: PackedByteArray) -> void:
	super.decode(data)
	type = data.decode_u8(1) as TYPE
	for i in range(2, data.size(), 8):
		coords.append(Vector2i(data.decode_s32(i), data.decode_s32(i+4)))
	owner_id = data.decode_u8(data.size()-1)
