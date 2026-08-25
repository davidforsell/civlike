class_name MapCamera
extends Camera2D

@export var pan_speed := 1.0
@export var zoom_speed := 0.5
@export var zoom_speed_trackpad := 0.01
@export var min_zoom := 0.2
@export var max_zoom := 3.0

@export var map: HexMap

@export var hex_overlay_material: ShaderMaterial

var dragging := false
var zoom_in := false
var zoom_out := false

var block_input: bool = false:
	set(new):
		block_input = new
		if new: print("Camera blocked")
		else: print("Camera unblocked")

var last_mouse_position := Vector2.ZERO

var move_direction: Vector2 = Vector2.ZERO

func _unhandled_input(event: InputEvent) -> void:
	if block_input:
		return
	# Start dragging
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			dragging = event.pressed
			last_mouse_position = event.position
			
	if event.is_action_pressed("zoom_in"):
		zoom_in = true
	elif event.is_action_released("zoom_in"):
		zoom_in = false
	
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_camera(zoom_speed * 0.005)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_camera(-zoom_speed * 0.005)


	if event.is_action_pressed("zoom_out"):
		zoom_out = true
	elif event.is_action_released("zoom_out"):
		zoom_out = false
	
	if event.is_action_pressed("up"):
		move_direction.y = -1
	if event.is_action_pressed("down"):
		move_direction.y = 1
	if event.is_action_pressed("left"):
		move_direction.x = -1
	if event.is_action_pressed("right"):
		move_direction.x = 1
	
	if event.is_action_released("up"):
		move_direction.y = 0
	if event.is_action_released("down"):
		move_direction.y = 0
	if event.is_action_released("left"):
		move_direction.x = 0
	if event.is_action_released("right"):
		move_direction.x = 0

	# Move camera while dragging
	if event is InputEventMouseMotion and dragging:
		var mouse_delta = event.position - last_mouse_position
		position -= mouse_delta * pan_speed / zoom.x
		position = Vector2(clamp(position.x,limit_left+get_viewport_rect().size.x/2,limit_right-get_viewport_rect().size.x/2),clamp(position.y,limit_top+get_viewport_rect().size.y/2,limit_bottom-get_viewport_rect().size.y/2))
		last_mouse_position = event.position
	
	if event is InputEventPanGesture:
		zoom_camera(-zoom_speed_trackpad * event.delta.y)

func _process(delta: float) -> void:
	if zoom_in:
		zoom_camera(zoom_speed * delta)
	if zoom_out:
		zoom_camera(-zoom_speed * delta)
	
	position += move_direction * pan_speed * 15 / zoom.x
	
	map.update_border_camera(global_position, zoom)

func pan_smoothly(new_global_position: Vector2) -> void:
	var tween := create_tween()

	tween.tween_property(
		self,
		"global_position",
		new_global_position,
		0.5
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func zoom_camera(amount: float):
	var new_zoom := zoom + Vector2(amount, amount)
	
	new_zoom.x = clamp(new_zoom.x, min_zoom, max_zoom)
	new_zoom.y = clamp(new_zoom.y, min_zoom, max_zoom)

	var mouse_pos := get_global_mouse_position()
	zoom = new_zoom
	var new_mouse_pos := get_global_mouse_position()
	position +=  (mouse_pos - new_mouse_pos)
	
	var zoom_ratio = min_zoom / zoom.x
	
	if zoom_ratio > 0.9:
		var shader_value = lerp(0.0, 1.0, (zoom_ratio - 0.9) / 0.1)
		hex_overlay_material.set_shader_parameter("zoom_value", shader_value)
	else:
		hex_overlay_material.set_shader_parameter("zoom_value", 0.0)
