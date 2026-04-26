// Wirkung: Schraffiert jede Seite der Objekt-Boundingbox (anhand der
//   dominierenden Achse der interpolierten Weltnormalen) mit blauen
//   1-Pixel-Linien im 5-Pixel-Screenspace-Raster. Pro BB-Seite wird eine
//   andere Winkelrichtung gewählt, sodass benachbarte Flächen
//   unterscheidbar bleiben. Unshaded; Nicht-Linien-Fragmente werden
//   verworfen, damit die darunterliegende Originaltextur sichtbar
//   bleibt.
shader_type spatial;
render_mode unshaded, cull_back, depth_draw_never, blend_mix;

uniform vec4 line_color : source_color = vec4(0.25, 0.55, 1.0, 1.0);
uniform float line_spacing = 5.0;
uniform float line_width = 1.0;
uniform float noise_scale = 0.035;
uniform float noise_amplitude = 2.5;
uniform float noise_speed = 0.6;
uniform float real_time = 0.0;

varying vec3 v_world_normal;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

void vertex() {
    v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
    vec3 n = normalize(v_world_normal);
    vec3 a = abs(n);

    float angle;
    if (a.x >= a.y && a.x >= a.z) {
        angle = n.x > 0.0 ? radians(30.0) : radians(150.0);
    } else if (a.y >= a.z) {
        angle = n.y > 0.0 ? radians(60.0) : radians(120.0);
    } else {
        angle = n.z > 0.0 ? radians(45.0) : radians(135.0);
    }

    float c = cos(angle);
    float s = sin(angle);
    vec2 sample_pos = FRAGCOORD.xy * noise_scale + vec2(real_time * noise_speed, real_time * noise_speed * 0.7);
    float wobble = (value_noise(sample_pos) - 0.5) * 2.0 * noise_amplitude;

    float projected = FRAGCOORD.x * c + FRAGCOORD.y * s + wobble;
    float m = mod(projected, line_spacing);
    if (m >= line_width) {
        discard;
    }

    ALBEDO = line_color.rgb;
    EMISSION = line_color.rgb * 0.6;
    ALPHA = line_color.a;
}
