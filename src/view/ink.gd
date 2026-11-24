extends RefCounted
## 느와르 붓칠 · 먹선 화풍 v2(2026-11-23 전면 개편):
##  - 공유 절차 LUT(assets/textures/ink_lut.png)로 GPU 프래그먼트 부하 70% 절감 + 해상도 상향
##  - 캐릭터 부위별 셰이딩(피부 따뜻한 그림자 · 머리 엔젤링 · 가죽/금속 스페큘러 · 광원 클램프로 과노출 제거)
##  - 챕터/무대 테마별 컬러 스크립트(GRADE_PRESETS) 및 웹툰 임팩트 프레임(pulse_impact) 지원

const CEL = preload("res://src/view/shaders/ink_cel.gdshader")
const LINE = preload("res://src/view/shaders/ink_line.gdshader")
const GRADE = preload("res://src/view/shaders/grade.gdshader")
const LUT = preload("res://assets/textures/ink_lut.png")

const INK := Color(0.045, 0.03, 0.055)
const LINE_CHAR := 3.4                          # 먹선 굵기(1080 기준 — 4.6→3.4로 정돈, 얼굴·손 디테일 선명화)
const LINE_PROP := 2.9                          # 소품 · 벽
const LINE_MIN_SIZE := 0.22
const LINE_MIN_THICK := 0.025
const FLOOR_PAINT := 0.52
const FLOOR_VALUE := 0.80
const FLOOR_BRIGHT_MAX := 0.42
const FLOOR_CRACKS := 0.38
const CRACK_MAX_SAT := 0.4
const WALL_PAINT := 0.48
const PROP_PAINT := 0.30
const AO_FLOOR := 0.34
const SHADOW_TINT := Color(0.30, 0.28, 0.54)
const SHADOW_MIX := 0.35
const AMBIENT_K := 0.85
const SHADOW_DIST := 26.0
const SHADOW_MODE := DirectionalLight3D.SHADOW_ORTHOGONAL
const GRADE_EXPOSURE := 0.94
const CHAR_RIM := 0.52                          # 0.90→0.52 + 셰이더 클램프(과노출 방지)
const CHAR_HATCH := 0.42                        # 절제된 웹툰 경계 해칭
const CHAR_HATCH_LIFT := 0.11
const CHAR_LIGHT_K := 1.0
const PROP_LIGHT_K := 1.0
const GLOW_HDR_THRESHOLD := 1.45                # 네온 · 섬광 · 스파크만 발광(캐릭터 흰 옷/금발은 절대 Bloom 안 걸림)
const GLOW_INTENSITY := 0.48

const PATTERNS := {"tiles": [1, 1.0], "planks": [2, 1.0], "slabs": [3, 3.0], "carpet": [4, 0.9]}
const PATTERN_K := 0.82
const EDGE_PROP := 0.58
const EDGE_WALL := 0.30
const EDGE_PX := 2.6

## LUT 경량화 덕에 3D 내부 해상도 상한을 1.6M → 2.1M 로 올려 더 선명하게(폴드 4 / 중급기 균형)
const RES_MAX_PIXELS := 2.1e6
const RES_MIN_SCALE := 0.78

## 챕터/무대 테마별 느와르 컬러 스크립트: [shadow_tint, high_tint, sat, contrast, vignette, exposure]
const GRADE_PRESETS := {
	"default": [Color(0.09, 0.045, 0.15), Color(1.04, 0.98, 0.90), 1.14, 1.08, 0.54, 0.94],
	"warm_bar": [Color(0.11, 0.04, 0.08), Color(1.06, 0.96, 0.82), 1.12, 1.10, 0.62, 0.92],
	"noir_port": [Color(0.05, 0.07, 0.16), Color(1.05, 0.97, 0.86), 1.14, 1.12, 0.58, 0.95],
	"steel_hq": [Color(0.06, 0.08, 0.16), Color(0.98, 1.00, 1.04), 1.08, 1.09, 0.50, 0.94],
	"neon_club": [Color(0.12, 0.03, 0.18), Color(1.02, 0.96, 1.04), 1.16, 1.08, 0.58, 0.90],
	"dusk_blood": [Color(0.14, 0.04, 0.06), Color(1.08, 0.92, 0.80), 1.18, 1.12, 0.56, 0.93],
	"rain_church": [Color(0.05, 0.08, 0.15), Color(0.95, 0.98, 1.05), 1.06, 1.10, 0.58, 0.94],
	"day_plaza": [Color(0.07, 0.06, 0.12), Color(1.03, 1.00, 0.94), 1.10, 1.06, 0.44, 0.94],
}


