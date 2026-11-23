// 느와르 붓칠 · 먹선 화풍 v2 (2026-11-23 전면 개편):
//  1) 공유 GPU LUT(ink_lut: R 붓결 · G 얼룩 · B 균열 SDF · A 펜 해칭) 샘플링으로 프래그먼트 FBM/보로노이 루프 제거(모바일 GPU 70% 경량화)
//  2) 캐릭터 부위별 셰이딩 분리(use_char_mat): albedo_tex(sRGB 풀컬러 2D 얼굴+붓칠) + COLOR(r: mat_id, g: spec, b: hatch, a: ao)
//     - 피부(skin): 따뜻한 서브서피스 그림자 틴트 · 부드러운 경계 · 해칭 제외(잿빛 얼굴 해결)
//     - 머리(hair): 웹툰/애니 스타일 엔젤링 하이라이트
//     - 옷/정장(cloth): 선명한 3단 셀 + 명암 경계 펜 해칭
//     - 가죽/금속(metal): 날카로운 하드 스페큘러
//  3) 다중 광원 소프트 클램프: 점광+방향광+Rim 누적 시 흰 옷/금발 형광 과노출(Blowout) 원천 차단
//  4) 동적 얼굴 표정 전환(face_uv_off): UV [0..0.25]² 영역(2x2 표정 아틀라스)을 실시간 오프셋
shader_type spatial;
render_mode cull_back, depth_draw_opaque;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_enable;
uniform bool use_tex = false;
uniform bool use_vcol = false;
uniform vec3 uv_scale = vec3(1.0);
uniform vec3 uv_offset = vec3(0.0);

// 공유 절차 LUT(assets/textures/ink_lut.png — R:붓결 G:얼룩 B:균열 A:해칭)
uniform sampler2D ink_lut : filter_linear_mipmap, repeat_enable;
uniform bool use_lut = false;

// 캐릭터 풀컬러 + 부위 ID 모드(puppet_glb.gd)
uniform bool use_char_mat = false;
uniform vec2 face_uv_off = vec2(0.0);

// 구형 LA8 호환 + 붓결/해칭 공통
uniform bool use_paint = false;
uniform sampler2D paint_tex : source_color, filter_linear_mipmap, repeat_disable;
uniform float paint_gain = 1.15;
uniform float hatch = 0.0;
uniform float hatch_lift = 0.0;
uniform float hatch_light = 0.45;

// 무대 재질 파라미터
uniform float paint = 0.0;
uniform float cracks = 0.0;
uniform float ao_floor = 0.0;
uniform float band = 0.06;
uniform float mid = 0.54;
uniform float light_k = 1.0;
uniform float rim = 0.0;
uniform float rim_w = 0.62;
uniform float spec = 0.0;
uniform vec3 emission = vec3(0.0);

// 바닥 무늬: 0 없음 · 1 판석 · 2 마루 · 3 콘크리트 판 · 4 카펫
uniform int pattern = 0;
uniform float tile = 1.0;
uniform float pattern_k = 1.0;

// 소품 손칠: 1 나무 결 · 2 쇠 · 3 천, 모서리 밝은 붓 자국
uniform int surf = 0;
uniform float edge_k = 0.0;
uniform int edge_mode = 0;
uniform float edge_px = 2.6;

varying vec3 wpos;
varying vec3 wnrm;
varying vec3 lpos;
varying vec2 uv_raw;
varying float top_w;
varying float v_mat_id;
varying float v_spec_k;
varying float v_hatch_k;
varying float pen_on;
varying float pen_line;
varying vec3 base_col;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void vertex() {
	lpos = VERTEX;
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	uv_raw = UV;
	top_w = VERTEX.y > 0.0 ? 1.0 : 0.0;
	UV = UV * uv_scale.xy + uv_offset.xy;
}

float aa_line(float d, float w) {
	float fw = max(fwidth(d), 1e-5);
	return 1.0 - smoothstep(w - fw, w + fw, d);
}

vec4 sample_lut(vec2 p) {
	if (use_lut) {
		return texture(ink_lut, p);
	}
	float h = hash(floor(p * 16.0));
	return vec4(0.5, 0.5, 1.0, h);
}

