extends Node3D
## 결투 무대 — 인천항 제3부두, 밤 (castle_M 6장 결투 무대 `dock` 의 3D 판: 컨테이너 · 가로등 · 계류 기둥 · 드럼통 · 크레인 다리).
## 빛: 달빛(차가운 주광, 그림자) · 가로등(따뜻한 점광) · 뒤쪽 역광(실루엣) · 어두운 남색 환경광 · 얕은 안개.
## 바닥은 젖은 아스팔트 — 거칠기를 얼룩지게 해 가로등 빛이 물웅덩이처럼 번진다. 크기는 combat/world.gd bounds 와 맞춘다.

const HALF_W := 7.4
const HALF_D := 4.4

const Breakables = preload("res://src/view/breakables.gd")

var lamps: Array = []
var brk: Node3D = null              # 부서지는 드럼통 · 상자(2026-11-12 사용자 "싸우면서 주변 물건들도 박살나는 연출")


func break_hit(pos: Vector2, dir: Vector2) -> bool:
	return brk != null and brk.break_hit(pos, dir)


func break_at(at: Vector2, r: float, dir: Vector2, kind := "") -> bool:
	return brk != null and brk.break_at(at, r, dir, kind)


## 메시 몇 개를 묶어 부서지는 소품 하나로
func _breakable(meshes: Array, at: Vector3, r: float) -> void:
	if brk == null:
		brk = Breakables.new()
		add_child(brk)
	var g := Node3D.new()
	add_child(g)
	g.position = Vector3(at.x, 0, at.z)
	for m in meshes:
		var gt: Transform3D = (m as Node3D).transform
		(m as Node3D).reparent(g, false)
		(m as Node3D).transform = g.transform.affine_inverse() * gt
	brk.register(g, Vector2(at.x, at.z), r)


func build(shadows_detail := true) -> void:
	_environment()
	_lights(shadows_detail)
	_ground()
	_props()


func _environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.015, 0.022, 0.04)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.2, 0.25, 0.38)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.1
	env.fog_enabled = true
	env.fog_light_color = Color(0.07, 0.09, 0.14)
	env.fog_density = 0.018
	env.glow_enabled = true
	env.glow_intensity = 0.6
	env.glow_bloom = 0.05
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)


func _lights(detail: bool) -> void:
	var moon := DirectionalLight3D.new()
	moon.light_color = Color(0.66, 0.76, 1.0)
	moon.light_energy = 0.7
	moon.rotation_degrees = Vector3(-52, 32, 0)
	moon.shadow_enabled = true
	moon.shadow_blur = 1.5
	moon.directional_shadow_max_distance = 26.0
	add_child(moon)
	var rim := DirectionalLight3D.new()                  # 카메라 반대쪽에서 오는 역광 — 어두운 정장의 윤곽
	rim.light_color = Color(0.45, 0.6, 1.0)
	rim.light_energy = 0.45
	rim.rotation_degrees = Vector3(-20, 180, 0)
	add_child(rim)
	# 가로등: 뒤쪽 둘(그림자) · 앞 모서리 하나
	for p in [Vector3(-4.2, 0, -5.0), Vector3(3.8, 0, -5.0), Vector3(7.6, 0, 3.4)]:
		lamps.append(_lamp(p, detail and p.z < 0))


func _lamp(at: Vector3, shadow: bool) -> OmniLight3D:
	var pole := _mat(Color(0.2, 0.21, 0.24), 0.5, 0.6)
	_mesh(self, _cyl(0.07, 0.09, 6.0), pole, at + Vector3(0, 3.0, 0))
	_mesh(self, _box(Vector3(0.9, 0.08, 0.08)), pole, at + Vector3(0.4, 5.95, 0))
	var head := _mat(Color(1.0, 0.85, 0.6), 0.4)
	head.emission = Color(1.0, 0.72, 0.4)
	head.emission_energy_multiplier = 4.0
	_mesh(self, _box(Vector3(0.38, 0.12, 0.26)), head, at + Vector3(0.78, 5.86, 0))
	var light := OmniLight3D.new()
	light.position = at + Vector3(0.78, 5.6, 0.0)
	light.light_color = Color(1.0, 0.72, 0.42)
	light.light_energy = 2.6
	light.omni_range = 11.0
	light.omni_attenuation = 1.1
	light.shadow_enabled = shadow
	add_child(light)
	return light


