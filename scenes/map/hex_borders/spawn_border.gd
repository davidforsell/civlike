class_name SpawnBorder
extends Border

var centre: Vector2i

static func create_from_array(coordinates: Array[Vector2i]) -> SpawnBorder:
	var spawn_border := SpawnBorder.new()

	for hex in coordinates:
		spawn_border.add_hex(hex)

	spawn_border.centre = coordinates[0] # by convention
	return spawn_border