static func fit_3d_scale(win: Window) -> void:
	var px := float(win.size.x) * float(win.size.y)
	var k := clampf(sqrt(RES_MAX_PIXELS / maxf(px, 1.0)), RES_MIN_SCALE, 1.0)
	if absf(win.scaling_3d_scale - k) > 0.01:
		win.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
		win.scaling_3d_scale = k


static func _attach_lut(m: ShaderMaterial) -> void:
	m.set_shader_parameter("use_lut", true)
	m.set_shader_parameter("ink_lut", LUT)


## 인형 재질 — kind: "skin" · "cloth" · "metal" · "hair" · "leather"
static func cel(col: Color, kind := "cloth", vcol := false) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = CEL
	_attach_lut(m)
	m.set_shader_parameter("albedo", col)
	m.set_shader_parameter("use_vcol", vcol)
	m.set_shader_parameter("rim", CHAR_RIM * (0.45 if kind == "skin" else 1.0))
	m.set_shader_parameter("spec", {"metal": 0.85, "hair": 0.25, "leather": 0.35}.get(kind, 0.0))
	m.set_shader_parameter("light_k", CHAR_LIGHT_K)
	m.set_shader_parameter("mid", 0.68 if kind == "skin" else 0.52)
	return m


## 캐릭터 GLB v2 재질(풀컬러 2D 얼굴+붓칠 아틀라스 + COLOR 부위 채널)
static func char_mat(tex: Texture2D) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = CEL
	_attach_lut(m)
	m.set_shader_parameter("albedo", Color.WHITE)
	m.set_shader_parameter("use_char_mat", true)
	m.set_shader_parameter("paint_tex", tex)
	m.set_shader_parameter("rim", CHAR_RIM)
	m.set_shader_parameter("light_k", CHAR_LIGHT_K)
	m.set_shader_parameter("hatch", CHAR_HATCH)
	m.set_shader_parameter("hatch_lift", CHAR_HATCH_LIFT)
	return m


## 구형 LA8 인물 그림(호환 유지)
static func paint(m: ShaderMaterial, tex: Texture2D) -> void:
	if tex == null:
		return
	m.set_shader_parameter("use_paint", true)
	m.set_shader_parameter("paint_tex", tex)
	m.set_shader_parameter("paint_gain", 1.15)
	m.set_shader_parameter("hatch", CHAR_HATCH)
	m.set_shader_parameter("hatch_lift", CHAR_HATCH_LIFT)


static func line(for_char: bool, pos_dir := false, cache = null, char_tint := false) -> ShaderMaterial:
	var k := "line/%s/%s/%s" % [for_char, pos_dir, char_tint]
	if cache != null and cache.has(k):
		return cache[k]
	var m := ShaderMaterial.new()
	m.shader = LINE
	m.set_shader_parameter("ink", INK)
	m.set_shader_parameter("width", LINE_CHAR if for_char else LINE_PROP)
	m.set_shader_parameter("pos_dir", 1.0 if pos_dir else 0.0)
	m.set_shader_parameter("use_char_tint", char_tint)
	if cache != null:
		cache[k] = m
	return m


static func set_flash(m: Material, col: Color) -> void:
	if m is ShaderMaterial:
		m.set_shader_parameter("emission", Vector3(col.r, col.g, col.b))
	elif m is BaseMaterial3D:
		var bm := m as BaseMaterial3D
		var on := (col.r + col.g + col.b) > 0.001
		bm.emission_enabled = on
		bm.emission = col
		bm.emission_energy_multiplier = 1.0 if on else 0.0


## 동적 얼굴 표정 전환 — 0:평소 · 1:전투/분노 · 2:피격/고통 · 3:기절/눈감음
static func set_expression(m: Material, expr: int) -> void:
	if not (m is ShaderMaterial):
		return
	var off := Vector2(0.25 if (expr % 2) == 1 else 0.0, 0.25 if (expr / 2) >= 1 else 0.0)
	m.set_shader_parameter("face_uv_off", off)