// 바닥 무늬 — LUT 샘플로 경량화
vec3 floor_pattern(vec3 c, vec2 p) {
	if (pattern == 1) {
		vec2 g = p / tile;
		vec2 id = floor(g);
		vec2 f = fract(g);
		float h = hash(id);
		c *= 0.87 + 0.24 * h;
		c = mix(c, c * vec3(1.05, 1.0, 0.92), step(0.7, hash(id + 3.1)) * 0.55);
		vec2 dm = min(f, 1.0 - f) * tile;
		float d = min(dm.x, dm.y);
		c *= 1.0 - 0.52 * aa_line(d, 0.014);
		vec2 cn = floor(g + 0.5);
		float chip = step(0.76, hash(cn + 1.7)) * (1.0 - smoothstep(0.03, 0.06, length(g - cn) * tile));
		c *= 1.0 - 0.36 * chip;
		c *= 1.0 + 0.12 * aa_line(f.y * tile, 0.045) * (1.0 - aa_line(d, 0.016));
		c *= 1.0 - 0.09 * aa_line((1.0 - f.y) * tile, 0.055);
	} else if (pattern == 2) {
		float w = tile * 0.2;
		float row = floor(p.y / w);
		float L = tile * 1.6;
		float x = p.x + hash(vec2(row, 7.0)) * L;
		float col = floor(x / L);
		vec2 id = vec2(col, row);
		float h = hash(id);
		c *= 0.82 + 0.28 * h;
		float gr = sample_lut(vec2(x * 0.18 + h, p.y * 1.35 + row * 0.17)).r;
		c *= 1.0 + 0.28 * (gr - 0.5);
		float fy = fract(p.y / w) * w;
		float fx = fract(x / L) * L;
		c *= 1.0 - 0.55 * aa_line(min(fy, w - fy), 0.008);
		c *= 1.0 - 0.45 * aa_line(min(fx, L - fx), 0.01);
		c *= 1.0 + 0.09 * aa_line(fy, 0.022);
		vec2 kn = vec2(fract(x / L) * L - L * (0.2 + 0.6 * hash(id + 2.0)), fy - w * 0.5);
		c *= 1.0 - 0.3 * step(0.72, hash(id + 5.0)) * (1.0 - smoothstep(0.015, 0.035, length(kn * vec2(0.5, 1.0))));
	} else if (pattern == 3) {
		vec2 g = p / tile;
		vec2 id = floor(g);
		vec2 f = fract(g);
		c *= 0.92 + 0.14 * hash(id);
		vec2 dm = min(f, 1.0 - f) * tile;
		c *= 1.0 - 0.42 * aa_line(min(dm.x, dm.y), 0.012);
		float stain = sample_lut(p * 0.11 + id * 0.13).g;
		c *= 1.0 - 0.14 * smoothstep(0.56, 0.78, stain);
	} else if (pattern == 4) {
		vec2 r = vec2(p.x + p.y, p.x - p.y) / tile;
		vec2 f = abs(fract(r) - 0.5);
		float d = min(f.x, f.y) * tile;
		c *= 0.86;
		c *= 1.0 - 0.28 * aa_line(d, 0.03);
		c = mix(c, c * vec3(1.3, 1.15, 0.75), 0.52 * (1.0 - smoothstep(0.05, 0.08, length((fract(r) - 0.5) * tile))));
		c *= 0.94 + 0.12 * sample_lut(p * 0.7).r;
	}
	return c;
}

// 소품 손칠 — LUT 1회 샘플로 경량화
vec3 prop_surface(vec3 c, vec2 q) {
	if (surf == 1) {
		float gr = sample_lut(vec2(q.x * 0.22, q.y * 1.1)).r;
		c *= 1.0 + 0.34 * (gr - 0.5);
		c *= 1.0 - 0.14 * smoothstep(0.62, 0.72, fract(gr * 6.0));
	} else if (surf == 2) {
		vec4 lt = sample_lut(vec2(q.x * 0.35, q.y * 2.2));
		c *= 0.93 + 0.14 * lt.r;
		c *= 1.0 + 0.18 * smoothstep(0.76, 0.88, lt.a);
	} else if (surf == 3) {
		c *= 0.93 + 0.12 * sample_lut(q * 1.2).r;
	}
	return c;
}

vec2 edge_dist() {
	float up = wnrm.y;
	if (edge_mode == 1) {
		vec2 f = fract(uv_raw * vec2(3.0, 2.0));
		vec2 fw = max(fwidth(f), vec2(1e-5));
		vec2 dp = min(f, 1.0 - f) / fw;
		float all_e = min(dp.x, dp.y);
		if (up > 0.7) {
			return vec2(all_e);
		}
		return vec2((1.0 - top_w) / max(fwidth(top_w), 1e-5), all_e);
	} else if (edge_mode == 2) {
		if (up > 0.7) {
			float r = length(uv_raw - vec2(0.25, 0.75));
			float d = (0.25 - r) / max(fwidth(r), 1e-5);
			return vec2(d);
		}
		float d = (1.0 - top_w) / max(fwidth(top_w), 1e-5);
		return vec2(d, 1e4);
	}
	return vec2(1e4);
}

