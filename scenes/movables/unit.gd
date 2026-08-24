class_name Unit

var definition: UnitDefinition

var type := UnitDefinition.UnitType.NONE
var unit_name: String
var hp := 0
var defense := 0
var damage := 0

func _init(my_definition: UnitDefinition):
	definition = my_definition
	type = definition.unit_type
	unit_name = UnitDefinition.UNIT_TYPE_TO_STRING[type]
	hp = definition.base_hp
	defense = definition.base_defense
	damage = definition.base_damage
