shader_type canvas_item;

uniform float size : hint_range(1.0, 100.0) = 100.0;
uniform float scroll_speed : hint_range(1.0, 100.0) = 15.0;
uniform vec4 color1 : source_color = vec4(0.1961, 0.2157, 0.2549, 1.0000); 
uniform vec4 color2 : source_color = vec4(0.1647, 0.1804, 0.2157, 1.0000);

void fragment() {
	vec2 pos = FRAGCOORD.xy;
	pos.x += TIME * scroll_speed;
    pos = floor(pos / size);
    float pattern_mask = mod(pos.x + mod(pos.y, 2.0), 2.0);
    COLOR = mix(color1, color2, pattern_mask);
}