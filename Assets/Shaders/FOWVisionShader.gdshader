shader_type canvas_item;
render_mode light_only;

uniform vec4 clothes_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float tolerance = 0.2;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec4 light = clothes_color + vec4(0.1, 0.3, 0.1, 0.0);
	
	bool shirt_color =
		abs(tex.r - 0.71) < tolerance &&
		abs(tex.g - 0.18) < tolerance &&
		abs(tex.b - 0.21) < tolerance;
	
	bool shirt_light =
		abs(tex.r - 0.8) < tolerance &&
		abs(tex.g - 0.0) < tolerance &&
		abs(tex.b - 0.21) < tolerance;

	if (shirt_color) {
		COLOR = vec4(clothes_color.rgb, tex.a);
	} else if (shirt_light) {
		COLOR = vec4(light.rgb, tex.a);
	} else {
		COLOR = tex;
	}
}