func _ground() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = 6
	noise.frequency = 0.035
	noise.fractal_octaves = 4
	var tex := NoiseTexture2D.new()
	tex.noise = noise
	tex.width = 256
	tex.height = 256
	tex.seamless = true
	var ramp := Gradient.new()                       # 거칠기 0.72 ~ 0.95 — 대비가 크면 표범 무늬처럼 번쩍인다
	ramp.set_color(0, Color(0.72, 0.72, 0.72))
	ramp.set_color(1, Color(0.95, 0.95, 0.95))
	tex.color_ramp = ramp
	var asphalt := StandardMaterial3D.new()
	asphalt.albedo_color = Color(0.12, 0.125, 0.145)     # 무늬는 거칠기에만 — 색 얼룩(구름 · 대리석 같음)을 없앴다
	asphalt.roughness_texture = tex                  # 얼룩진 거칠기 = 젖은 곳은 빛을 비춘다
	asphalt.roughness = 1.0
	asphalt.metallic_specular = 0.6
	asphalt.uv1_scale = Vector3(16, 16, 16)
	var ground := PlaneMesh.new()
	ground.size = Vector2(HALF_W * 2 + 6, HALF_D * 2 + 3)
	_mesh(self, ground, asphalt, Vector3(0, 0, 0.9))
	# 부두 끝 너머 바다 (뒤쪽)
	var sea := StandardMaterial3D.new()
	sea.albedo_color = Color(0.02, 0.04, 0.07)
	sea.roughness = 0.06
	sea.metallic = 0.4
	var water := PlaneMesh.new()
	water.size = Vector2(60, 30)
	_mesh(self, water, sea, Vector3(0, -0.6, -HALF_D - 15.6))
	_mesh(self, _box(Vector3(HALF_W * 2 + 6, 0.6, 0.4)), _mat(Color(0.25, 0.25, 0.27), 0.9), Vector3(0, -0.3, -HALF_D - 0.6))
	# 노란 안전선 · 줄눈
	var yellow := _mat(Color(0.85, 0.66, 0.12), 0.6)
	yellow.emission = Color(0.25, 0.18, 0.0)
	for x in range(-7, 8, 2):
		_mesh(self, _box(Vector3(1.1, 0.012, 0.14)), yellow, Vector3(x, 0.006, -HALF_D + 0.2))
	_mesh(self, _box(Vector3(0.12, 0.012, HALF_D * 2)), yellow, Vector3(-HALF_W + 0.3, 0.006, 0.2))
	var joint := _mat(Color(0.08, 0.08, 0.09), 0.9)
	for z in [-2.0, 0.6, 3.2]:
		_mesh(self, _box(Vector3(HALF_W * 2, 0.008, 0.03)), joint, Vector3(0, 0.004, z))


