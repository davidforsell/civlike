class_name TileSelectedInfo extends PacketInfo

enum TYPE {
	SPAWN_TILE,
}

var type: TYPE
var coordinates: Vector2i

@warning_ignore("shadowed_variable")
static func create(type: TYPE, coordinates: Vector2i) -> TileSelectedInfo:
	var info := TileSelectedInfo.new()
	info.packet_type = PacketInfo.PACKET_TYPE.TILE_SELECTED_INFO
	info.flag = ENetPacketPeer.FLAG_RELIABLE
	info.type = type
	info.coordinates = coordinates
	return info

static func create_from_data(data: PackedByteArray) -> TileSelectedInfo:
	var info := TileSelectedInfo.new()
	info.decode(data)
	return info

func encode() -> PackedByteArray:
	var data := super.encode()
	data.resize(10)
	data.encode_u8(1, type)
	data.encode_s32(2, coordinates.x)
	data.encode_s32(6, coordinates.y)
	return data

func decode(data: PackedByteArray) -> void:
	super.decode(data)
	type = data.decode_u8(1) as TYPE
	coordinates = Vector2i(data.decode_s32(2), data.decode_s32(6))
