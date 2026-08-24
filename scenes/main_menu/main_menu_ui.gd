extends Control

@onready var h_box: HBoxContainer = $HBoxContainer
@onready var waiting: Label = $Waiting
@onready var start_button: Button = $Start

func _enter_tree() -> void:
	ClientNetworkGlobals.handle_game_message.connect(_on_client_game_message)

func _on_client_game_message(message: GameMessage):
	if NetworkHandler.is_server:
		return
	match message.message:
		GameMessage.MESSAGE.START_GAME:
			client_start()

func client_start():
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func server_start():
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

func _on_server_pressed() -> void:
	NetworkHandler.start_server()
	h_box.visible = false
	start_button.visible = true


func _on_client_pressed() -> void:
	NetworkHandler.start_client()
	h_box.visible = false
	waiting.visible = true


func _on_start_pressed() -> void:
	if not NetworkHandler.is_server:
		return
	GameMessage.create(GameMessage.MESSAGE.START_GAME).broadcast(NetworkHandler.connection)
	server_start()
