class_name Player
extends Node

enum Phase { WAIT, SPAWN, MOVE }

signal hex_selected(hex_coords: Vector2i, player_data: PlayerData)

var data: PlayerData
var phase: Phase = Phase.WAIT
var hex_map: HexMap
var hex_borders: HexBorders
var camera: MapCamera

var target_player_id: int

func _enter_tree() -> void:
	ClientNetworkGlobals.handle_game_message.connect(_on_client_game_message)
	ClientNetworkGlobals.handle_border_info.connect(_on_client_border_info)

func _init(player_data):
	data = player_data

func _on_client_game_message(message: GameMessage):
	if NetworkHandler.is_server: return
	match message.message:
		GameMessage.MESSAGE.START_TURN:
			_on_client_turn_start()
		GameMessage.MESSAGE.END_TURN:
			_on_client_turn_end()

func _on_client_border_info(info: BorderInfo):
	if NetworkHandler.is_server: return
	match info.type:
		BorderInfo.TYPE.SPAWN_BORDER:
			data.spawn_border = SpawnBorder.create_from_array(info.coords)

func _on_client_turn_start():
	print("Client ", str(ClientNetworkGlobals.id), ": Turn started")
	if data.owned_structures == []:
		# Start of game since own no structures (or dead...)
		phase = Phase.SPAWN
		client_pick_spawn()

func _on_client_turn_end():
	print("Client ", str(ClientNetworkGlobals.id), ": Turn ended")
	camera.block_input = false

func client_pick_spawn():
	if !data.spawn_border:
		print("Client ", str(ClientNetworkGlobals.id), ": Awaiting spawn border")
		await data.spawn_border_ready
	camera.pan_smoothly(hex_map.tile_to_world(data.spawn_border.centre))
	camera.zoom = Vector2i.ONE * 0.35
	hex_borders.draw_border(data.spawn_border)
	camera.block_input = true

func _unhandled_input(event: InputEvent) -> void:
	if NetworkHandler.is_server: return
	if data.is_bot: return
	if event.is_action_pressed("select"):
		hex_selected.emit(hex_map.get_mouse_coords(), data)

func _on_turn_end():
	phase = Phase.WAIT
