extends Node

const DAMAGE_POPUP = preload("res://scenes/ui/damage_popup.tscn")

func show_damage(target: Node2D, damage: int) -> void:
	var popup = DAMAGE_POPUP.instantiate()

	target.get_parent().add_child(popup)

	popup.global_position = target.global_position + Vector2(0, -20)

	popup.setup(damage)
	popup.play()
