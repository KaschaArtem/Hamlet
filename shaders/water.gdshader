shader_type spatial;
render_mode blend_mix, depth_draw_always, world_vertex_coords;

uniform vec4 water_color : source_color = vec4(0.0, 0.2, 0.6, 1.0);
uniform float night_fill : hint_range(0.0, 1.0) = 0.0;

uniform sampler2D wave_noise_tex : hint_default_black, repeat_enable; // Добавлено repeat_enable
uniform float wave_amplitude : hint_range(0.01, 5.0) = 1.0;
uniform float wave_frequency : hint_range(0.01, 1.0) = 0.1;
uniform float wave_speed : hint_range(0.1, 5.0) = 0.5;

uniform float facet_variation : hint_range(0.0, 0.5) = 0.1;

varying vec3 v_world_pos;

float hash(vec3 p) {
    p = fract(p * 0.1031);
    p += dot(p, p.yzx + 33.33);
    return fract((p.x + p.y) * p.z);
}

float generateYOffset(vec3 vertex, float time) {
    vec2 uv1 = vertex.xz * wave_frequency + (time * wave_speed * 0.1);
    float n1 = textureLod(wave_noise_tex, uv1, 0.0).r;
    
    vec2 uv2 = vertex.xz * (wave_frequency * 0.73) - (time * wave_speed * 0.07);
    float n2 = textureLod(wave_noise_tex, uv2 + vec2(0.5, 0.2), 0.0).r;
    
    vec2 uv3 = vertex.xz * (wave_frequency * 0.21) + (time * wave_speed * 0.02);
    float n3 = textureLod(wave_noise_tex, uv3, 0.0).r;
    
    float combined_noise = (n1 * 0.5) + (n2 * 0.3) + (n3 * 0.2);
    
    return (combined_noise - 0.5) * wave_amplitude * 2.0;
}

void vertex() {
    VERTEX.y += generateYOffset(VERTEX, TIME);
    v_world_pos = VERTEX;
}

void fragment() {
	vec3 lp_normal = normalize(cross(dFdx(VERTEX), dFdy(VERTEX)));
	NORMAL = lp_normal;

	vec3 face_id = floor(v_world_pos * 3.0); 
	float height_factor = clamp(v_world_pos.y * 0.2, -0.1, 0.1);
	float color_mod = (hash(face_id) - 0.5) * facet_variation + height_factor;

	vec3 final_color = water_color.rgb + color_mod;
	ALBEDO = final_color;
	
	EMISSION = final_color * night_fill * 0.2; 

	ROUGHNESS = 0.1;
	METALLIC = 0.05;
	SPECULAR = 0.5;
	ALPHA = water_color.a;
}