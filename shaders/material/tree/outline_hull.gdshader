shader_type spatial;

// render_mode прописывает настройки материала прямо в коде:
// blend_mix - включает прозрачность (чтобы работал ALPHA)
// depth_test_disabled - рисует обводку ПОВЕРХ других объектов (опционально)
// cull_disabled - рисует обе стороны полигонов (на всякий случай)
// unshaded - отключает влияние света (обводка будет ярко-зеленой всегда)
render_mode blend_mix, cull_disabled, unshaded;

uniform vec3 outline_color : source_color = vec3(0.0, 1.0, 0.0);
uniform float width : hint_range(0.0, 0.5) = 0.05;

void vertex() {
	// Приподнимаем вершины вдоль нормалей, чтобы избежать мерцания (Z-fighting)
	// Если 0.01 мало, попробуй 0.02
	VERTEX += NORMAL * 0.01;
}

void fragment() {
	vec2 uv = UV;
	
	// Логика рамки по UV-координатам
	float h = step(width, uv.x) * step(width, 1.0 - uv.x);
	float v = step(width, uv.y) * step(width, 1.0 - uv.y);
	float mask = 1.0 - (h * v);

	// Если мы не на краю (в центре тайла) — полностью убираем пиксель
	if (mask < 0.5) {
		discard;
	}

	ALBEDO = outline_color;
	// ALPHA делает края плавными, если нужно, но в режиме discard достаточно этого
	ALPHA = 1.0; 
}