func _props() -> void:
	# 컨테이너: 왼쪽 · 오른쪽 옆에 2단으로 (뒤쪽은 바다)
	var cols := [Color(0.55, 0.16, 0.12), Color(0.12, 0.28, 0.5), Color(0.18, 0.4, 0.3), Color(0.62, 0.45, 0.12)]
	_container(Vector3(-10.4, 0, -2.4), cols[0], 90.0)
	_container(Vector3(-10.4, 0, 3.8), cols[1], 90.0)
	_container(Vector3(-10.2, 2.6, -2.2), cols[2], 90.0)
	_container(Vector3(10.5, 0, 0.6), cols[3], 90.0)
	_container(Vector3(10.3, 2.6, 0.8), cols[0], 90.0)
	_container(Vector3(10.5, 0, -5.6), cols[1], 90.0)
	# 계류 기둥 (부두 끝)
	var iron := _mat(Color(0.16, 0.17, 0.19), 0.45, 0.5)
	for x in [-5.6, -1.0, 4.6]:
		_mesh(self, _cyl(0.2, 0.24, 0.5), iron, Vector3(x, 0.25, -HALF_D))
		_mesh(self, _cyl(0.27, 0.27, 0.08), iron, Vector3(x, 0.52, -HALF_D))
	# 드럼통 묶음 · 팔레트 · 나무 상자
	var drum_cols := [Color(0.5, 0.12, 0.1), Color(0.14, 0.24, 0.42), Color(0.3, 0.3, 0.32)]
	var drums := [Vector3(-7.2, 0, 3.4), Vector3(-6.6, 0, 3.8), Vector3(-7.0, 0, 4.3), Vector3(7.4, 0, -2.9)]
	for i in drums.size():
		var d: Vector3 = drums[i]
		_breakable([_mesh(self, _cyl(0.29, 0.29, 0.88), _mat(drum_cols[i % 3], 0.5, 0.3, 0.3), d + Vector3(0, 0.44, 0))], d, 0.32)
	var wood := _mat(Color(0.42, 0.31, 0.2), 0.9)
	_breakable([_mesh(self, _box(Vector3(1.2, 0.11, 1.0)), wood, Vector3(6.4, 0.055, 4.0)),
		_mesh(self, _box(Vector3(0.9, 0.8, 0.9)), _mat(Color(0.36, 0.3, 0.22), 0.9), Vector3(6.4, 0.55, 4.0))], Vector3(6.4, 0, 4.0), 0.6)
	# 부두 가장자리 나무 상자 더미(부서지는 소품)
	for c in [Vector3(-3.2, 0, 4.6), Vector3(2.4, 0, 4.7), Vector3(-6.8, 0, -3.9), Vector3(3.4, 0, -3.9)]:
		var bm := _mat(Color(0.45, 0.33, 0.2), 0.9)
		_breakable([_mesh(self, _box(Vector3(0.8, 0.7, 0.8)), bm, c + Vector3(0, 0.35, 0)),
			_mesh(self, _box(Vector3(0.6, 0.5, 0.6)), bm, c + Vector3(0.1, 0.95, 0.05))], c, 0.5)
	# 크레인 다리 (노란 철골, 부두 끝 오른쪽)
	var crane := _mat(Color(0.75, 0.55, 0.1), 0.5, 0.3, 0.4)
	for x in [7.2, 9.6]:
		_mesh(self, _box(Vector3(0.45, 9.0, 0.45)), crane, Vector3(x, 4.5, -HALF_D - 0.4))
	_mesh(self, _box(Vector3(2.9, 0.45, 0.45)), crane, Vector3(8.4, 8.8, -HALF_D - 0.4))
	# 건너편 부두 불빛 (멀리, 바다 너머)
	var far := StandardMaterial3D.new()
	far.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	far.albedo_color = Color(1.0, 0.78, 0.45)
	var rng := RandomNumberGenerator.new()
	rng.seed = 36
	for i in 26:
		var x := rng.randf_range(-30.0, 30.0)
		_mesh(self, _box(Vector3(0.25, 0.12, 0.1)), far, Vector3(x, rng.randf_range(0.4, 2.4), -26.0 - rng.randf_range(0, 6)))


func _container(at: Vector3, col: Color, yaw: float) -> void:
	# 골판 무늬: 세로 줄무늬 그림을 덮는다
	var img := Image.create(32, 1, false, Image.FORMAT_RGB8)
	for x in 32:
		var k := 0.78 if (x % 4) < 2 else 1.0
		img.set_pixel(x, 0, Color(col.r * k, col.g * k, col.b * k))
	var tex := ImageTexture.create_from_image(img)
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.roughness = 0.62
	m.metallic = 0.35
	m.uv1_scale = Vector3(6, 1, 1)
	var c := _mesh(self, _box(Vector3(6.06, 2.59, 2.44)), m, at + Vector3(0, 1.3, 0))
	c.rotation_degrees = Vector3(0, yaw, 0)


func _mat(c: Color, rough := 0.7, rim := 0.0, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	if rim > 0.0:
		m.rim_enabled = true
		m.rim = rim
	m.emission_enabled = true
	m.emission = Color(0, 0, 0)
	return m


func _mesh(parent: Node3D, mesh: Mesh, mat: Material, pos: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _cyl(top: float, bottom: float, h: float) -> CylinderMesh:
	var m := CylinderMesh.new()
	m.top_radius = top
	m.bottom_radius = bottom
	m.height = h
	m.radial_segments = 16
	m.rings = 1
	return m


func _box(size: Vector3) -> BoxMesh:
	var m := BoxMesh.new()
	m.size = size
	return m
