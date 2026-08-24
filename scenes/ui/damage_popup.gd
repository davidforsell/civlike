class_name DamagePopup
extends Label

@export var float_distance := 40.0
@export var duration := 0.7

func setup(damage: int) -> void:
	text = "%d" % damage
	modulate = Color.RED

func play() -> void:
	var start_position := position
	var end_position := start_position + Vector2(0, -float_distance)

	var tween := create_tween()
	tween.set_parallel(true)

	tween.tween_property(self, "position", end_position, duration)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)

	tween.tween_property(self, "modulate:a", 0.0, duration)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)

	await tween.finished
	queue_free()
