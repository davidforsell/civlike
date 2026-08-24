shader_type canvas_item;

uniform float zoom_value : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    COLOR = texture(TEXTURE, UV);

    // Make everything slightly transparent
	if (COLOR.r < 0.1 && COLOR.g < 0.1 && COLOR.b < 0.1) {
		COLOR.a *= 0.2 * zoom_value;
	} else {
    	COLOR.a *= 1.0 * zoom_value;
	}
}