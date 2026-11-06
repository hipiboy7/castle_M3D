extends Node3D
## 11장 호텔 캐슬 무대 — 방(src/data/hotel.gd ROOMS theme)마다 바닥 · 벽 · 소품 · 빛. 카메라는 +z 쪽 위에서 내려다보므로
## 뒷벽(-z)이 보인다 — 높은 층은 뒷벽을 유리창으로 두고 그 너머 아래로 도시 야경(기획서 03 3절 '높이 · 유리창 · 도시 야경').
## 원작 근거(canon beats): 28층 중앙홀 = 손님이 있는 홀 · 엘리베이터(057) / 71층 홀 = 둥근 탁자 · 기둥 · 붉은 카펫(058) /
## 회장실 앞 = 푸른 조명 복도(fight:kimshin_shingen place_text) / 회장실 = 비어 있음 · 도시를 내려다봄(062/099-106).
## 폰 성능: 점광 3개 이하 · 그림자는 위에서 오는 빛 하나 · 도시는 상자 몇십 개(같은 재질).

var theme := ""
var _detail := true


func build(th: String, b: Rect2, detail := true) -> void:
	theme = th
	_detail = detail
	match th:
		"hall":
			_env(Color(0.32, 0.27, 0.22), 0.7, Color(0.03, 0.03, 0.04))
			_top(Color(1.0, 0.9, 0.75), 0.7)
			_floor(b, Color(0.42, 0.38, 0.33), 0.3, true)
			_back_wall(b, Color(0.42, 0.36, 0.3), 3.6)
			for x in [-2.6, 2.6]:
				_elevator(Vector3(x, 0, b.position.y - 0.62), "28")
			for p in [Vector3(b.position.x + 0.6, 0, b.position.y + 0.4), Vector3(b.end.x - 0.6, 0, b.position.y + 0.4)]:
				_pillar(p, Color(0.7, 0.64, 0.55))
			_omni(Vector3(-3.0, 3.4, -1.0), Color(1.0, 0.82, 0.6), 2.4, 9.0)
			_omni(Vector3(3.0, 3.4, -1.0), Color(1.0, 0.82, 0.6), 2.4, 9.0)
			_sofa(Vector3(b.position.x + 0.9, 0, b.end.y - 0.4))
			_plant(Vector3(b.end.x - 0.5, 0, b.end.y - 0.3))
		"vip_hall":
			_env(Color(0.3, 0.2, 0.18), 0.6, Color(0.02, 0.015, 0.015))
			_top(Color(1.0, 0.85, 0.7), 0.75)
			_floor(b, Color(0.22, 0.14, 0.1), 0.45, false)
			_rug(Rect2(b.position.x + 0.6, -1.1, b.size.x - 1.2, 2.2), Color(0.34, 0.06, 0.07))       # 붉은 카펫
			_back_wall(b, Color(0.26, 0.17, 0.12), 3.6)
			_round_table(Vector3(0, 0, b.position.y + 0.2))
			for x in [b.position.x + 0.5, -2.2, 2.2, b.end.x - 0.5]:
				_pillar(Vector3(x, 0, b.position.y - 0.25), Color(0.36, 0.25, 0.18))
			_omni(Vector3(0, 3.2, -0.6), Color(1.0, 0.78, 0.55), 2.6, 10.0)
			_omni(Vector3(-4.0, 2.6, 1.6), Color(1.0, 0.7, 0.5), 1.2, 6.0)
		"corridor":
			_env(Color(0.16, 0.18, 0.26), 0.55, Color(0.01, 0.015, 0.03))
			_top(Color(0.8, 0.85, 1.0), 0.6)
			_floor(b, Color(0.2, 0.18, 0.2), 0.6, false)
			_rug(Rect2(b.position.x, -0.9, b.size.x, 1.8), Color(0.32, 0.12, 0.14))
			_window_wall(b, 3.4)
			_city(b.position.y - 1.6, b.size.x + 30.0, 1)
			for x in range(int(b.position.x) + 1, int(b.end.x), 3):
				_sconce(Vector3(x, 1.9, b.position.y - 0.55))
			_omni(Vector3(-3.5, 2.8, 0.2), Color(1.0, 0.8, 0.6), 1.6, 7.0)
			_omni(Vector3(3.5, 2.8, 0.2), Color(1.0, 0.8, 0.6), 1.6, 7.0)
		"blue_corridor":
			_env(Color(0.1, 0.16, 0.32), 0.65, Color(0.005, 0.01, 0.03))
			_top(Color(0.55, 0.7, 1.0), 0.6)
			_floor(b, Color(0.12, 0.13, 0.17), 0.3, true)
			_back_wall(b, Color(0.12, 0.14, 0.2), 3.6)
			_double_door(Vector3(b.end.x + 0.05, 0, 0))
			for x in range(int(b.position.x) + 1, int(b.end.x), 2):
				_strip(Vector3(x, 3.0, b.position.y - 0.5))
			_omni(Vector3(-2.0, 2.6, -0.4), Color(0.45, 0.6, 1.0), 2.4, 8.0)
			_omni(Vector3(3.6, 2.6, -0.4), Color(0.45, 0.6, 1.0), 2.4, 8.0)
		"office":
			_env(Color(0.18, 0.2, 0.28), 0.55, Color(0.01, 0.015, 0.03))
			_top(Color(0.8, 0.85, 1.0), 0.55)
			_floor(b, Color(0.18, 0.14, 0.12), 0.5, false)
			_rug(Rect2(-2.4, -1.6, 4.8, 3.2), Color(0.3, 0.26, 0.2))
			_window_wall(b, 3.6)
			_city(b.position.y - 1.6, b.size.x + 36.0, 2)
			_desk(Vector3(1.2, 0, b.position.y + 0.9))
			_omni(Vector3(1.2, 2.8, -1.0), Color(1.0, 0.82, 0.6), 1.4, 6.0)


