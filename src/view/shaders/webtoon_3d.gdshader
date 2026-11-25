// 3단계 로컬 만화/웹툰 3D 전용 셰이더(정연 「캐슬」 느와르 웹툰 화풍 — Guilty Gear / Solo Leveling 스타일).
//  - mat_kind: 0 의상(2.5단 셀 + 그림자 경계 펜 해칭 + 실루엣 림) · 1 원작 얼굴/피부(평면 핵심광 유지로 원작 선화 100% 보존)
//              2 조각 만화 헤어(하드 셀 + 크라운 엔젤링 하이라이트) · 3 안경 글린트(백도찬 흰 반사 / 서진태 노란 선글라스)
//              4 가죽/금속(선명한 하드 스페큘러 — 홀스터 · 벨트 · 구두)
shader_type spatial;
render_mode cull_back, depth_draw_opaque;

uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_enable;
uniform bool use_tex = true;
uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D ink_lut : filter_linear_mipmap, repeat_enable;
uniform bool use_lut = true;
uniform int mat_kind = 0;
uniform vec3 emission = vec3(0.0);

varying vec3 lpos;
varying vec3 wnrm;
varying vec3 base_col;

void vertex() {
	lpos = VERTEX;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 c = albedo.rgb;
	if (use_tex) {
		c *= texture(tex, UV).rgb;
	}
	base_col = clamp(c, vec3(0.0), vec3(0.96));
	ALBEDO = base_col;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	SPECULAR = 0.0;
	vec3 extra_em = vec3(0.0);
	if (mat_kind == 1) {
		// 원작 정연 얼굴 선화 · 피부 혈색이 밤/주점 조명에서도 어둡거나 잿빛이 되지 않도록 온화한 셀 자가보정
		extra_em = base_col * vec3(0.28, 0.24, 0.22);
	} else if (mat_kind == 3) {
		// 백도찬 빛나는 사각 안경 / 서진태 노란 선글라스 — 만화 특유의 선명한 글린트(블룸 1.45 이하 유지)
		extra_em = base_col * 0.95;
	} else if (mat_kind == 2) {
		extra_em = base_col * 0.04;
	}
	EMISSION = emission + extra_em;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float a = ATTENUATION;
	vec3 lc = LIGHT_COLOR;
	if (LIGHT_IS_DIRECTIONAL) {
		a = smoothstep(0.28, 0.58, a);
		lc = lc / (1.0 + max(lc - vec3(0.9), vec3(0.0)) * 0.55);
	} else {
		a = smoothstep(0.0, 1.0, a);
		lc = lc / (1.0 + lc * 0.72);
	}

	if (mat_kind == 3) {
		DIFFUSE_LIGHT = min(DIFFUSE_LIGHT + lc * (0.25 * a), vec3(1.15));
	} else if (mat_kind == 1) {
		// 얼굴/피부: 부드러운 웹툰 키라이트 — 원작 눈·코·입·흉터 선화를 망가뜨리는 거친 3D 음영 제거
		float t = mix(0.62, 1.0, smoothstep(-0.18, 0.16, ndl));
		float lit = mix(0.56, 1.0, a * t);
		vec3 warm = mix(vec3(1.06, 0.94, 0.90), vec3(1.0), smoothstep(0.55, 0.90, lit));
		DIFFUSE_LIGHT = min(DIFFUSE_LIGHT + lc * warm * (lit * 0.88), vec3(1.06));
	} else {
		// 의상 · 헤어 · 가죽: 선명한 2.5단 느와르 셀 셰이딩
		float band_w = (mat_kind == 2) ? 0.06 : 0.05;
		float mid_v = (mat_kind == 4) ? 0.44 : 0.52;
		float t = mix(mid_v * smoothstep(-0.08, band_w, ndl), 1.0, smoothstep(0.36, 0.36 + band_w, ndl));
		t = mix(0.30, 1.0, t);
		float lit = a * t;

		// 그림자 경계 웹툰 펜 해칭(의상만 — 정연 특유의 먹선 음영)
		if (mat_kind == 0 && use_lut) {
			vec3 an = abs(wnrm);
			vec2 hq = an.x > 0.65 ? lpos.zy : lpos.xy;
			float hl = smoothstep(0.34, 0.66, texture(ink_lut, hq * 2.4).a);
			float edge = smoothstep(-0.16, 0.04, ndl) * (1.0 - smoothstep(0.12, 0.24, ndl)) * a;
			lit *= 1.0 - 0.40 * edge * hl;
		}
		DIFFUSE_LIGHT = min(DIFFUSE_LIGHT + lc * lit, vec3(1.12));

		// 만화 실루엣 림 라이트(배경에서 인물 윤곽을 또렷하게 분리 — 어두운 머리가 회색이 되지 않게 억제)
		float fr = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
		float rim_k = (mat_kind == 2) ? 0.16 : ((mat_kind == 4) ? 0.42 : 0.28);
		float rim_edge = smoothstep(0.66, 0.74, fr) * smoothstep(-0.20, 0.35, ndl);
		float lum_damp = 1.0 - 0.55 * smoothstep(0.55, 0.90, dot(base_col, vec3(0.3, 0.59, 0.11)));
		SPECULAR_LIGHT = min(SPECULAR_LIGHT + lc * (a * rim_edge * rim_k * lum_damp), vec3(0.32));

		// 헤어 만화 엔젤링(가로 리본 광택 — 동그란 플라스틱 점 방지) · 가죽 하드 스페큘러
		if (mat_kind == 2) {
			vec3 hdir = normalize(LIGHT + VIEW);
			float ndh = max(dot(NORMAL, hdir), 0.0);
			float band_y = 1.0 - smoothstep(0.06, 0.20, abs(wnrm.y - 0.56));
			float sp = smoothstep(0.76, 0.88, ndh) * band_y * 0.14;
			vec3 sp_tint = mix(base_col * 1.4, vec3(0.90, 0.92, 0.98), 0.35);
			SPECULAR_LIGHT = min(SPECULAR_LIGHT + lc * sp_tint * (a * sp), vec3(0.22));
		} else if (mat_kind == 4) {
			vec3 hdir = normalize(LIGHT + VIEW);
			float ndh = max(dot(NORMAL, hdir), 0.0);
			float sp = smoothstep(0.88, 0.93, ndh) * 0.44;
			SPECULAR_LIGHT = min(SPECULAR_LIGHT + lc * (a * sp), vec3(0.38));
		}
	}
}
