class_name Border

signal color_updated(new_value: Color)

static func create_from_array(coordinates: Array[Vector2i]) -> Border:
	var border := Border.new()
	for hex in coordinates:
		border.add_hex(hex)
	return border

var color: Color = Color.WHITE: 
	set(new_value):
		color = new_value
		color_updated.emit(new_value)
var contents: Dictionary[Vector2i, bool] = {}

func add_hex(coords: Vector2i):
	contents[coords] = true