func _env(amb: Color, energy: float, bg: Color) -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = bg
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = amb
	env.ambient_light_energy = energy
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.05
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.06
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


## 위에서 오는 빛(그림자) — 실내 천장 조명을 하나로 묶은 것
func _top(col: Color, energy: float) -> void:
	var l := DirectionalLight3D.new()
	l.light_color = col
	l.light_energy = energy
	l.rotation_degrees = Vector3(-70, 20, 0)
	l.shadow_enabled = _detail
	l.shadow_blur = 1.6
	l.directional_shadow_max_distance = 24.0
	add_child(l)
	var rim := DirectionalLight3D.new()                  # 뒤에서 오는 약한 빛 — 어두운 정장 윤곽
	rim.light_color = Color(0.6, 0.7, 1.0)
	rim.light_energy = 0.3
	rim.rotation_degrees = Vector3(-20, 180, 0)
	add_child(rim)


func _omni(at: Vector3, col: Color, energy: float, rng: float) -> void:
	var l := OmniLight3D.new()
	l.position = at
	l.light_color = col
	l.light_energy = energy
	l.omni_range = rng
	l.omni_attenuation = 1.2
	add_child(l)


func _floor(b: Rect2, col: Color, rough: float, tiles: bool) -> void:
	var m := _mat(col, rough, 0.0, 0.0)
	m.metallic_specular = 0.7
	var pm := PlaneMesh.new()
	pm.size = Vector2(b.size.x + 4.0, b.size.y + 4.0)
	_mesh(self, pm, m, Vector3(b.get_center().x, 0, b.get_center().y + 0.6))
	if tiles:                                            # 대리석 줄눈
		var j := _mat(col.darkened(0.25), 0.6)
		for x in range(int(b.position.x) - 1, int(b.end.x) + 2, 2):
			_mesh(self, _box(Vector3(0.02, 0.004, b.size.y + 3.0)), j, Vector3(x, 0.002, b.get_center().y + 0.6))
		for z in range(int(b.position.y) - 1, int(b.end.y) + 2, 2):
			_mesh(self, _box(Vector3(b.size.x + 3.0, 0.004, 0.02)), j, Vector3(b.get_center().x, 0.002, z))


func _rug(r: Rect2, col: Color) -> void:
	var m := _mat(col, 0.95)
	_mesh(self, _box(Vector3(r.size.x, 0.01, r.size.y)), m, Vector3(r.get_center().x, 0.005, r.get_center().y))
	var edge := _mat(Color(0.75, 0.6, 0.25), 0.6, 0.0, 0.5)
	for z in [r.position.y, r.end.y]:
		_mesh(self, _box(Vector3(r.size.x, 0.012, 0.05)), edge, Vector3(r.get_center().x, 0.006, z))


