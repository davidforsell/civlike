class_name UnitDefinition
extends Resource

@export var texture: CompressedTexture2D
@export var unit_type: UnitType = UnitType.NONE
@export var base_damage: int = 0
@export var base_hp: int = 0
@export var base_defense: int = 0
@export var base_stamina: int = 0

@export var base_money_cost: int = 0
@export var base_population_cost: int = 0

enum UnitType {
	NONE,
	SWORDSMAN,
	ARCHER,
	PIKEMAN
}

const UNIT_TYPE_TO_STRING: Dictionary[UnitType, String] = {
	UnitType.SWORDSMAN: "Swordsman",
	UnitType.ARCHER: "Archer",
	UnitType.PIKEMAN: "Pikeman"
}
