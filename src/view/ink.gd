extends RefCounted
## 붓칠 · 먹선 화풍(2026-11-11 사용자 "Hades의 모습을 베껴서 진행해줘. 지금까지 네가 해준 대로 하면 계속 도형모양이자나" — 1 ~ 5 추천대로):
## Hades(BAFTA 2021 · TGA 2025 Hades II)처럼 굵은 먹선 · 딱 끊긴 세 단 명암 · 짙고 차가운 그림자 · 빛 색 테두리 빛 · 붓 결 바닥 · 짙은 비네트.
## 그리는 쪽(무대 set3d · town3d … · 인형 puppet3d · puppet_glb)은 그대로 StandardMaterial3D 로 짓고, 여기서 한 번에 바꿔 입힌다(OCP —
## 무대 파일마다 고치지 않는다). 셰이더 src/view/shaders/ink_cel · ink_line · grade. 수치는 이 파일 머리 const 한 곳.
##   stylize(무대 뿌리)  — 불투명 · 빛 받는 재질 → ink_cel(바닥은 붓 결 · 금, 벽 · 소품은 결만), 크기 있는 메시에 먹선(material_overlay),
##                         환경(그림자 색 차갑게 · 빛 번짐 문턱 낮춤)
##   cel(색, 종류)       — 인형 재질(puppet3d _mat · puppet_glb _toon) — 테두리 빛 · 반사광
##   line(인물 | 소품)   — 먹선 재질(나눠 씀)
##   grade_layer()       — 화면 마무리(3D 위 · HUD 밑)
##   set_flash(재질, 색) — 번쩍임(StandardMaterial3D · ShaderMaterial 둘 다)

const CEL = preload("res://src/view/shaders/ink_cel.gdshader")
const LINE = preload("res://src/view/shaders/ink_line.gdshader")
const GRADE = preload("res://src/view/shaders/grade.gdshader")

const INK := Color(0.045, 0.03, 0.055)          # 먹 — 순검정보다 조금 보랏빛
const LINE_CHAR := 4.6                          # 먹선 굵기(화면 높이 1080 기준 픽셀) — 인물
const LINE_PROP := 3.4                          # 소품 · 벽
const LINE_MIN_SIZE := 0.22                     # 이보다 작은 소품(가장 긴 변 m)은 먹선 없음 — 잔 조각이 먹 덩어리가 되지 않게
const LINE_MIN_THICK := 0.025                   # 이보다 얇은 것(바닥 줄눈 · 안전선 · 붙인 판)도 없음 — 화면을 가로지르는 검은 줄이 된다(6장 부두)
const FLOOR_PAINT := 0.6
const FLOOR_VALUE := 0.8                        # 바닥 색 × — 바닥은 인물보다 한 단 어둡게(인물이 떠 보이게 — Hades 바닥 원칙)
const FLOOR_BRIGHT_MAX := 0.42                  # 아주 밝은 바닥(흰 대리석 · 눈)은 이 밝기까지 — 하얗게 날아가지 않게
const FLOOR_CRACKS := 0.4
const CRACK_MAX_SAT := 0.4                      # 이보다 채도 높은 바닥(풀밭 · 카펫)은 금이 가지 않는다 — 회색 땅(아스팔트 · 콘크리트)만
const WALL_PAINT := 0.55
const PROP_PAINT := 0.32
const AO_FLOOR := 0.32                          # 벽 · 기둥 밑동 그늘
const SHADOW_TINT := Color(0.34, 0.3, 0.58)     # 그림자(환경광) 쪽으로 미는 색 — 차갑고 보랏빛
const SHADOW_MIX := 0.4
const AMBIENT_K := 0.82                         # 환경광 세기 × — 명암 대비를 키운다
const SHADOW_DIST := 34.0                       # 해 그림자 거리(m) — 망원 카메라(camera_rig OFFSET)가 멀다
const CHAR_RIM := 0.9
const CHAR_LIGHT_K := 1.0
const PROP_LIGHT_K := 1.0

