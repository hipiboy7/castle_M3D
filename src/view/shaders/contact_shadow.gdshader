// 발밑 콘택트 섀도 — 캐릭터/소품의 바닥 접지감(그림자 패스 비용 없음)
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform vec4 col : source_color = vec4(0.03, 0.02, 0.05, 0.44);

void fragment() {
	float r = length(UV * 2.0 - 1.0);
	float a = (1.0 - smoothstep(0.16, 0.96, r)) * col.a;
	ALBEDO = col.rgb;
	ALPHA = a;
}