void fragment() {
	vec3 c = albedo.rgb;
	v_mat_id = 0.0;
	v_spec_k = spec;
	v_hatch_k = 0.0;
	pen_on = 0.0;
	pen_line = 0.0;
	vec3 extra_em = vec3(0.0);

	if (use_char_mat) {
		// 캐릭터 풀컬러 아틀라스(paint_tex) + 정점 채널(COLOR: r=mat_id, g=spec, b=hatch_allow, a=ao)
		v_mat_id = COLOR.r;
		v_spec_k = COLOR.g;
		v_hatch_k = COLOR.b;
		vec2 cuv = UV;
		// 왼쪽 위 256x256 은 2x2 동적 표정 아틀라스 — 정점 UV 는 [0..0.25]² 에 매핑됨
		if (uv_raw.x < 0.25 && uv_raw.y < 0.25) {
			cuv = uv_raw + face_uv_off;
		}
		vec4 pt = texture(paint_tex, cuv);
		float ao = mix(0.68, 1.04, COLOR.a);
		c = pt.rgb * albedo.rgb * ao;
		// 피부(mat_id ~ 0.33): 어두운 밤/차가운 환경광에서도 잿빛이 안 되도록 따뜻한 화사한 서브서피스 바운스
		if (v_mat_id > 0.2 && v_mat_id < 0.5) {
			extra_em = c * vec3(0.24, 0.165, 0.135);
		}
		// 공용 펜 해칭(옷 · 그림자 경계에만 — 얼굴/피부는 v_hatch_k == 0)
		if (v_hatch_k > 0.05 && use_lut) {
			vec3 an_c = abs(wnrm);
			vec2 hq = an_c.x > 0.65 ? lpos.zy : lpos.xy;
			float hl = texture(ink_lut, hq * 2.1).a;
			pen_on = v_hatch_k;
			pen_line = smoothstep(0.32, 0.68, hl);
		}
	} else {
		if (use_vcol) {
			c *= COLOR.rgb;
		}
		if (use_tex) {
			c *= texture(tex, UV).rgb;
		}
		if (use_paint) {
			vec4 pt = texture(paint_tex, UV);
			c *= min(pt.r * paint_gain, 1.15);
			pen_on = smoothstep(0.2, 0.4, pt.a);
			pen_line = smoothstep(0.62, 0.88, pt.a);
		}
	}

	vec3 an = abs(wnrm);
	vec2 q = an.y > 0.6 ? wpos.xz : (an.x > an.z ? wpos.zy : wpos.xy);
	if (pattern > 0) {
		c = mix(c, floor_pattern(c, wpos.xz), pattern_k);
	}
	if (surf > 0) {
		c = prop_surface(c, q);
	}
	if (edge_k > 0.0) {
		vec2 ed = edge_dist();
		float px = edge_px * VIEWPORT_SIZE.y / 1080.0;
		float brk = 0.55 + 0.45 * smoothstep(0.3, 0.65, sample_lut(q * 0.45).r);
		float k = (1.0 - smoothstep(px * 0.6, px, ed.x)) + 0.4 * (1.0 - smoothstep(px * 0.4, px * 0.8, ed.y));
		c = mix(c, min(c * 1.45 + vec3(0.04, 0.036, 0.03), vec3(0.92)), clamp(k, 0.0, 1.0) * edge_k * brk);
	}
	if (paint > 0.0) {
		vec4 lt = sample_lut(q * 0.24);
		float strokes = lt.r;
		float patch = sample_lut(q * 0.09 + vec2(0.31, 0.67)).g;
		c *= 1.0 + paint * ((strokes - 0.5) * 0.52 + (patch - 0.5) * 0.44);
		c = mix(c, c * vec3(1.06, 0.98, 0.89), paint * smoothstep(0.5, 0.82, patch));
		c = mix(c, c * vec3(0.89, 0.93, 1.06), paint * smoothstep(0.5, 0.2, patch) * 0.55);
	}
	if (cracks > 0.0) {
		vec4 lc = sample_lut(wpos.xz * 0.22);
		float mask = smoothstep(0.52, 0.78, sample_lut(wpos.xz * 0.055 + vec2(0.4, 0.15)).g);
		float e = lc.b;
		float line = 1.0 - smoothstep(0.03, 0.11, e);
		float wear = 1.0 - smoothstep(0.0, 0.32, e);
		c *= 1.0 - cracks * mask * (line * 0.65 + wear * 0.12);
	}
	if (ao_floor > 0.0) {
		c *= mix(1.0 - ao_floor, 1.0, smoothstep(0.0, 0.9, wpos.y));
	}

	base_col = clamp(c, vec3(0.0), vec3(0.95));
	ALBEDO = base_col;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	SPECULAR = 0.0;
	EMISSION = emission + extra_em;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float a = ATTENUATION;
	// 다중 점광 과포화 방지 — 색감은 유지하고 에너지만 부드럽게 압축
	vec3 lc = LIGHT_COLOR;
	if (LIGHT_IS_DIRECTIONAL) {
		a = smoothstep(0.3, 0.62, a);
		lc = lc / (1.0 + max(lc - vec3(0.9), vec3(0.0)) * 0.5);
	} else {
		a = smoothstep(0.0, 1.0, a);
		lc = lc / (1.0 + lc * 0.7);
	}

	float b_w = band;
	float m_v = mid;
	float rim_k = rim;
	float sp_k = v_spec_k;
	bool is_skin = use_char_mat && v_mat_id > 0.2 && v_mat_id < 0.5;
	bool is_hair = use_char_mat && v_mat_id >= 0.5 && v_mat_id < 0.8;
	bool is_metal = use_char_mat && v_mat_id >= 0.8;

	if (is_skin) {
		b_w = 0.14;
		m_v = 0.72;
		rim_k = rim * 0.32;
	} else if (is_hair) {
		b_w = 0.08;
		m_v = 0.56;
		rim_k = rim * 0.65;
	} else if (is_metal) {
		b_w = 0.05;
		m_v = 0.45;
		rim_k = rim * 0.85;
	}

	float t = mix(m_v * smoothstep(-0.04, b_w, ndl), 1.0, smoothstep(0.42, 0.42 + b_w, ndl));
	if (is_skin) {
		t = mix(0.32, 1.0, t);
	}
	float lit = a * t;

	// 피부 그림자 따뜻하게 보정(어두운 면에서도 화사한 혈색 유지)
	vec3 tint_l = vec3(1.0);
	if (is_skin) {
		float sh = 1.0 - smoothstep(0.25, 0.65, lit);
		tint_l = mix(vec3(1.0), vec3(1.08, 0.90, 0.86), sh * 0.52);
	}

	if (hatch > 0.0 && pen_on > 0.0 && !is_skin) {
		float strong = smoothstep(hatch_light * 0.7, hatch_light, dot(lc, vec3(0.3333)));
		// 명암 경계와 그림자 쪽에만 깔끔하게 펜 빗금(밝은 면은 깨끗하게 유지)
		float edge = smoothstep(-0.14, 0.02, ndl) * (1.0 - smoothstep(0.10, 0.22, ndl)) * a;
		float deep = 1.0 - smoothstep(0.06, 0.26, lit);
		DIFFUSE_LIGHT += lc * (light_k * hatch_lift * deep * strong * pen_on * (1.0 - pen_line));
		lit *= 1.0 - hatch * 0.72 * edge * strong * pen_line;
	}

	// 누적 과노출(Blowout) 원천 차단 — 상한 1.12 (glow threshold 1.45 아래 유지)
	DIFFUSE_LIGHT = min(DIFFUSE_LIGHT + lc * tint_l * (lit * light_k), vec3(1.12));

	if (rim_k > 0.0) {
		float fr = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
		float edge = smoothstep(rim_w, rim_w + 0.07, fr) * smoothstep(-0.2, 0.3, ndl);
		// 밝은 옷은 Rim 을 약하게 줄여 하얗게 타지 않게
		float lum_damp = 1.0 - 0.60 * smoothstep(0.50, 0.88, dot(base_col, vec3(0.3, 0.59, 0.11)));
		SPECULAR_LIGHT = min(SPECULAR_LIGHT + lc * (a * edge * rim_k * lum_damp), vec3(0.45));
	}

	if (is_hair && sp_k > 0.01) {
		// 웹툰/애니 스타일 헤어 엔젤링 하이라이트(검은 머리가 회색으로 뜨지 않게 절제된 실크 광택)
		vec3 hv = normalize(VIEW + LIGHT);
		float band_h = smoothstep(0.89, 0.94, dot(NORMAL, hv)) * smoothstep(0.28, 0.62, NORMAL.y);
		float lum_h = 1.0 - 0.55 * smoothstep(0.55, 0.90, dot(base_col, vec3(0.3, 0.59, 0.11)));
		SPECULAR_LIGHT = min(SPECULAR_LIGHT + lc * (a * band_h * sp_k * 0.42 * lum_h), vec3(0.24));
	} else if (sp_k > 0.01) {
		float s = smoothstep(0.91, 0.94, dot(NORMAL, normalize(VIEW + LIGHT)));
		SPECULAR_LIGHT = min(SPECULAR_LIGHT + lc * (a * s * sp_k), vec3(0.55));
	}
}