## 인형 재질 — kind: "skin" · "cloth" · "metal" · "hair" · "leather"(테두리 빛 · 반사광만 다르다)
static func cel(col: Color, kind := "cloth", vcol := false) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = CEL
	m.set_shader_parameter("albedo", col)
	m.set_shader_parameter("use_vcol", vcol)
	m.set_shader_parameter("rim", CHAR_RIM * (0.7 if kind == "skin" else 1.0))
	m.set_shader_parameter("spec", {"metal": 0.9, "hair": 0.22, "leather": 0.3}.get(kind, 0.0))
	m.set_shader_parameter("light_k", CHAR_LIGHT_K)
	m.set_shader_parameter("mid", 0.6 if kind == "skin" else 0.5)
	return m


## 먹선 재질(material_overlay) — 상자 · 원기둥은 꼭짓점 방향으로 민다(모서리 법선이 갈라져 끊기지 않게). 나눠 쓰기는 부르는 쪽이
## 캐시(무대 하나 · 인형 하나) — 정적 캐시는 끝날 때 '자원이 남았다' 오류(verify 가 실패로 본다)
static func line(for_char: bool, pos_dir := false, cache = null) -> ShaderMaterial:
	var k := "line/%s/%s" % [for_char, pos_dir]
	if cache != null and cache.has(k):
		return cache[k]
	var m := ShaderMaterial.new()
	m.shader = LINE
	m.set_shader_parameter("ink", INK)
	m.set_shader_parameter("width", LINE_CHAR if for_char else LINE_PROP)
	m.set_shader_parameter("pos_dir", 1.0 if pos_dir else 0.0)
	if cache != null:
		cache[k] = m
	return m


static func set_flash(m: Material, col: Color) -> void:
	if m is ShaderMaterial:
		m.set_shader_parameter("emission", Vector3(col.r, col.g, col.b))
	else:
		m.emission = col


## 화면 마무리 — 3D 그림 위, HUD(CanvasLayer 1) 밑
static func grade_layer() -> CanvasLayer:
	var cl := CanvasLayer.new()
	cl.layer = -1
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = GRADE
	r.material = m
	cl.add_child(r)
	return cl


## 무대 뿌리 밑 모든 메시를 화풍으로. detail false(헤드리스 · 시험)면 아무것도 안 한다
static func stylize(root: Node, detail := true) -> void:
	if not detail:
		return
	for c in root.find_children("*", "WorldEnvironment", true, false):
		_env((c as WorldEnvironment).environment)
	for l in root.find_children("*", "DirectionalLight3D", true, false):
		l.directional_shadow_max_distance = maxf(l.directional_shadow_max_distance, SHADOW_DIST)   # 카메라가 멀어졌다(camera_rig FOV)
	var cache := {}
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		_mesh(mi as MeshInstance3D, cache)


static func _env(e: Environment) -> void:
	if e == null:
		return
	var a := e.ambient_light_color
	e.ambient_light_color = a.lerp(SHADOW_TINT * maxf(a.get_luminance(), 0.2) * 1.6, SHADOW_MIX)
	e.ambient_light_energy *= AMBIENT_K


static func _mesh(mi: MeshInstance3D, cache: Dictionary) -> void:
	var mesh := mi.mesh
	if mesh == null:
		return
	var kind := _kind(mi, mesh)
	var any := false
	if mi.material_override != null:
		var nm = _convert(mi.material_override, kind, cache)
		if nm != null:
			mi.material_override = nm
			any = true
	else:
		for s in mesh.get_surface_count():
			var src: Material = mi.get_surface_override_material(s)
			if src == null:
				src = mesh.surface_get_material(s)
			var nm2 = _convert(src, kind, cache)
			if nm2 != null:
				mi.set_surface_override_material(s, nm2)
				any = true
	if any and kind != "floor" and mi.material_overlay == null:
		var sz := mesh.get_aabb().size * mi.global_transform.basis.get_scale()
		if maxf(sz.x, maxf(sz.y, sz.z)) >= LINE_MIN_SIZE and minf(sz.x, minf(sz.y, sz.z)) >= LINE_MIN_THICK:
			mi.material_overlay = line(false, mesh is BoxMesh or mesh is CylinderMesh or mesh is PrismMesh, cache)


