class_name Banner
extends Node2D

signal finished

func raise_animation(time: float = 0.5):
	visible = true
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	# Rotate 90° counterclockwise
	tween.tween_property(self, "rotation_degrees", -90.0, time)
	
	# Fade in
	tween.tween_property(self, "modulate:a", 1.0, time)
	await tween.finished
	finished.emit()


func fall_animation(time: float = 0.5, free: bool = false):
	var tween = create_tween()
	tween.set_parallel(true)

	# Falling
	tween.tween_property(self, "rotation_degrees", 0.0, time) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)

	# Fade starts halfway through
	var fade = create_tween()
	fade.tween_interval(time / 2.0)
	fade.tween_property(self, "modulate:a", 0.0, time / 2.0) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)

	await tween.finished

	if free:
		queue_free()
	else:
		visible = false
	finished.emit()