func _back_wall(b: Rect2, col: Color, h: float) -> void:
	var m := _mat(col, 0.8)
	var z := b.position.y - 0.8
	_mesh(self, _box(Vector3(b.size.x + 4.0, h, 0.3)), m, Vector3(b.get_center().x, h * 0.5, z))
	var trim := _mat(col.lightened(0.2), 0.5)
	_mesh(self, _box(Vector3(b.size.x + 4.0, 0.12, 0.34)), trim, Vector3(b.get_center().x, 0.06, z + 0.02))
	for sx in [-1.0, 1.0]:                               # 옆벽(낮게 — 위에서 보는 카메라가 안을 본다)
		var x: float = b.get_center().x + sx * (b.size.x * 0.5 + 1.2)
		_mesh(self, _box(Vector3(0.3, 1.2, b.size.y + 2.0)), m, Vector3(x, 0.6, b.get_center().y))


## 유리창 벽: 낮은 턱 · 창틀(세로 기둥)만 — 그 너머로 도시가 보인다
func _window_wall(b: Rect2, h: float) -> void:
	var z := b.position.y - 0.8
	var frame := _mat(Color(0.16, 0.17, 0.2), 0.4, 0.0, 0.6)
	_mesh(self, _box(Vector3(b.size.x + 4.0, 0.5, 0.3)), frame, Vector3(b.get_center().x, 0.25, z))
	_mesh(self, _box(Vector3(b.size.x + 4.0, 0.12, 0.2)), frame, Vector3(b.get_center().x, h, z))
	var glass := _mat(Color(0.5, 0.65, 0.9, 0.12), 0.05, 0.4, 0.0)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mesh(self, _box(Vector3(b.size.x + 4.0, h - 0.5, 0.02)), glass, Vector3(b.get_center().x, 0.5 + (h - 0.5) * 0.5, z))
	for x in range(int(b.position.x) - 1, int(b.end.x) + 2, 2):
		_mesh(self, _box(Vector3(0.08, h, 0.14)), frame, Vector3(x, h * 0.5, z))
	for sx in [-1.0, 1.0]:
		var x: float = b.get_center().x + sx * (b.size.x * 0.5 + 1.2)
		_mesh(self, _box(Vector3(0.3, 1.2, b.size.y + 2.0)), _mat(Color(0.2, 0.2, 0.24), 0.8), Vector3(x, 0.6, b.get_center().y))


