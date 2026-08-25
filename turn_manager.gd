extends Node

signal turn_changed(active_player: int)

func add_player(player: PlayerData) -> void:
	GameState.add_player(player)

func get_current_player_id() -> int:
	return GameState.get_current_player_id()

func server_start_turn():
	var current_player := get_current_player_id()
	if !GameState.player_datas[current_player].is_bot:
		print("Sending start turn message to client ", str(current_player))
		GameMessage.create(GameMessage.MESSAGE.START_TURN).send(NetworkHandler.client_peers[current_player])
	else:
		var bot := GameState.players[current_player] as Bot
		bot.start_turn()

func server_end_turn():
	if !NetworkHandler.is_server: return
	var prev_id := get_current_player_id()
	var prev_data := GameState.player_datas[prev_id]
	var prev_player := GameState.players[prev_id]
	if prev_data.is_bot:
		prev_player = prev_player as Bot
		prev_player.end_turn()
	else:
		GameState.players[prev_id]._on_turn_end()
		GameMessage.create(GameMessage.MESSAGE.END_TURN).send(NetworkHandler.client_peers[prev_id])
	
	GameState.advance_player()
	
	var id := get_current_player_id()
	turn_changed.emit(id)
	server_start_turn()
	
