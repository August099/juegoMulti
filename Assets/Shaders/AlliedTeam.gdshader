shader_type canvas_item;

uniform vec4 clothes_color : source_color = vec4(0.0, 0.56, 1.0, 1.0);
uniform float tolerance = 0.5;

void fragment() {
	vec4 tex = texture(TEXTURE, UV);

	bool is_white =
		abs(tex.r - 1.0) < tolerance &&
		abs(tex.g - 1.0) < tolerance &&
		abs(tex.b - 1.0) < tolerance;

	if (is_white) {
		COLOR = vec4(clothes_color.rgb, tex.a);
	} else {
		COLOR = tex;
	}
}
