class_name StructureInfoPanel
extends CustomPanel

@onready var container: VBoxContainer = $MarginContainer/PanelContainer/VBoxContainer
@onready var change_name: HBoxContainer = $MarginContainer/PanelContainer/VBoxContainer/ChangeName


var hp_texture = preload("res://assets/sprites/hp_icon.png")
var defense_texture = preload("res://assets/sprites/defense_icon.png")
var icon_label_scene = preload("res://scenes/ui/icon_label.tscn")

var labels: Array[IconLabel] = []

func _on_enter():
	var id := TurnManager.get_current_player_id()
	var structure := GameState.player_datas[id].selected_structure
	
	if structure.player_owner_id == TurnManager.get_current_player_id():
		change_name.visible = true
	else:
		change_name.visible = false
	
	var hp_icon: IconLabel = icon_label_scene.instantiate()
	container.add_child(hp_icon)
	hp_icon.icon = hp_texture
	hp_icon.text = "HP: " + str(structure.hp) + " / " + str(structure.definition.base_hp)
	hp_icon.update()
	labels.append(hp_icon)
	
	var defense_icon: IconLabel = icon_label_scene.instantiate()
	container.add_child(defense_icon)
	defense_icon.icon = defense_texture
	defense_icon.text = "Defence: " + str(structure.defense)
	defense_icon.update()
	labels.append(defense_icon)

func _on_exit():
	for label in labels:
		label.queue_free()
	labels = []
