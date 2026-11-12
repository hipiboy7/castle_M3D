// 붓칠 · 먹선 화풍(2026-11-11 사용자 "Hades의 모습을 베껴서") — 셀 명암 바탕 셰이더. 무대 소품 · 바닥 · 인물이 같이 쓴다(src/view/ink.gd).
// 빛: 그림자 · 중간 · 밝은 면 세 단으로 딱 끊고(그러데이션 없음), 해 그림자도 경계를 세운다. 빛을 받는 쪽 실루엣에 그 빛 색의 굵은 테두리 빛.
// 바탕색: 세계 좌표 잡음으로 붓 결(paint) · 큰 얼룩 · 바닥 금(cracks) · 아래쪽 그늘(ao_floor). 그림자 색은 환경광(ink.gd 가 차갑게 민다).
shader_type spatial;
render_mode cull_back, depth_draw_opaque;

uniform vec4 albedo : source_color = vec4(1.0);
uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_enable;
uniform bool use_tex = false;
uniform bool use_vcol = false;
uniform vec3 uv_scale = vec3(1.0);
uniform vec3 uv_offset = vec3(0.0);
uniform float paint = 0.0;          // 붓 결 · 얼룩 세기(0 = 민 색)
uniform float cracks = 0.0;         // 바닥 금 · 닳은 자국
uniform float ao_floor = 0.0;       // 바닥에 가까울수록 어둡게(벽 · 기둥 밑동)
uniform float band = 0.05;          // 명암 경계 너비(작을수록 딱 끊긴다)
uniform float mid = 0.55;           // 중간 단 밝기(0 ~ 1)
uniform float light_k = 1.0;        // 빛 세기 맞춤
uniform float rim = 0.0;            // 테두리 빛 세기(인물 · 무기)
uniform float rim_w = 0.6;          // 테두리 빛 시작(1 - N·V)
uniform float spec = 0.0;           // 딱 끊긴 반사광(쇠 · 가죽 · 머리)
uniform vec3 emission = vec3(0.0);  // 맞음 번쩍임 · 엇엇박 달아오름(puppet_pose _update_flash)
// 인물 그림(그림 A GLB 에 든 회색 그림 — tools/make_models.gd ③): 붓 결 · 얼룩 · 머리털 가닥 · 가죽 광 · 오목한 데 빗금. 값 × paint_gain 을 곱한다
uniform bool use_paint = false;
uniform sampler2D paint_tex : filter_linear_mipmap, repeat_disable;
uniform float paint_gain = 1.3;
// 빛 빗금(펜 해칭 — 원작 웹툰의 명암 경계 · 그림자 빗금): 그림의 A 채널에 손으로 그은 선(떨림 · 끊김 — make_models _hatch · 머리는 가닥 결).
// A 0 = 빗금 없음(살 · 얼굴), 0.5 = 선 사이, 1 = 선. hatch = 중간 단에서 선 자리를 어둡게, hatch_lift = 그림자 쪽 선 사이를 밝혀 선이 드러나게
uniform float hatch = 0.0;
uniform float hatch_lift = 0.0;
uniform float hatch_light = 0.45;   // 이 밝기(빛 색 × 세기 평균) 이상인 빛만 빗금을 긋는다
// 화풍 3단계(2026-11-12 — 무대 소품 · 바닥 무늬, ink.gd 가 정한다). 바닥 무늬 pattern: 0 없음 · 1 판석(tiles) · 2 마루(planks) ·
// 3 콘크리트 판(slabs) · 4 카펫(carpet) — 세계 좌표 xz, 칸 크기 tile(m). 줄눈은 화면 픽셀로 부드럽게(fwidth — 멀리서 반짝이지 않게)
uniform int pattern = 0;
uniform float tile = 1.0;
uniform float pattern_k = 1.0;
// 소품 손칠: surf 1 나무 결 · 2 쇠(긁힘 · 결) · 3 천(올) · edge_k = 위 모서리 밝은 붓 자국(Hades 소품 — 빛 받는 모서리를 칠로 세운다).
// edge_mode 1 상자(BoxMesh UV 3x2 칸) · 2 원기둥(옆 v 0 ~ 0.5 · 윗면 원 (0.25, 0.75) 반지름 0.25) — 메시 가운데가 원점(Godot 기본 도형)
uniform int surf = 0;
uniform float edge_k = 0.0;
uniform int edge_mode = 0;
uniform float edge_px = 3.0;        // 모서리 칠 너비(화면 높이 1080 기준 픽셀)

