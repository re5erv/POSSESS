shader_type canvas_item;

group_uniforms Drip_Settings;
// Цвет подтёков — поставьте точно такой же, как у ваших букв
uniform vec4 drip_color : source_color = vec4(0.85, 0.05, 0.05, 1.0);
uniform float column_count : hint_range(10.0, 120.0) = 45.0;         // Частота струек (плотность сетки)
uniform float drip_chance : hint_range(0.0, 1.0) = 0.4;              // Шанс появления струи под буквой
uniform float min_drip_length : hint_range(0.0, 0.3) = 0.03;         // Минимальная длина струйки
uniform float max_drip_length : hint_range(0.01, 0.6) = 0.22;        // Максимальная длина струйки
uniform float stream_thickness : hint_range(0.05, 0.5) = 0.15;       // Толщина нити (чем меньше, тем тоньше)
uniform float drop_size : hint_range(0.0, 2.5) = 1.2;                // Размер круглой капельки на самом конце
uniform float anim_speed : hint_range(0.0, 5.0) = 0.0;               // Скорость движения (0.0 — статичные как на скрине, >0 — живые)

float hash(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    // Если в текущем пикселе уже нарисована сама буква — рисуем её без изменений
    if (tex.a > 0.4) {
        COLOR = tex;
    } else {
        // Делим пространство на отдельные вертикальные колонки
        float col_id = floor(UV.x * column_count);
        float rnd = hash(col_id);
        float rnd2 = hash(col_id + 77.13);

        // Рисуем подтёк, только если колонка выбрана генератором случайных чисел
        if (rnd < drip_chance) {
            float col_fract = fract(UV.x * column_count);
            float dist_x = abs(col_fract - 0.5); // Расстояние от оси струи

            // Анимация: если anim_speed > 0, длина струек плавно «дышит»
            float anim = (anim_speed > 0.0) ? (0.85 + 0.15 * sin(TIME * anim_speed * (1.0 + rnd2) + rnd * 6.28)) : 1.0;
            float target_len = mix(min_drip_length, max_drip_length, rnd2) * anim;

            // Ищем нижний край текста строго над текущей точкой
            float hit_dist = -1.0;
            const int SAMPLES = 30;
            for (int i = 1; i <= SAMPLES; i++) {
                float check_offset = (float(i) / float(SAMPLES)) * target_len;
                vec2 check_uv = UV - vec2(0.0, check_offset);

                if (check_uv.y < 0.0) break;

                // Наткнулись на непрозрачный пиксель буквы выше нас
                if (texture(TEXTURE, check_uv).a > 0.4) {
                    hit_dist = check_offset;
                    break;
                }
            }

            // Если прямо над текущей точкой есть буква в пределах target_len
            if (hit_dist > 0.0) {
                // 1. Прямая тонкая вертикальная струйка
                bool is_stream = dist_x < (stream_thickness * 0.5);

                // 2. Округлая капелька на самом нижнем кончике
                float tip_dist_y = abs(hit_dist - target_len);
                float drop_dist = length(vec2(dist_x, tip_dist_y * column_count));
                bool is_drop = (drop_size > 0.0) && (drop_dist < (stream_thickness * drop_size));

                if (is_stream || is_drop) {
                    COLOR = drip_color;
                } else {
                    COLOR = vec4(0.0);
                }
            } else {
                COLOR = vec4(0.0);
            }
        } else {
            COLOR = vec4(0.0);
        }
    }
}
