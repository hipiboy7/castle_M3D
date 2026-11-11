// 먹선(바깥 윤곽) — 뒷면을 화면 픽셀 너비만큼 바깥으로 민 껍데기(뒤집은 껍질). 화면 높이 1080 기준 width 픽셀(큰 화면은 그 비율로 굵게).
// pos_dir 1: 면마다 법선이 갈라진 상자 · 원기둥은 꼭짓점 방향(가운데에서 바깥)으로 밀어 모서리가 끊기지 않게. 메시 하나에 material_overlay 로 붙인다(ink.gd).
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque, shadows_disabled, fog_disabled;

uniform vec4 ink : source_color = vec4(0.045, 0.03, 0.055, 1.0);
uniform float width = 2.0;
uniform float pos_dir = 0.0;

void vertex() {
	vec3 dir = NORMAL;
	if (pos_dir > 0.5 && length(VERTEX) > 0.0001) {
		dir = normalize(VERTEX);
	}
	vec4 clip = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	vec3 vn = mat3(MODELVIEW_MATRIX) * dir;
	vec2 sn = (PROJECTION_MATRIX * vec4(vn, 0.0)).xy;
	float l = length(sn);
	if (l > 0.00001) {
		float px = width * VIEWPORT_SIZE.y / 1080.0;
		clip.xy += (sn / l) * (vec2(2.0) / VIEWPORT_SIZE) * px * clip.w;
	}
	POSITION = clip;
}

void fragment() {
	ALBEDO = ink.rgb;
}
