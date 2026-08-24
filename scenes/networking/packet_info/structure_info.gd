class_name StructureInfo extends PacketInfo

enum TYPE {
	STRUCTURE_CREATED,
}

var type: TYPE
var coords: Vector2i
var owner_id: int
var structure_resource_id: int
# Info about structure border will be sent in a separate border_info packet...

@warning_ignore("shadowed_variable")
static func create(type: TYPE, coords: Vector2i, owner_id: int, structure_resource_id: int) -> StructureInfo:
	var info := StructureInfo.new()
	info.packet_type = PacketInfo.PACKET_TYPE.STRUCTURE_INFO
	info.flag = ENetPacketPeer.FLAG_RELIABLE
	info.type = type
	info.coords = coords
	info.owner_id = owner_id
	info.structure_resource_id = structure_resource_id
	return info

static func create_from_data(data: PackedByteArray) -> StructureInfo:
	var info := StructureInfo.new()
	info.decode(data)
	return info

func encode() -> PackedByteArray:
	var data := super.encode()
	data.resize(12)
	data.encode_u8(1, type)
	data.encode_s32(2, coords.x)
	data.encode_s32(6, coords.y)
	data.encode_u8(10, owner_id)
	data.encode_u8(11, structure_resource_id)
	return data

func decode(data: PackedByteArray) -> void:
	super.decode(data)
	type = data.decode_u8(1) as TYPE
	coords = Vector2i(data.decode_s32(2), data.decode_s32(6))
	owner_id = data.decode_u8(10)
	structure_resource_id = data.decode_u8(11)
