shader_type spatial;
render_mode blend_mix, depth_draw_always, world_vertex_coords;

uniform vec4 water_color : source_color = vec4(0.0, 0.2, 0.6, 1.0);

// --- ПАРАМЕТРЫ ВОЛН ---
uniform sampler2D wave_noise_tex : hint_default_black; 
uniform float wave_amplitude : hint_range(0.01, 5.0) = 1.0;
uniform float wave_frequency : hint_range(0.01, 1.0) = 0.1;
uniform float wave_speed : hint_range(0.1, 5.0) = 0.5;

// --- ВИЗУАЛЬНЫЕ ЭФФЕКТЫ ---
uniform float facet_variation : hint_range(0.0, 0.5) = 0.1; // Вариация яркости граней

varying vec3 v_world_pos;

// Функция для создания стабильного случайного числа для каждой грани
float hash(vec3 p) {
	p = fract(p * 0.1031);
	p += dot(p, p.yzx + 33.33);
	return fract((p.x + p.y) * p.z);
}

float generateYOffset(vec3 vertex, float time) {
	// Слой 1: Основная детализация
	vec2 uv1 = vertex.xz * wave_frequency + (time * wave_speed * 0.1);
	float n1 = textureLod(wave_noise_tex, uv1, 0.0).r;
	
	// Слой 2: Крупное смещение для уникальности тайлов
	vec2 uv2 = vertex.xz * (wave_frequency * 0.3) - (time * wave_speed * 0.04);
	float n2 = textureLod(wave_noise_tex, uv2, 0.0).r;
	
	float combined_noise = mix(n1, n2, 0.5);
	return (combined_noise - 0.5) * wave_amplitude * 2.0;
}

void vertex() {
	VERTEX.y += generateYOffset(VERTEX, TIME);
	v_world_pos = VERTEX;
}

void fragment() {
	// 1. Создаем эффект плоских граней через нормали
	vec3 lp_normal = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
	NORMAL = lp_normal;

	// 2. Вариация цвета (делает треугольники выразительными)
	// floor помогает зафиксировать цвет за конкретным треугольником
	vec3 face_id = floor(v_world_pos * 2.0); 
	float color_mod = (hash(face_id) - 0.5) * facet_variation;

	// 3. Итоговый цвет и физические параметры
	ALBEDO = water_color.rgb + color_mod;
	
	ROUGHNESS = 0.15; // Глянцевая поверхность
	METALLIC = 0.1;
	SPECULAR = 0.5;
	ALPHA = water_color.a;
}