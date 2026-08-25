extends Control

@onready var h_box: HBoxContainer = $HBoxContainer
@onready var waiting: Label = $Waiting
@onready var start_button: Button = $Start

var is_host: bool = false

func _enter_tree() -> void:
	ClientNetworkGlobals.handle_game_message.connect(_on_client_game_message)
	ServerNetworkGlobals.handle_game_message.connect(_on_server_game_message)
	if "--server" in OS.get_cmdline_args():
		NetworkHandler.start_server()

func _on_server_game_message(peer_id: int, message: GameMessage):
	if !NetworkHandler.is_server: return
	if message.message == GameMessage.MESSAGE.START_GAME:
		print("Start game message received")
		server_start()

func _on_client_game_message(message: GameMessage):
	if NetworkHandler.is_server: return
	match message.message:
		GameMessage.MESSAGE.START_GAME:
			client_start()

func client_start():
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func server_start():
	GameMessage.create(GameMessage.MESSAGE.START_GAME).broadcast(NetworkHandler.connection)
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _on_server_pressed() -> void:
	NetworkHandler.start_host()
	is_host = true
	h_box.visible = false
	start_button.visible = true


func _on_client_pressed() -> void:
	NetworkHandler.start_client()
	h_box.visible = false
	waiting.visible = true


func _on_start_pressed() -> void:
	if !is_host: return
	GameMessage.create(GameMessage.MESSAGE.START_GAME).send(NetworkHandler.server_peer)
