shader_type canvas_item;

group_uniforms Drip_Settings;
uniform vec4 drip_color : source_color = vec4(0.85, 0.05, 0.05, 1.0);
uniform float column_count : hint_range(10.0, 100.0) = 42.0;       // Частота линий
uniform float drip_chance : hint_range(0.0, 1.0) = 0.45;           // Сколько капель течет
uniform float min_drip_length : hint_range(0.0, 0.4) = 0.05;       // Минимальная длина
uniform float max_drip_length : hint_range(0.01, 0.6) = 0.22;      // Максимальная длина
uniform float stream_width : hint_range(0.05, 0.6) = 0.18;         // Толщина струйки
uniform float root_spread : hint_range(0.0, 3.0) = 1.6;            // Наплыв сверху у буквы

float hash(float p) {
    p = fract(p * 0.1031);
    p *= p + 33.33;
    p *= p + p;
    return fract(p);
}

void fragment() {
    vec4 tex = texture(TEXTURE, UV);

    if (tex.a > 0.3) {
        COLOR = tex;
    } else {
        float col_id = floor(UV.x * column_count);
        float rnd = hash(col_id);
        float rnd2 = hash(col_id + 42.17);

        if (rnd < drip_chance) {
            float col_center = (col_id + 0.5) / column_count;
            float dist_x = abs(UV.x - col_center) * column_count;

            float target_len = mix(min_drip_length, max_drip_length, rnd2);

            float hit_dist = -1.0;
            const int SAMPLES = 32;
            for (int i = 1; i <= SAMPLES; i++) {
                float check_offset = (float(i) / float(SAMPLES)) * target_len;
                vec2 check_uv = UV - vec2(0.0, check_offset);

                if (check_uv.y < 0.0) break;

                if (texture(TEXTURE, check_uv).a > 0.3) {
                    hit_dist = check_offset;
                    break;
                }
            }

            if (hit_dist > 0.0) {
                // progress: 0.0 у буквы, 1.0 на самом нижнем конце
                float progress = clamp(hit_dist / target_len, 0.0, 1.0);

                // Наплыв ТОЛЬКО сверху у основания буквы, сужается книзу в ровную пиксельную струйку
                float root_w = smoothstep(0.4, 0.0, progress) * (stream_width * root_spread);

                // Итоговая ширина: сверху широко, книзу ровно/сужается (никаких шариков снизу)
                float current_half_w = (stream_width + root_w) * 0.5;

                if (dist_x < current_half_w) {
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
