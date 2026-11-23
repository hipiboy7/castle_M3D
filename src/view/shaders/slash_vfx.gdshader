// 웹툰 붓칠 · 먹선 칼 궤적 셰이더(Hades + 캐슬 느와르 스타일):
// UV.x = 궤적 진행(0 꼬리 → 1 날끝), UV.y = 띠 폭(0 안쪽 → 1 바깥 날끝)
// 안쪽 짙은 먹선 심(ink core) + 날카로운 붓끝 갈라짐(dry brush) + 바깥 발광 날
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 blade_col : source_color = vec4(0.82, 0.92, 1.0, 1.0);
uniform vec4 ink_col : source_color = vec4(0.05, 0.03, 0.08, 1.0);
uniform float fade = 1.0;
uniform sampler2D ink_lut : filter_linear_mipmap, repeat_enable;

void fragment() {
	float u = UV.x;
	float v = UV.y;
	// 붓끝 갈라짐(dry brush)
	float brush = texture(ink_lut, vec2(u * 2.4, v * 1.4)).r;
	float head_taper = smoothstep(0.0, 0.14, 1.0 - u) * smoothstep(0.0, 0.25, u);
	float tail_cut = smoothstep(0.06, 0.85, u);
	float edge_w = smoothstep(0.0, 0.22 + (1.0 - brush) * 0.25, v) * smoothstep(1.0, 0.78, v);
	float alpha = head_taper * tail_cut * edge_w * fade;
	// 바깥 날은 밝은 발광 색, 안쪽 띠는 진한 먹선(웹툰 베기 맛)
	float bright_edge = smoothstep(0.45, 0.88, v);
	float ink_core = smoothstep(0.12, 0.42, v) * (1.0 - smoothstep(0.50, 0.78, v));
	vec3 c = mix(ink_col.rgb, blade_col.rgb * 1.45, bright_edge);
	c = mix(c, ink_col.rgb, ink_core * 0.65);
	ALBEDO = c;
	ALPHA = clamp(alpha * 1.15, 0.0, 0.95);
}
