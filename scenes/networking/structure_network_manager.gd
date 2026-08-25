extends Node

var pending_info: Dictionary[int, Array] = {}

var pending_info_timer: Timer = Timer.new()

func _enter_tree() -> void:
	ClientNetworkGlobals.handle_structure_info.connect(_on_client_handle_info)
	add_child(pending_info_timer)
	pending_info_timer.timeout.connect(_apply_pending_info)
	ServerNetworkGlobals.handle_structure_info.connect(_on_server_handle_info)

func _on_server_handle_info(peer_id: int, info: StructureInfo) -> void:
	if !NetworkHandler.is_server: return
	var owner_id = GameState.structures[info.structure_id].player_owner_id
	if peer_id != owner_id: return
	match info.type:
		StructureInfo.TYPE.NAME_UPDATED: _server_update_name(info)

func _on_client_handle_info(info: StructureInfo) -> void:
	if NetworkHandler.is_server: return
	match info.type:
		#Structure created handled in main
		StructureInfo.TYPE.STRUCTURE_CREATED: _apply_pending_info()
		StructureInfo.TYPE.NAME_UPDATED: _client_update_name(info)

func _server_update_name(info: StructureInfo) -> void:
	if info.structure_name == "": return
	var structure := GameState.structures[info.structure_id]
	structure.structure_name = info.structure_name

func _client_update_name(info: StructureInfo) -> void:
	var structure: Structure = GameState.structures.get(info.structure_id)

	if structure:
		structure.structure_name = info.structure_name
	else:
		_queue_info(info)


func _queue_info(info: StructureInfo) -> void:
	if info.structure_id not in pending_info:
		pending_info[info.structure_id] = []

	pending_info[info.structure_id].append(info)
	pending_info_timer.start(0.1)


func _apply_pending_info() -> void:
	for key in pending_info.keys():
		if key in GameState.structures:
			for info in pending_info[key]:
				_on_client_handle_info(info)
			pending_info.erase(key)
	
	if !pending_info.is_empty():
		pending_info_timer.start(0.1)