## 도시 야경: 유리창 너머 아래쪽(71층) — 건물 상자 + 불 켜진 창(빛나는 작은 판). 결정적(seed 고정)
func _city(z0: float, width: float, seed_v: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 71 + seed_v
	var body := _mat(Color(0.05, 0.06, 0.09), 0.9)
	var lit := _mat(Color(1.0, 0.85, 0.55), 0.5)
	lit.emission = Color(1.0, 0.78, 0.45)
	lit.emission_energy_multiplier = 2.2
	var lit2 := _mat(Color(0.7, 0.85, 1.0), 0.5)
	lit2.emission = Color(0.55, 0.75, 1.0)
	lit2.emission_energy_multiplier = 1.8
	var n := 34 if _detail else 18
	for i in n:
		var x := r.randf_range(-width * 0.5, width * 0.5)
		var z := z0 - r.randf_range(6.0, 40.0)
		var w := r.randf_range(2.0, 5.0)
		var top := r.randf_range(-18.0, -3.0)              # 이 층보다 한참 아래
		var hgt := 40.0
		_mesh(self, _box(Vector3(w, hgt, w)), body, Vector3(x, top - hgt * 0.5, z))
		for k in 3:
			_mesh(self, _box(Vector3(w * 0.7, 0.25, 0.05)), lit if r.randf() < 0.7 else lit2,
				Vector3(x, top - 1.0 - k * 1.6, z + w * 0.5 + 0.03))
	# 먼 도시 불빛 띠
	_mesh(self, _box(Vector3(width * 2.0, 0.3, 0.2)), lit, Vector3(0, -14.0, z0 - 60.0))


func _elevator(at: Vector3, floor_no: String) -> void:
	var metal := _mat(Color(0.7, 0.68, 0.62), 0.25, 0.0, 0.9)
	var frame := _mat(Color(0.45, 0.38, 0.28), 0.4, 0.0, 0.7)
	_mesh(self, _box(Vector3(1.7, 2.7, 0.12)), frame, at + Vector3(0, 1.35, 0))
	for sx in [-1.0, 1.0]:
		_mesh(self, _box(Vector3(0.72, 2.4, 0.06)), metal, at + Vector3(0.37 * sx, 1.2, 0.08))
	var ind := _mat(Color(1.0, 0.6, 0.2), 0.5)
	ind.emission = Color(1.0, 0.55, 0.15)
	ind.emission_energy_multiplier = 3.0
	_mesh(self, _box(Vector3(0.36, 0.14, 0.04)), ind, at + Vector3(0, 2.85, 0.07))
	var l := Label3D.new()
	l.text = floor_no
	l.font_size = 40
	l.pixel_size = 0.005
	l.modulate = Color(1.0, 0.7, 0.3)
	l.position = at + Vector3(0, 2.85, 0.1)
	add_child(l)


func _pillar(at: Vector3, col: Color) -> void:
	_mesh(self, _cyl(0.32, 0.32, 3.6), _mat(col, 0.35, 0.0, 0.1), at + Vector3(0, 1.8, 0))
	_mesh(self, _box(Vector3(0.8, 0.16, 0.8)), _mat(col.darkened(0.15), 0.4), at + Vector3(0, 0.08, 0))


func _sofa(at: Vector3) -> void:
	var m := _mat(Color(0.35, 0.22, 0.14), 0.8)
	_mesh(self, _box(Vector3(1.6, 0.42, 0.7)), m, at + Vector3(0, 0.21, 0))
	_mesh(self, _box(Vector3(1.6, 0.5, 0.18)), m, at + Vector3(0, 0.6, 0.28))


func _plant(at: Vector3) -> void:
	_mesh(self, _cyl(0.22, 0.18, 0.5), _mat(Color(0.3, 0.28, 0.26), 0.6), at + Vector3(0, 0.25, 0))
	_mesh(self, _sphere(0.45), _mat(Color(0.12, 0.28, 0.12), 0.9), at + Vector3(0, 0.9, 0))


func _round_table(at: Vector3) -> void:
	var wood := _mat(Color(0.3, 0.18, 0.1), 0.4)
	_mesh(self, _cyl(0.85, 0.85, 0.06), wood, at + Vector3(0, 0.76, 0))
	_mesh(self, _cyl(0.1, 0.25, 0.74), wood, at + Vector3(0, 0.37, 0))
	_mesh(self, _cyl(0.2, 0.12, 0.14), _mat(Color(0.85, 0.7, 0.3), 0.3, 0.0, 0.8), at + Vector3(0, 0.86, 0))     # 장식 그릇


func _sconce(at: Vector3) -> void:
	var m := _mat(Color(1.0, 0.85, 0.6), 0.5)
	m.emission = Color(1.0, 0.75, 0.45)
	m.emission_energy_multiplier = 2.5
	_mesh(self, _box(Vector3(0.2, 0.3, 0.08)), m, at)


func _strip(at: Vector3) -> void:
	var m := _mat(Color(0.5, 0.65, 1.0), 0.5)
	m.emission = Color(0.4, 0.6, 1.0)
	m.emission_energy_multiplier = 3.0
	_mesh(self, _box(Vector3(1.2, 0.05, 0.1)), m, at)


func _double_door(at: Vector3) -> void:
	var wood := _mat(Color(0.25, 0.15, 0.09), 0.45)
	var gold := _mat(Color(0.85, 0.7, 0.3), 0.3, 0.0, 0.85)
	for sz in [-1.0, 1.0]:
		_mesh(self, _box(Vector3(0.12, 2.8, 0.95)), wood, at + Vector3(0, 1.4, 0.5 * sz))
		_mesh(self, _box(Vector3(0.16, 0.5, 0.04)), gold, at + Vector3(-0.04, 1.2, 0.12 * sz))
	_mesh(self, _box(Vector3(0.2, 0.2, 2.2)), gold, at + Vector3(0, 2.9, 0))


func _desk(at: Vector3) -> void:
	var wood := _mat(Color(0.22, 0.13, 0.08), 0.35)
	_mesh(self, _box(Vector3(2.4, 0.08, 1.0)), wood, at + Vector3(0, 0.78, 0))
	_mesh(self, _box(Vector3(2.3, 0.74, 0.9)), wood, at + Vector3(0, 0.37, 0))
	var leather := _mat(Color(0.08, 0.06, 0.06), 0.5)
	_mesh(self, _box(Vector3(0.7, 0.12, 0.7)), leather, at + Vector3(0, 0.5, -0.9))          # 빈 의자
	_mesh(self, _box(Vector3(0.7, 0.9, 0.14)), leather, at + Vector3(0, 0.95, -1.22))


func _mat(c: Color, rough := 0.7, rim := 0.0, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	if rim > 0.0:
		m.rim_enabled = true
		m.rim = rim
	return m


func _mesh(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _cyl(top: float, bottom: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top
	c.bottom_radius = bottom
	c.height = h
	c.radial_segments = 16
	c.rings = 1
	return c


func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = 12
	s.rings = 6
	return s


func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b