varying vec3 wpos;
varying vec3 wnrm;
varying vec2 uv_raw;        // uv_scale 전 UV(모서리 찾기)
varying float top_w;        // 메시 위쪽 꼭짓점 1 · 아래 0 — 옆면에서 위 모서리까지 거리
varying float pen_on;       // 빗금 받는 자리(fragment → light)
varying float pen_line;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
	float s = 0.0;
	float a = 0.5;
	for (int i = 0; i < 3; i++) {
		s += a * vnoise(p);
		p = p * 2.03 + vec2(7.1, 3.7);
		a *= 0.5;
	}
	return s;
}

// 보로노이 경계까지 거리(0 = 금 위)
float cell_edge(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	float d1 = 8.0;
	float d2 = 8.0;
	for (int y = -1; y <= 1; y++) {
		for (int x = -1; x <= 1; x++) {
			vec2 g = vec2(float(x), float(y));
			vec2 o = vec2(hash(i + g), hash(i + g + vec2(19.3, 7.7)));
			float d = length(g + o - f);
			if (d < d1) {
				d2 = d1;
				d1 = d;
			} else if (d < d2) {
				d2 = d;
			}
		}
	}
	return d2 - d1;
}

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	uv_raw = UV;
	top_w = VERTEX.y > 0.0 ? 1.0 : 0.0;
	UV = UV * uv_scale.xy + uv_offset.xy;
}

// 줄 하나(거리 d 가 w 안이면 1) — 화면 픽셀로 부드럽게
float aa_line(float d, float w) {
	float fw = max(fwidth(d), 1e-5);
	return 1.0 - smoothstep(w - fw, w + fw, d);
}