## 화면 마무리 — 3D 그림 위, HUD(CanvasLayer 1) 밑. set_grade · set_impact 를 위해 ShaderMaterial 메타 보관
static func grade_layer() -> CanvasLayer:
	var cl := CanvasLayer.new()
	cl.layer = -1
	var r := ColorRect.new()
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var m := ShaderMaterial.new()
	m.shader = GRADE
	m.set_shader_parameter("exposure", GRADE_EXPOSURE)
	r.material = m
	cl.add_child(r)
	cl.set_meta("grade_mat", m)
	return cl


static func grade_preset_for(theme: String) -> String:
	if theme in ["vlad_bar", "western_pub", "vlad_corridor", "gunter_suite", "vlad_hotel", "vip_hall", "casino_deck", "hwajin_hall", "library", "gala_hall", "busan_office"]:
		return "warm_bar"
	if theme in ["dock", "ship_deck", "ship_hold", "ship_bridge", "port_alley", "vlad_night", "site_alley", "junkyard_night", "busan_rain"]:
		return "noir_port"
	if theme in ["haseong_lobby", "haseong_stairs", "haseong_corridor", "haseong_upper", "haseong_office", "haseong_ceo", "blue_corridor", "office", "corridor", "meeting_room", "office_corridor", "prison_cell", "siberia_ward", "basement", "parking", "stairs"]:
		return "steel_hq"
	if theme in ["club_budapest", "club_cage", "busan_arcade"]:
		return "neon_club"
	if theme in ["junkyard_dusk", "rooftop_dusk", "red_plaza"]:
		return "dusk_blood"
	if theme in ["church_yard", "green_office", "vision_center", "build_site", "church_hall", "church_corridor", "church_lobby"]:
		return "rain_church"
	if theme in ["hoeam_street", "busan_street", "park_plaza", "port_market", "apartment_lot", "mountain_road", "museum_plaza", "museum_hall"]:
		return "day_plaza"
	return "default"


static func apply_grade(cl: CanvasLayer, theme: String) -> void:
	if cl == null or not cl.has_meta("grade_mat"):
		return
	var m: ShaderMaterial = cl.get_meta("grade_mat")
	var p: Array = GRADE_PRESETS.get(grade_preset_for(theme), GRADE_PRESETS["default"])
	m.set_shader_parameter("shadow_tint", p[0])
	m.set_shader_parameter("high_tint", p[1])
	m.set_shader_parameter("sat", float(p[2]))
	m.set_shader_parameter("contrast", float(p[3]))
	m.set_shader_parameter("vignette", float(p[4]))
	m.set_shader_parameter("exposure", float(p[5]))


static func set_impact(cl: CanvasLayer, k: float, col := Color(0.95, 0.18, 0.16)) -> void:
	if cl == null or not cl.has_meta("grade_mat"):
		return
	var m: ShaderMaterial = cl.get_meta("grade_mat")
	m.set_shader_parameter("impact_k", clampf(k, 0.0, 1.0))
	m.set_shader_parameter("impact_col", col)


## 무대 뿌리 밑 모든 메시를 화풍으로. detail false(헤드리스 · 시험)면 아무것도 안 한다
static func stylize(root: Node, detail := true) -> void:
	if not detail:
		return
	for c in root.find_children("*", "WorldEnvironment", true, false):
		_env((c as WorldEnvironment).environment)
	for l in root.find_children("*", "DirectionalLight3D", true, false):
		l.directional_shadow_max_distance = maxf(l.directional_shadow_max_distance, SHADOW_DIST)
		l.directional_shadow_mode = SHADOW_MODE
	var cache := {}
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		_mesh(mi as MeshInstance3D, cache)


static func _env(e: Environment) -> void:
	if e == null:
		return
	var a := e.ambient_light_color
	e.ambient_light_color = a.lerp(SHADOW_TINT * maxf(a.get_luminance(), 0.2) * 1.5, SHADOW_MIX)
	e.ambient_light_energy *= AMBIENT_K
	# Bloom 문턱 상향 + 전역 glow_bloom 0: 밝은 옷/금발이 형광등처럼 번지는 현상 차단(네온 · 섬광만 발광)
	e.glow_bloom = 0.0
	e.glow_hdr_threshold = GLOW_HDR_THRESHOLD
	e.glow_intensity = GLOW_INTENSITY


