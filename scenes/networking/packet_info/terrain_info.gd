class_name TerrainInfo extends PacketInfo

var coordinates: Array[Vector2i]
var terrain_ids: Array[int] # max 1 byte per id... sorry ):

@warning_ignore("shadowed_variable")
static func create(coordinates: Array[Vector2i], terrain_ids: Array[int]) -> TerrainInfo:
	var info := TerrainInfo.new()
	info.packet_type = PacketInfo.PACKET_TYPE.TERRAIN_INFO
	info.flag = ENetPacketPeer.FLAG_RELIABLE
	info.coordinates = coordinates
	info.terrain_ids = terrain_ids
	return info

static func create_from_data(data: PackedByteArray) -> TerrainInfo:
	var info := TerrainInfo.new()
	info.decode(data)
	return info

func encode() -> PackedByteArray:
	var data := super.encode()
	data.resize(1 + coordinates.size() * 8 + terrain_ids.size())
	for i in range(coordinates.size()):
		var coords := coordinates[i]
		data.encode_s32(1 + 8*i, coords.x)
		data.encode_s32(5 + 8*i, coords.y)
	for i in range(terrain_ids.size()):
		var id := terrain_ids[i]
		data.encode_u8(1 + 8*coordinates.size() + i, id)
	return data

func decode(data: PackedByteArray) -> void:
	super.decode(data)
	@warning_ignore("integer_division")
	var tile_count := (data.size() - 1) / 9
	for i in range(1, 1 + 8*tile_count, 8):
		coordinates.append(Vector2i(data.decode_s32(i), data.decode_s32(i+4)))
	for i in range(1 + 8*tile_count, data.size()):
		terrain_ids.append(data.decode_u8(i))