// 바닥 무늬 — 색 c 에 곱할 값과 바꾼 색(칸마다 빛깔 차이 · 줄눈 · 결)
vec3 floor_pattern(vec3 c, vec2 p) {
	if (pattern == 1) {                                   // 판석 — 칸마다 빛깔 · 결, 줄눈, 위(먼 쪽) 가장자리 밝은 턱 · 군데군데 깨진 귀
		vec2 g = p / tile;
		vec2 id = floor(g);
		vec2 f = fract(g);
		float h = hash(id);
		c *= 0.86 + 0.26 * h;
		c = mix(c, c * vec3(1.05, 1.0, 0.92), step(0.7, hash(id + 3.1)) * 0.6);
		vec2 dm = min(f, 1.0 - f) * tile;
		float d = min(dm.x, dm.y);
		c *= 1.0 - 0.55 * aa_line(d, 0.014);
		vec2 cn = floor(g + 0.5);                          // 가장 가까운 모서리 꼭짓점 — 군데군데 귀가 깨졌다
		float chip = step(0.75, hash(cn + 1.7)) * (1.0 - smoothstep(0.03, 0.06, length(g - cn) * tile));
		c *= 1.0 - 0.4 * chip;
		c *= 1.0 + 0.14 * aa_line(f.y * tile, 0.05) * (1.0 - aa_line(d, 0.016));
		c *= 1.0 - 0.1 * aa_line((1.0 - f.y) * tile, 0.06);
	} else if (pattern == 2) {                            // 마루 — 가로로 놓인 널(엇갈림), 널마다 빛깔, 길게 늘인 결 · 옹이
		float w = tile * 0.2;
		float row = floor(p.y / w);
		float L = tile * 1.6;
		float x = p.x + hash(vec2(row, 7.0)) * L;
		float col = floor(x / L);
		vec2 id = vec2(col, row);
		float h = hash(id);
		c *= 0.8 + 0.32 * h;
		float gr = fbm(vec2(x * 1.1, p.y * 26.0) + id * 3.0);
		c *= 1.0 + 0.32 * (gr - 0.5);
		float fy = fract(p.y / w) * w;
		float fx = fract(x / L) * L;
		c *= 1.0 - 0.6 * aa_line(min(fy, w - fy), 0.008);
		c *= 1.0 - 0.5 * aa_line(min(fx, L - fx), 0.01);
		c *= 1.0 + 0.1 * aa_line(fy, 0.025);
		vec2 kn = vec2(fract(x / L) * L - L * (0.2 + 0.6 * hash(id + 2.0)), fy - w * 0.5);
		c *= 1.0 - 0.35 * step(0.7, hash(id + 5.0)) * (1.0 - smoothstep(0.015, 0.035, length(kn * vec2(0.5, 1.0))));
	} else if (pattern == 3) {                            // 콘크리트 판 — 큰 판 줄눈(톱질 자국) · 판마다 조금 다른 빛 · 물 자국
		vec2 g = p / tile;
		vec2 id = floor(g);
		vec2 f = fract(g);
		c *= 0.92 + 0.14 * hash(id);
		vec2 dm = min(f, 1.0 - f) * tile;
		c *= 1.0 - 0.45 * aa_line(min(dm.x, dm.y), 0.012);
		c *= 1.0 - 0.12 * smoothstep(0.55, 0.75, fbm(p * 0.45 + id));
	} else if (pattern == 4) {                            // 카펫 — 마름모 무늬(옅게) · 칸 가운데 점
		vec2 r = vec2(p.x + p.y, p.x - p.y) / tile;
		vec2 f = abs(fract(r) - 0.5);
		float d = min(f.x, f.y) * tile;
		c *= 0.86;                                         // 털 결 — 카펫은 판보다 빛을 덜 튕긴다
		c *= 1.0 - 0.32 * aa_line(d, 0.03);
		c = mix(c, c * vec3(1.35, 1.2, 0.75), 0.6 * (1.0 - smoothstep(0.05, 0.08, length((fract(r) - 0.5) * tile))));
		c *= 0.94 + 0.12 * fbm(p * 4.0);
	}
	return c;
}

// 소품 손칠 — 나무 결 · 쇠 긁힘 · 천 올
vec3 prop_surface(vec3 c, vec2 q) {
	if (surf == 1) {
		float gr = fbm(vec2(q.x * 1.4, q.y * 14.0));
		c *= 1.0 + 0.4 * (gr - 0.5);
		c *= 1.0 - 0.18 * smoothstep(0.62, 0.7, fract(gr * 7.0));
	} else if (surf == 2) {
		float br = vnoise(vec2(q.x * 2.0, q.y * 60.0));
		c *= 0.94 + 0.12 * br;
		float sc = vnoise(q * vec2(30.0, 3.0) + 9.0);
		c *= 1.0 + 0.22 * smoothstep(0.9, 0.96, sc);
	} else if (surf == 3) {
		c *= 0.93 + 0.1 * fbm(q * 9.0);
	}
	return c;
}