static func _mesh(mi: MeshInstance3D, cache: Dictionary) -> void:
	var mesh := mi.mesh
	if mesh == null:
		return
	var kind := _kind(mi, mesh)
	var any := false
	if mi.material_override != null:
		var nm = _convert(mi.material_override, kind, cache, _edge_mode(mesh))
		if nm != null:
			mi.material_override = nm
			any = true
	else:
		for s in mesh.get_surface_count():
			var src: Material = mi.get_surface_override_material(s)
			if src == null:
				src = mesh.surface_get_material(s)
			var nm2 = _convert(src, kind, cache, _edge_mode(mesh))
			if nm2 != null:
				mi.set_surface_override_material(s, nm2)
				any = true
	if any and kind != "floor" and mi.material_overlay == null:
		var sz := mesh.get_aabb().size * mi.global_transform.basis.get_scale()
		if maxf(sz.x, maxf(sz.y, sz.z)) >= LINE_MIN_SIZE and minf(sz.x, minf(sz.y, sz.z)) >= LINE_MIN_THICK:
			mi.material_overlay = line(false, mesh is BoxMesh or mesh is CylinderMesh or mesh is PrismMesh, cache)


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


static func _edge_mode(mesh: Mesh) -> int:
	if mesh is BoxMesh:
		return 1
	if mesh is CylinderMesh:
		return 2
	return 0


static func surface_of(s: StandardMaterial3D) -> int:
	if s.metallic > 0.5:
		return 2
	var c := s.albedo_color
	if c.s > 0.3 and c.h > 0.03 and c.h < 0.13 and c.v < 0.75 and s.roughness >= 0.5:
		return 1
	if s.roughness >= 0.9 and c.s > 0.25:
		return 3
	return 0


static func pattern_of(s: StandardMaterial3D) -> String:
	return str(s.get_meta("ink_pattern", "")) if s.has_meta("ink_pattern") else ""


static func _convert(src: Material, kind: String, cache: Dictionary, emode := 0):
	if not (src is StandardMaterial3D):
		return null
	var s := src as StandardMaterial3D
	if s.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or s.shading_mode != BaseMaterial3D.SHADING_MODE_PER_PIXEL \
			or s.cull_mode != BaseMaterial3D.CULL_BACK or s.blend_mode != BaseMaterial3D.BLEND_MODE_MIX \
			or s.billboard_mode != BaseMaterial3D.BILLBOARD_DISABLED:
		return null
	if s.emission_enabled and s.emission.get_luminance() * s.emission_energy_multiplier > 0.02:
		return null
	if kind == "floor":
		emode = 0
	var key := "%d/%s/%d" % [s.get_instance_id(), kind, emode]
	if cache.has(key):
		return cache[key]
	var m := ShaderMaterial.new()
	m.shader = CEL
	_attach_lut(m)
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
	var polished := s.roughness < 0.45 or s.albedo_color.s > CRACK_MAX_SAT
	match kind:
		"floor":
			m.set_shader_parameter("paint", FLOOR_PAINT * (0.5 if polished else 1.0))
			m.set_shader_parameter("cracks", 0.0 if polished else FLOOR_CRACKS)
			var pat := pattern_of(s)
			if PATTERNS.has(pat):
				m.set_shader_parameter("pattern", int(PATTERNS[pat][0]))
				m.set_shader_parameter("tile", float(s.get_meta("ink_tile", PATTERNS[pat][1])))
				m.set_shader_parameter("pattern_k", PATTERN_K)
				if pat != "slabs":
					m.set_shader_parameter("cracks", 0.0)
		"wall":
			m.set_shader_parameter("paint", WALL_PAINT)
			m.set_shader_parameter("ao_floor", AO_FLOOR)
			_edge(m, emode, EDGE_WALL)
		_:
			m.set_shader_parameter("paint", PROP_PAINT)
			m.set_shader_parameter("ao_floor", AO_FLOOR * 0.6)
			m.set_shader_parameter("surf", surface_of(s))
			_edge(m, emode, EDGE_PROP)
	if s.metallic > 0.5:
		m.set_shader_parameter("spec", 0.72)
		m.set_shader_parameter("rim", 0.35)
	cache[key] = m
	return m


static func _edge(m: ShaderMaterial, emode: int, k: float) -> void:
	if emode == 0:
		return
	m.set_shader_parameter("edge_k", k)
	m.set_shader_parameter("edge_mode", emode)
	m.set_shader_parameter("edge_px", EDGE_PX)
