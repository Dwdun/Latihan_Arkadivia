shader_type canvas_item;

// Parameter untuk mengatur tingkat keburaman (0.0 = Jelas, 5.0 = Buram)
uniform float lod: hint_range(0.0, 5.0) = 0.0;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment(){
	// Mengambil warna dari layar di belakang object ini, dengan tingkat blur (LOD) tertentu
	vec4 color = texture(screen_texture, SCREEN_UV, lod);
	COLOR = color;
}