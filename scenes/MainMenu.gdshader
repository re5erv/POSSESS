shader_type canvas_item;

// Скорость изменения
uniform float speed = 0.5;
// Насколько сильно пульсирует
uniform float pulse_intensity = 0.15;
// Прозрачность оверлея (0.0 = невидимый, 1.0 = непрозрачный)
uniform float alpha : hint_range(0.0, 1.0) = 0.2; 

// Текстура экрана (то, что под оверлеем)
uniform sampler2D screen_texture : hint_screen_texture, filter_linear;

void fragment() {
	vec2 uv = SCREEN_UV;
	float time = TIME * speed;
	
	// Генерируем плавный "шум"
	float noise = sin(uv.x * 3.0 + time) * cos(uv.y * 3.0 - time * 0.8);
	float noise2 = sin((uv.x + uv.y) * 4.0 + time * 1.5) * 0.5;
	
	// Смешиваем и приводим к диапазону 0..1
	float gray = (noise + noise2) * 0.5 + 0.5;
	
	// Делаем цвет очень темным
	vec3 dark_gray = vec3(0.05);
	vec3 light_gray = vec3(0.25);
	
	vec3 overlay_color = mix(dark_gray, light_gray, gray);
	overlay_color += pulse_intensity * sin(time * 2.0);
	
	// БЕРЕМ ЦВЕТ ИЗ-ПОД ОВЕРЛЕЯ (текстура экрана)
	vec4 base_color = texture(screen_texture, SCREEN_UV);
	
	// СМЕШИВАЕМ ЦВЕТ КАРТИНКИ С НАШИМ СЕРО-ЧЕРНЫМ ШУМОМ
	// alpha отвечает за то, насколько сильно оверлей перекрывает картинку
	COLOR = mix(base_color, vec4(overlay_color, 1.0), alpha);
}
