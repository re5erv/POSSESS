shader_type canvas_item;
render_mode unshaded, blend_mix;

uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
// Смещение в ЦЕЛЫХ ПИКСЕЛЯХ (1.0 или 2.0)
uniform float aberration_pixels : hint_range(0.0, 5.0) = 1.0; 
uniform float contrast : hint_range(0.5, 2.0) = 1.1;

// Настройки сканлайнов
uniform float scanline_density : hint_range(1.0, 10.0) = 2.0; // Частота полос
uniform float scanline_opacity : hint_range(0.0, 0.5) = 0.1;  // Насколько темные полосы

void fragment() {
	// Размер пикселя экрана
	vec2 pixel_size = SCREEN_PIXEL_SIZE;
	
	// Смещение ровно на N пикселей (чёткое)
	vec2 offset = vec2(aberration_pixels * pixel_size.x, 0.0);
	
	vec2 uv = SCREEN_UV;
	
	// Берём каналы с четким смещением
	float r = texture(screen_texture, uv + offset).r;
	float g = texture(screen_texture, uv).g;
	float b = texture(screen_texture, uv - offset).b;
	
	vec3 color = vec3(r, g, b);
	
	// Контраст
	color = (color - 0.5) * contrast + 0.5;
	
	// --- СКАНЛАЙНЫ ---
	// Привязываем к реальным пикселям экрана (FRAGCOORD)
	// Делим на scanline_density, чтобы полосы были крупнее
	float scanline = sin(FRAGCOORD.y / scanline_density * 3.1415);
	
	// Умножаем на opacity, чтобы полосы были мягкими
	color -= scanline * scanline_opacity;
	
	COLOR = vec4(color, 1.0);
}