shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
// УМЕНЬШИЛИ ЗНАЧЕНИЕ (было 0.002, стало 0.0008)
uniform float aberration_amount : hint_range(0.0, 0.05) = 0.0008; 
uniform float contrast : hint_range(0.5, 2.0) = 1.1;

void fragment() {
	vec2 uv = SCREEN_UV;
	
	// Смещение красного и синего каналов
	vec2 offset = vec2(aberration_amount, 0.0);
	float r = texture(screen_texture, uv + offset).r;
	float g = texture(screen_texture, uv).g;
	float b = texture(screen_texture, uv - offset).b;
	vec3 color = vec3(r, g, b);
	
	// Повышаем контраст
	color = (color - 0.5) * contrast + 0.5;
	
	// Легкий сканлайн
	float scanline = sin(uv.y * 800.0) * 0.04;
	color -= scanline;
	
	COLOR = vec4(color, 1.0);
}
