extends Label

func _on_info_panel_enter() -> void:
	var id := TurnManager.get_current_player_id()
	var selected_structure := GameState.player_datas[id].selected_structure
	text = selected_structure.structure_name
	add_theme_color_override("font_color", selected_structure.color)
