class_name EnterStructurename
extends Control
@onready var line_edit: LineEdit = $MarginContainer/HBoxContainer/LineEdit


func _on_line_edit_text_submitted(new_text: String) -> void:
	if NetworkHandler.is_server: return
	if new_text == "": return
	
	var id = ClientNetworkGlobals.id
	var selected_structure: Structure = GameState.player_datas[id].selected_structure
	selected_structure.structure_name = new_text
	StructureInfo.create_name_updated(selected_structure.id, new_text).send(NetworkHandler.server_peer)
	visible = false


func _on_random_pressed() -> void:
	line_edit.text = TownNameGenerator.generate_name(5, 10)
