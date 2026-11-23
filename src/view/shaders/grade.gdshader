// 화면 마무리 v2 (3D 위 · HUD 밑 — src/view/ink.gd grade_layer):
//  - 챕터 무드별 컬러 스크립트(shadow_tint · high_tint · vignette · sat · contrast · exposure)
//  - 타격 임팩트 프레임(impact_k: 0 평소 · >0 순간 고대비 흑백/크림슨 웹툰 임팩트 컷 + 방사형 집중선)
shader_type canvas_item;

uniform sampler2D screen : hint_screen_texture, filter_linear;
uniform float sat = 1.14;
uniform float contrast = 1.08;
uniform vec4 shadow_tint : source_color = vec4(0.09, 0.045, 0.15, 1.0);
uniform vec4 high_tint : source_color = vec4(1.04, 0.98, 0.90, 1.0);
uniform float vignette = 0.56;
uniform float grain = 0.018;
uniform float exposure = 0.94;
// 웹툰 임팩트 프레임(쳐내기 · 엇박 치명타 · 제압 순간 2~4프레임)
uniform float impact_k = 0.0;
uniform vec4 impact_col : source_color = vec4(0.95, 0.18, 0.16, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec3 c = texture(screen, SCREEN_UV).rgb * exposure;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, sat);
	c = (c - 0.5) * contrast + 0.5;
	c += shadow_tint.rgb * (1.0 - smoothstep(0.0, 0.42, l)) * 0.45;
	c *= mix(vec3(1.0), high_tint.rgb, smoothstep(0.35, 0.95, l));
	// 부드러운 하이라이트 무릎(Reinhard 유사 숄더) — 흰 옷/대리석 디테일 보존
	c = c / (1.0 + max(c - vec3(0.76), vec3(0.0)) * 0.85);
	vec2 d = (SCREEN_UV - 0.5) * vec2(1.0, 1.18);
	float rad = length(d);
	float v = smoothstep(0.80, 0.30, rad);
	c *= mix(1.0 - vignette, 1.0, v);
	c += (hash(floor(FRAGCOORD.xy * 0.5)) - 0.5) * grain;

	// 임팩트 프레임: 고대비 느와르 이진화 + 외곽 방사형 집중선
	if (impact_k > 0.001) {
		float bw = smoothstep(0.28, 0.58, l);
		vec3 cut_c = mix(vec3(0.03, 0.02, 0.04), mix(vec3(1.0, 0.97, 0.94), impact_col.rgb, 0.32), bw);
		float ang = atan(d.y, d.x);
		float rays = smoothstep(0.68, 0.92, sin(ang * 44.0) * 0.5 + 0.5) * smoothstep(0.24, 0.56, rad);
		cut_c = mix(cut_c, impact_col.rgb, rays * 0.65);
		c = mix(c, cut_c, clamp(impact_k, 0.0, 1.0));
	}

	COLOR = vec4(max(c, vec3(0.0)), 1.0);
}