// 모서리 칠까지 화면 픽셀 거리 — x: 위 모서리 · y: 모든 모서리(옆 세로 모서리 포함)
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
	if (use_vcol) {
		c *= COLOR.rgb;
	}
	if (use_tex) {
		c *= texture(tex, UV).rgb;
	}
	pen_on = 0.0;
	pen_line = 0.0;
	if (use_paint) {
		vec4 pt = texture(paint_tex, UV);
		c *= pt.r * paint_gain;
		pen_on = smoothstep(0.2, 0.4, pt.a);
		pen_line = smoothstep(0.62, 0.88, pt.a);
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
		float brk = 0.55 + 0.45 * smoothstep(0.3, 0.6, vnoise(q * 6.0));       // 붓이 끊긴 자리
		float k = (1.0 - smoothstep(px * 0.6, px, ed.x)) + 0.45 * (1.0 - smoothstep(px * 0.4, px * 0.8, ed.y));
		c = mix(c, c * 1.55 + vec3(0.05, 0.045, 0.035), clamp(k, 0.0, 1.0) * edge_k * brk);
	}
	if (paint > 0.0) {
		float strokes = fbm(q * vec2(2.2, 6.5));          // 한 방향으로 늘인 잡음 = 붓 자국
		float patch = fbm(q * 0.6 + vec2(3.0, 9.0));      // 얼룩(빛 바랜 곳 · 때) — 크면 구름처럼 보였다(11장)
		c *= 1.0 + paint * ((strokes - 0.5) * 0.6 + (patch - 0.5) * 0.5);
		c = mix(c, c * vec3(1.07, 0.98, 0.88), paint * smoothstep(0.5, 0.8, patch));    // 따뜻한 얼룩
		c = mix(c, c * vec3(0.88, 0.92, 1.06), paint * smoothstep(0.5, 0.2, patch) * 0.6);   // 차가운 얼룩
	}
	if (cracks > 0.0) {
		// 금은 군데군데(mask)만 — 온 바닥이 그물처럼 갈라 보이지 않게. 금 둘레는 닳아 조금 어둡다
		float mask = smoothstep(0.5, 0.78, fbm(wpos.xz * 0.23 + vec2(11.0, 2.0)));
		vec2 cq = wpos.xz * 0.9 + vec2(fbm(wpos.xz * 1.7), fbm(wpos.xz * 1.7 + 5.0)) * 0.5;   // 금을 구불구불하게
		float e = cell_edge(cq);
		float line = 1.0 - smoothstep(0.008, 0.035, e);
		float wear = 1.0 - smoothstep(0.0, 0.16, e);
		c *= 1.0 - cracks * mask * (line * 0.7 + wear * 0.14);
	}
	if (ao_floor > 0.0) {
		c *= mix(1.0 - ao_floor, 1.0, smoothstep(0.0, 0.9, wpos.y));
	}
	ALBEDO = c;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	SPECULAR = 0.0;
	EMISSION = emission;
}

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float a = ATTENUATION;
	if (LIGHT_IS_DIRECTIONAL) {
		a = smoothstep(0.3, 0.62, a);                   // 해 그림자 경계를 세운다
	} else {
		a = smoothstep(0.0, 1.0, a);                     // 점광: 빛 웅덩이 가운데를 조금 더 밝게(가장자리는 부드럽게)
	}
	float t = mix(mid * smoothstep(0.0, band, ndl), 1.0, smoothstep(0.42, 0.42 + band, ndl));
	float lit = a * t;
	if (hatch > 0.0 && pen_on > 0.0) {
		// 센 빛(해 · 달 · 실내 위 빛)만 — 뒤에서 오는 약한 윤곽 빛은 앞면 전체가 '그림자'라 빗금이 밝은 면을 덮었다(흰 정장 신겐)
		float strong = smoothstep(hatch_light * 0.7, hatch_light, dot(LIGHT_COLOR, vec3(0.3333)));
		float edge = smoothstep(-0.06, 0.04, ndl) * (1.0 - smoothstep(0.14, 0.28, ndl)) * a;     // 명암 경계 띠
		float deep = 1.0 - smoothstep(0.06, 0.28, lit);
		DIFFUSE_LIGHT += LIGHT_COLOR * (light_k * hatch_lift * deep * strong * pen_on * (1.0 - pen_line));
		lit *= 1.0 - hatch * edge * strong * pen_line;
	}
	DIFFUSE_LIGHT += LIGHT_COLOR * (lit * light_k);
	if (rim > 0.0) {
		float fr = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
		float edge = smoothstep(rim_w, rim_w + 0.06, fr) * smoothstep(-0.25, 0.25, ndl);
		SPECULAR_LIGHT += LIGHT_COLOR * (a * edge * rim);
	}
	if (spec > 0.0) {
		float s = smoothstep(0.93, 0.95, dot(NORMAL, normalize(VIEW + LIGHT)));
		SPECULAR_LIGHT += LIGHT_COLOR * (a * s * spec);
	}
}
