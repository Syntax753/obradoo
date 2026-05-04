shader_type canvas_item;

// 1-bit ordered (Bayer) dither, applied to the SubViewport's render.
// Quantises luminance against a 4x4 threshold matrix and snaps each pixel
// to one of two palette colours — the Obra Dinn aesthetic.

uniform vec3 ink_color : source_color = vec3(0.10, 0.08, 0.06);
uniform vec3 parchment_color : source_color = vec3(0.91, 0.86, 0.74);
uniform float bias : hint_range(-0.5, 0.5) = 0.0;
uniform float pixel_scale : hint_range(1.0, 8.0) = 2.0;

const float bayer4[16] = float[16](
	 0.0,  8.0,  2.0, 10.0,
	12.0,  4.0, 14.0,  6.0,
	 3.0, 11.0,  1.0,  9.0,
	15.0,  7.0, 13.0,  5.0
);

void fragment() {
	vec3 src = texture(TEXTURE, UV).rgb;
	float lum = dot(src, vec3(0.299, 0.587, 0.114));
	ivec2 p = ivec2(FRAGCOORD.xy / pixel_scale) % 4;
	float threshold = (bayer4[p.y * 4 + p.x] + 0.5) / 16.0;
	float v = step(threshold + bias, lum);
	COLOR = vec4(mix(ink_color, parchment_color, v), 1.0);
}
