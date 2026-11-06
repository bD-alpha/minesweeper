shader_type canvas_item;

varying vec2 coords;

void vertex() {
	VERTEX *= 0.5;
}

void fragment() {
	COLOR.xy = UV;
	COLOR.z = 0.0;
}
