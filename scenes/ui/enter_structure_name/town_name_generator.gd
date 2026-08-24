extends Node

var used_names: Dictionary = {}

var chain: Dictionary = {}

var name_file := "res://scenes/ui/enter_structure_name/city_names.txt"
var source_names: Array[String] = []

func _ready() -> void:
	randomize()

	var names := load_source_names(name_file)

	chain = build_chain(names)

func load_source_names(file_path: String) -> Array[String]:
	var names: Array[String] = []

	if not FileAccess.file_exists(file_path):
		push_warning("Could not find name file: " + file_path)
		return names

	var file := FileAccess.open(file_path, FileAccess.READ)

	if file == null:
		push_warning("Could not open name file: " + file_path)
		return names

	while not file.eof_reached():
		var read_name := file.get_line().strip_edges()

		if not read_name.is_empty():
			names.append(read_name)

	file.close()

	return names


func build_chain(names: Array[String]) -> Dictionary:
	var new_chain: Dictionary = {}

	for town_name in names:
		var new_name := "^" + town_name.to_lower() + "$"

		for i in range(new_name.length() - 2):
			var pair := new_name.substr(i, 2)
			var next_character := new_name[i + 2]

			if not new_chain.has(pair):
				new_chain[pair] = []

			new_chain[pair].append(next_character)

	return new_chain


func generate_name(min_length: int = 5, max_length: int = 15) -> String:
	var possible_starts: Array[String] = []

	for pair in chain:
		if pair.begins_with("^"):
			possible_starts.append_array(chain[pair])

	if possible_starts.is_empty():
		return "Unnamed"

	var result := ""
	var attempts := 0

	while result.length() < min_length and attempts < 100:
		attempts += 1
		result = ""

		var first_character: String = possible_starts.pick_random()
		result += first_character

		while result.length() < max_length:
			var pair: String

			if result.length() == 1:
				pair = "^" + result
			else:
				pair = result.substr(result.length() - 2, 2)

			if not chain.has(pair):
				break

			var next_character: String = chain[pair].pick_random()

			if next_character == "$":
				break

			result += next_character

	if result.length() < min_length:
		return "Unnamed"

	return result.capitalize()
