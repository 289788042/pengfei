shader_type canvas_item;

// 扫光位置 0~1，从左到右
uniform float sweep_pos : hint_range(0.0, 1.0) = 0.0;
// 扫光宽度
uniform float sweep_width : hint_range(0.01, 0.6) = 0.2;
// 高亮颜色
uniform vec3 glow_color : source_color = vec3(0.7, 0.95, 1.0);
// 高亮强度
uniform float glow_strength : hint_range(0.0, 3.0) = 2.0;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	
	// 只对有内容的像素发光（透明背景不受影响）
	float content_alpha = col.a;
	float glow = 0.0;
	if (content_alpha > 0.01) {
		float dist = abs(UV.x - sweep_pos);
		glow = (1.0 - smoothstep(0.0, sweep_width, dist)) * glow_strength;
		col.rgb += glow_color * glow * content_alpha;
		col.rgb += col.rgb * glow * 0.5;
	}
	
	COLOR = col;
}
