shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_nearest;
uniform float refraction_magnitude = 30.0;
uniform float time_scale = 2;
uniform float amplitude = 1.0f;

void vertex() {
	VERTEX .y += sin(TIME * time_scale + VERTEX.y + VERTEX.x) * amplitude;
}