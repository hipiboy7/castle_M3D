// 화면 마무리(3D 위 · HUD 밑 — src/view/ink.gd grade_layer): 채도 · 대비 올림, 어두운 데는 보랏빛 · 밝은 데는 따뜻하게(갈라 물들이기),
// 가장자리 짙은 비네트(가운데 싸움터에 눈이 가게), 종이 결 잡음.
shader_type canvas_item;

uniform sampler2D screen : hint_screen_texture, filter_linear;
uniform float sat = 1.16;
uniform float contrast = 1.1;
uniform vec4 shadow_tint : source_color = vec4(0.10, 0.04, 0.16, 1.0);
uniform vec4 high_tint : source_color = vec4(1.05, 0.98, 0.88, 1.0);
uniform float vignette = 0.62;
uniform float grain = 0.022;
uniform float exposure = 1.0;       // 전체 밝기 ×(ink.gd GRADE_EXPOSURE)

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec3 c = texture(screen, SCREEN_UV).rgb * exposure;
	float l = dot(c, vec3(0.299, 0.587, 0.114));
	c = mix(vec3(l), c, sat);
	c = (c - 0.5) * contrast + 0.5;
	c += shadow_tint.rgb * (1.0 - smoothstep(0.0, 0.42, l)) * 0.5;
	c *= mix(vec3(1.0), high_tint.rgb, smoothstep(0.35, 0.95, l));
	c -= max(c - 0.8, vec3(0.0)) * 0.5;     // 밝은 데는 무릎을 꺾어 하얗게 날아가지 않게(2장 대리석 로비)
	vec2 d = (SCREEN_UV - 0.5) * vec2(1.0, 1.18);
	float v = smoothstep(0.78, 0.3, length(d));
	c *= mix(1.0 - vignette, 1.0, v);
	c += (hash(floor(FRAGCOORD.xy * 0.5)) - 0.5) * grain;
	COLOR = vec4(max(c, vec3(0.0)), 1.0);
}
