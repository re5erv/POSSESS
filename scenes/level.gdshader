shader_type canvas_item;

// Скорость изменения
uniform float speed = 0.5;
// Насколько сильно пульсирует (делает темнее/светлее)
uniform float pulse_intensity = 0.15;

void fragment() {
	vec2 uv = SCREEN_UV;
	float time = TIME * speed;
	
	// Генерируем плавный "шум" с помощью синусоид
	// Мы используем разные частоты, чтобы пятна двигались хаотично
	float noise = sin(uv.x * 3.0 + time) * cos(uv.y * 3.0 - time * 0.8);
	float noise2 = sin((uv.x + uv.y) * 4.0 + time * 1.5) * 0.5;
	
	// Смешиваем и приводим к диапазону 0..1
	float gray = (noise + noise2) * 0.5 + 0.5;
	
	// Делаем цвет очень темным (от черного до темно-серого)
	// 0.05 - почти черный, 0.25 - темно-серый
	vec3 dark_gray = vec3(0.05);
	vec3 light_gray = vec3(0.25);
	
	vec3 color = mix(dark_gray, light_gray, gray);
	
	// Легкая пульсация яркости
	color += pulse_intensity * sin(time * 2.0);
	
	COLOR = vec4(color, 1.0);
}
