class_name StructureInfo extends PacketInfo

enum TYPE {
	INVALID,
	STRUCTURE_CREATED,
	NAME_UPDATED,
}

# ALWAYS transmitted
var type: TYPE
var structure_id: int

# STRUCTURE_CREATED
var coords: Vector2i
var owner_id: int
var structure_resource_id: int

# NAME_UPDATED
var structure_name: String

# Info about structure border will be sent in a separate border_info packet...

@warning_ignore("shadowed_variable")
static func create_structure_created(structure_id: int, coords: Vector2i, owner_id: int, structure_resource_id: int) -> StructureInfo:
	var info := StructureInfo.new()
	info.packet_type = PacketInfo.PACKET_TYPE.STRUCTURE_INFO
	info.flag = ENetPacketPeer.FLAG_RELIABLE
	info.type = TYPE.STRUCTURE_CREATED
	info.structure_id = structure_id
	info.coords = coords
	info.owner_id = owner_id
	info.structure_resource_id = structure_resource_id
	return info

@warning_ignore("shadowed_variable")
static func create_name_updated(structure_id: int, structure_name: String) -> StructureInfo:
	var info := StructureInfo.new()
	info.packet_type = PacketInfo.PACKET_TYPE.STRUCTURE_INFO
	info.flag = ENetPacketPeer.FLAG_RELIABLE
	info.type = TYPE.NAME_UPDATED
	info.structure_id = structure_id
	info.structure_name = structure_name
	return info

static func create_from_data(data: PackedByteArray) -> StructureInfo:
	var info := StructureInfo.new()
	info.decode(data)
	return info

func encode() -> PackedByteArray:
	match type:
		TYPE.STRUCTURE_CREATED: return _encode_structure_created()
		TYPE.NAME_UPDATED: return _encode_name_updated()
		_: 
			push_error("Invalid StructureInfo type")
			return super.encode()

func _encode_structure_created() -> PackedByteArray:
	var data := super.encode()
	data.resize(13)
	data.encode_u8(1, type)
	data.encode_u8(2, structure_id)
	data.encode_s32(3, coords.x)
	data.encode_s32(7, coords.y)
	data.encode_u8(11, owner_id)
	data.encode_u8(12, structure_resource_id)
	return data

func _encode_name_updated():
	var data := super.encode()
	var name_bytes := structure_name.to_utf8_buffer()
	data.resize(3 + name_bytes.size())
	
	data.encode_u8(1, type)
	data.encode_u8(2, structure_id)
	
	for i in range(name_bytes.size()):
		data[i + 3] = name_bytes[i]
	
	return data

func decode(data: PackedByteArray) -> void:
	super.decode(data)
	type = data.decode_u8(1) as TYPE
	structure_id = data.decode_u8(2)
	match type:
		TYPE.STRUCTURE_CREATED: _decode_structure_created(data)
		TYPE.NAME_UPDATED: _decode_name_updated(data)
		_: push_error("Invalid StructureInfo type")

func _decode_structure_created(data: PackedByteArray) -> void:
	coords = Vector2i(data.decode_s32(3), data.decode_s32(7))
	owner_id = data.decode_u8(11)
	structure_resource_id = data.decode_u8(12)

func _decode_name_updated(data: PackedByteArray) -> void:
	structure_name = data.slice(3).get_string_from_utf8()