## floor(땅 · 바닥 판) · wall(키 큰 벽 · 기둥) · prop
static func _kind(mi: MeshInstance3D, mesh: Mesh) -> String:
	var sz := mesh.get_aabb().size * mi.global_transform.basis.get_scale()
	var y := mi.global_position.y
	if mesh is PlaneMesh or mesh is QuadMesh:
		return "floor" if absf(mi.global_transform.basis.y.normalized().y) > 0.9 and y < 0.2 else "wall"
	if sz.y <= 0.12 and minf(sz.x, sz.z) >= 1.2 and y < 0.2:
		return "floor"
	if sz.y >= 1.6 or maxf(sz.x, sz.z) >= 3.0:
		return "wall"
	return "prop"


static func _convert(src: Material, kind: String, cache: Dictionary):
	if not (src is StandardMaterial3D):
		return null
	var s := src as StandardMaterial3D
	if s.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or s.shading_mode != BaseMaterial3D.SHADING_MODE_PER_PIXEL \
			or s.cull_mode != BaseMaterial3D.CULL_BACK or s.blend_mode != BaseMaterial3D.BLEND_MODE_MIX \
			or s.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED:
		return null
	if s.emission_enabled and s.emission.get_luminance() * s.emission_energy_multiplier > 0.02:
		return null                                       # 스스로 빛나는 것(창 · 등 · 간판)은 그대로 — 빛 번짐
	var key := "%d/%s" % [s.get_instance_id(), kind]
	if cache.has(key):
		return cache[key]
	var m := ShaderMaterial.new()
	m.shader = CEL
	var col := s.albedo_color
	if kind == "floor":
		col = Color(col.r * FLOOR_VALUE, col.g * FLOOR_VALUE, col.b * FLOOR_VALUE, col.a)
		var lum := col.get_luminance()
		if lum > FLOOR_BRIGHT_MAX:
			var k := FLOOR_BRIGHT_MAX / lum
			col = Color(col.r * k, col.g * k, col.b * k, col.a)
	m.set_shader_parameter("albedo", col)
	if s.albedo_texture != null:
		m.set_shader_parameter("use_tex", true)
		m.set_shader_parameter("tex", s.albedo_texture)
		m.set_shader_parameter("uv_scale", s.uv1_scale)
		m.set_shader_parameter("uv_offset", s.uv1_offset)
	m.set_shader_parameter("use_vcol", s.vertex_color_use_as_albedo)
	m.set_shader_parameter("light_k", PROP_LIGHT_K)
	var polished := s.roughness < 0.45 or s.albedo_color.s > CRACK_MAX_SAT   # 대리석 · 광택 바닥 · 풀 · 카펫(채도 높음)은 금 없이
	match kind:
		"floor":
			m.set_shader_parameter("paint", FLOOR_PAINT * (0.5 if polished else 1.0))
			m.set_shader_parameter("cracks", 0.0 if polished else FLOOR_CRACKS)
		"wall":
			m.set_shader_parameter("paint", WALL_PAINT)
			m.set_shader_parameter("ao_floor", AO_FLOOR)
		_:
			m.set_shader_parameter("paint", PROP_PAINT)
			m.set_shader_parameter("ao_floor", AO_FLOOR * 0.6)
	if s.metallic > 0.5:
		m.set_shader_parameter("spec", 0.8)
		m.set_shader_parameter("rim", 0.4)
	cache[key] = m
	return m
