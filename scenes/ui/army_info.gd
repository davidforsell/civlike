extends VBoxContainer

@export var panel: CustomPanel


var icon_label_scene = preload("res://scenes/ui/icon_label.tscn")
var army_texture = preload("res://assets/sprites/train_army.png")
var damage_texture = preload("res://assets/sprites/sword_icon.png")
var defense_texture = preload("res://assets/sprites/defense_icon.png")
var hp_texture = preload("res://assets/sprites/hp_icon.png")

func _ready():
	panel.enter.connect(_on_enter)
	panel.exit.connect(_on_exit)

func _on_enter():
	var id := TurnManager.get_current_player_id()
	var units := GameState.player_datas[id].selected_movable.units
	var total_hp := 0
	var damage := 0
	var defense := 0
	
	for unit in units:
		var h_box_container: HBoxContainer = HBoxContainer.new()
		add_child(h_box_container)
		var instance: IconLabel = icon_label_scene.instantiate()
		instance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h_box_container.add_child(instance)
		h_box_container.add_child(create_hp_label(": ", unit.hp))
		h_box_container.add_child(create_damage_label(": ", unit.damage))
		h_box_container.add_child(create_defense_label(": ", unit.defense))
		instance.icon = army_texture
		instance.text = unit.unit_name
		instance.update()
		
		damage += unit.damage
		defense += unit.defense
		total_hp += unit.hp
		
	var h_separator: HSeparator = HSeparator.new()
	h_separator.add_theme_constant_override("separation", 20)
	
	
	add_child(h_separator)
	
	add_child(create_damage_label("Total damage: ", damage))
	add_child(create_defense_label("Total defense: ", defense))
	add_child(create_hp_label("Total hp: ", total_hp))

func create_hp_label(text: String, hp: int) -> IconLabel:
	var hp_label: IconLabel = icon_label_scene.instantiate()
	hp_label.icon = hp_texture
	hp_label.text = text + str(hp)
	hp_label.update()
	return hp_label

func create_damage_label(text: String, damage: int) -> IconLabel:
	var damage_label: IconLabel = icon_label_scene.instantiate()
	damage_label.icon = damage_texture
	damage_label.text = text + str(damage)
	damage_label.update()
	return damage_label

func create_defense_label(text: String, defense: int) -> IconLabel:
	var defense_label: IconLabel = icon_label_scene.instantiate()
	defense_label.icon = defense_texture
	defense_label.text = text + str(defense)
	defense_label.update()
	return defense_label

func _on_exit():
	for child in get_children():
		child.queue_free()
	
	
