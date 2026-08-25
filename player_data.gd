class_name PlayerData

signal spawn_border_ready

var id: int
var name: String
var color: Color = Color.WHITE
var is_bot := false
var owned_structures: Array[Structure] = []
var owned_armies: Array[Movable] = []

var spawn_border: SpawnBorder: 
	set(new):
		spawn_border = new
		spawn_border.color = Color.RED
		spawn_border_ready.emit()
		if !NetworkHandler.is_server:
			print("Client ", ClientNetworkGlobals.id, " spawn border received!")

var selected_structure: Structure = null
var selected_movable: Movable = null
var selected_unit: UnitDefinition.UnitType

func _init(player_id: int):
	id = player_id
