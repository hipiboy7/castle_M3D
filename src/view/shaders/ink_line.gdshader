// 먹선(바깥 윤곽) v2 — 거리 적응형 화면 픽셀 먹선 + 부위별 컬러드 잉크(피부/금발은 따뜻한 다크 세피아, 정장은 짙은 보라먹).
// pos_dir 1: 면마다 법선이 갈라진 상자 · 원기둥은 꼭짓점 방향으로 밀어 모서리가 끊기지 않게.
shader_type spatial;
render_mode unshaded, cull_front, depth_draw_opaque, shadows_disabled, fog_disabled;

uniform vec4 ink : source_color = vec4(0.045, 0.03, 0.055, 1.0);
uniform float width = 2.0;
uniform float pos_dir = 0.0;
uniform bool use_char_tint = false;

varying vec3 v_ink;

void vertex() {
	vec3 dir = NORMAL;
	if (pos_dir > 0.5 && length(VERTEX) > 0.0001) {
		dir = normalize(VERTEX);
	}
	vec4 view_pos = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	vec4 clip = PROJECTION_MATRIX * view_pos;
	vec3 vn = mat3(MODELVIEW_MATRIX) * dir;
	vec2 sn = (PROJECTION_MATRIX * vec4(vn, 0.0)).xy;
	float l = length(sn);
	if (l > 0.00001) {
		// 멀어질수록 먹선을 살짝 줄여 엑스트라 군중이 검은 먹 덩어리가 되는 현상 방지
		float dist = max(-view_pos.z, 1.0);
		float dist_k = clamp(15.5 / dist, 0.62, 1.15);
		float px = width * dist_k * VIEWPORT_SIZE.y / 1080.0;
		clip.xy += (sn / l) * (vec2(2.0) / VIEWPORT_SIZE) * px * clip.w;
	}
	POSITION = clip;
	v_ink = ink.rgb;
	if (use_char_tint) {
		// COLOR.r: 0.33 피부 · 0.66 머리 → 따뜻한 다크 세피아로 부드럽게, 옷/정장은 짙은 보라먹
		if (COLOR.r > 0.2 && COLOR.r < 0.5) {
			v_ink = vec3(0.14, 0.075, 0.07);
		} else if (COLOR.r >= 0.5 && COLOR.r < 0.8) {
			v_ink = vec3(0.08, 0.05, 0.055);
		}
	}
}

void fragment() {
	ALBEDO = v_ink;
}
