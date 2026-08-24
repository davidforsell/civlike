class_name StaminaBar
extends Sprite2D

@onready var bar: Sprite2D = $Bar

func set_stamina_percentage(percentage: float):
	bar.scale.y = percentage
