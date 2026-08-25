class_name MainUI
extends CanvasLayer

@onready var structure_buttons: StructureButtons = $StructureButtons
@onready var army_buttons: HBoxContainer = $ArmyButtons

func hide_all_buttons():
	structure_buttons.hide_buttons()
	army_buttons.hide_buttons()

func client_select_structure(structure: Structure):
	if NetworkHandler.is_server: return
	if structure.player_owner_id == ClientNetworkGlobals.id:
		structure_buttons.set_owner_buttons_visible()
	else:
		structure_buttons.set_non_owner_buttons_visible()

func client_select_movable(movable: Movable):
	if NetworkHandler.is_server: return
	if movable.player_owner_id == ClientNetworkGlobals.id:
		army_buttons.set_owner_buttons_visible()
	else:
		army_buttons.set_non_owner_buttons_visible()
