extends Node3D
## 타격 연출 — 불꽃(CPU 입자) · 번쩍이는 점광(주위 인물을 잠깐 비춘다) · 칼 궤적(초승달 띠) · 찌르기 쐐기 · 원형 난도질 고리.
## main.gd 가 combat/world.gd 신호(hit · parry · block · finish · dodge · feint)와 공격 시작을 보고 부른다.
## 연출은 판정과 따로라(전용 난수) 결투 결과에 영향이 없다.

const FONT = preload("res://assets/fonts/Galmuri11-Bold.ttf")

var _items: Array = []            # [노드, 남은 시간, 처음 시간, 재질 · 빛 · 글자, 처음 밝기 · 색]
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	rng.seed = 99


func _process(dt: float) -> void:
	for i in range(_items.size() - 1, -1, -1):
		var it: Array = _items[i]
		it[1] -= dt
		var k: float = maxf(0.0, it[1] / it[2])
		var thing = it[3]
		if thing is OmniLight3D:
			thing.light_energy = float(it[4]) * k * k
		elif thing is Label3D:
			thing.position.y += dt * 0.5
			var c: Color = it[4]
			thing.modulate = Color(c.r, c.g, c.b, minf(1.0, k * 2.5))
			thing.outline_modulate = Color(0, 0, 0, 0.85 * minf(1.0, k * 2.5))
		elif thing is StandardMaterial3D:
			thing.albedo_color = it[4] * k               # 처음 색에서 어둡게 — 더하기 섞기라 검정이 투명이다
		if it[1] <= 0.0:
			it[0].queue_free()
			_items.remove_at(i)


func _add_mat(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.vertex_color_use_as_albedo = true
	m.no_depth_test = false
	m.albedo_color = Color(col.r * col.a, col.g * col.a, col.b * col.a, col.a)   # 투명도를 색에 미리 곱한다
	return m


func spark(at: Vector3, col: Color, amount: int, speed: float, life := 0.32) -> void:
	var p := CPUParticles3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.022, 0.022, 0.11)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = col
	mesh.material = m
	p.mesh = mesh
	p.amount = amount
	p.lifetime = life
	p.one_shot = true
	p.explosiveness = 1.0
	p.direction = Vector3(0, 1, 0)
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.35
	p.initial_velocity_max = speed
	p.gravity = Vector3(0, -9.0, 0)
	p.particle_flag_align_y = true
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.3
	p.position = at
	add_child(p)
	p.emitting = true
	_items.append([p, life + 0.3, life + 0.3, null, 0.0])


func flash(at: Vector3, col: Color, energy: float, life := 0.14, reach := 4.0) -> void:
	var l := OmniLight3D.new()
	l.position = at
	l.light_color = col
	l.light_energy = energy
	l.omni_range = reach
	l.shadow_enabled = false
	add_child(l)
	_items.append([l, life, life, l, energy])


## 칼 궤적: 공격하는 사람 발 위치 · 방향(yaw) 기준으로 a0 → a1(도, 0 = 정면, + 왼쪽) 초승달. 끝으로 갈수록 밝다
func arc(at: Vector3, yaw: float, a0: float, a1: float, r_in: float, r_out: float, h: float, col: Color, life := 0.16) -> void:
	var m := _add_mat(col)
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, m)
	var n := 18
	for i in n + 1:
		var u := float(i) / n
		var a := deg_to_rad(lerpf(a0, a1, u))
		var d := Vector3(-sin(a), 0, -cos(a))
		var w := 0.28 + 0.22 * sin(u * PI)               # 띠 폭: 바깥 가장자리에서 안쪽 반지름까지의 28 ~ 50 %
		var v := u * u * 0.55                            # 더하기 섞기: 투명도에 기대지 않고 색을 어둡게 한다(run #4 · #5 에서 투명도만으로는 흰 판, T-5)
		var c := Color(v, v, v, v)
		im.surface_set_color(c)
		im.surface_add_vertex(d * lerpf(r_out, r_in, w) + Vector3(0, h - 0.04 * u, 0))
		im.surface_set_color(c)
		im.surface_add_vertex(d * r_out + Vector3(0, h, 0))
	im.surface_end()
	_place(im, m, at, yaw, life)


## 세로 궤적 (각법 내려찍기): 정면 세로면에서 a0 → a1(도, 0 = 정면 수평, 90 = 머리 위), 가운데 높이 h
func arc_v(at: Vector3, yaw: float, a0: float, a1: float, r_in: float, r_out: float, h: float, col: Color, life := 0.2) -> void:
	var m := _add_mat(col)
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, m)
	var n := 16
	for i in n + 1:
		var u := float(i) / n
		var a := deg_to_rad(lerpf(a0, a1, u))
		var d := Vector3(0, sin(a), -cos(a))
		var v := u * u * 0.55
		var c := Color(v, v, v, v)
		im.surface_set_color(c)
		im.surface_add_vertex(d * r_in + Vector3(0, h, -0.2))
		im.surface_set_color(c)
		im.surface_add_vertex(d * r_out + Vector3(0, h, -0.2))
	im.surface_end()
	_place(im, m, at, yaw, life)


## 떠오르며 사라지는 글자 (엇박 % · 기절 · 가드 관통 · 삼연타 번호 · 기술 이름)
func pop(at: Vector3, text: String, col: Color, size := 64, life := 0.9) -> void:
	var l := Label3D.new()
	l.font = FONT
	l.text = text
	l.font_size = size
	l.outline_size = 16
	l.outline_modulate = Color(0, 0, 0, 0.85)
	l.pixel_size = 0.0045
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.modulate = col
	l.position = at
	add_child(l)
	_items.append([l, life, life, l, col])


## 찌르기 · 차기 쐐기: 정면으로 r0 → r1, 뿌리 폭 w
func spike(at: Vector3, yaw: float, r0: float, r1: float, h: float, w: float, col: Color, life := 0.14) -> void:
	var m := _add_mat(col)
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, m)
	var a := Vector3(-w, h, -r0)
	var b := Vector3(w, h, -r0)
	var c := Vector3(0, h, -r1)
	var a2 := Vector3(0, h + w, -r0)
	var b2 := Vector3(0, h - w, -r0)
	for tri in [[a, b, c], [a2, b2, c]]:
		for k in 3:
			var v := 0.25 if k < 2 else 1.0
			im.surface_set_color(Color(v, v, v, v))
			im.surface_add_vertex(tri[k])
	im.surface_end()
	_place(im, m, at, yaw, life)


func _place(mesh: Mesh, m: StandardMaterial3D, at: Vector3, yaw: float, life: float) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = at
	mi.rotation.y = yaw
	add_child(mi)
	_items.append([mi, life, life, m, m.albedo_color])


## 기술 모양별 궤적 (Move.shape) — 공격 판정이 시작되는 프레임에 부른다
func swing(f, yaw: float, left_hand: bool) -> void:
	var mv: Dictionary = f.move
	var at := Vector3(f.pos.x, 0, f.pos.y)
	var reach: float = mv["reach"]
	var radius: float = mv["radius"]
	var arc_deg: float = maxf(60.0, float(mv["arc"]))
	var steel := Color(0.85, 0.92, 1.0, 0.9)
	match str(mv["shape"]):
		"slash":
			arc(at, yaw, -arc_deg * 0.6, arc_deg * 0.6, reach * 0.4, reach + radius * 0.6, 1.2, steel)
		"slash_back":
			arc(at, yaw, arc_deg * 0.6, -arc_deg * 0.6, reach * 0.4, reach + radius * 0.6, 1.15, steel)
		"thrust", "thrust_low":
			var h := 1.2 if str(mv["shape"]) == "thrust" else 0.92
			spike(at, yaw, 0.35, reach + radius + 0.15, h, 0.07, steel)
		"sidekick":
			spike(at, yaw, 0.3, reach + radius + 0.2, 0.95, 0.13, Color(1.0, 0.95, 0.85, 0.9), 0.18)
		"spin":
			for k in 3:
				arc(at, yaw + k * 2.1, 0.0, 300.0, radius * 0.8, radius, 0.95 + k * 0.08, Color(1.0, 0.5, 0.45, 0.5), 0.42)
		"cross":
			arc(at, yaw, -70, 70, reach * 0.3, reach + radius, 1.45, Color(1.0, 0.85, 0.5, 1.0), 0.24)
			arc(at, yaw, 70, -70, reach * 0.3, reach + radius, 0.9, Color(1.0, 0.85, 0.5, 1.0), 0.24)
		"axe":
			arc_v(at, yaw, 110.0, -20.0, 0.75, 1.05, 0.95, Color(1.0, 0.95, 0.85, 0.9), 0.22)
		"punch":
			spike(at, yaw, 0.3, reach + radius * 0.5, 1.25, 0.06, Color(1.0, 0.95, 0.85, 0.8), 0.1)
	if left_hand:
		pass


## 엇박 멈칫: 앞으로 찌르는 척한 잔상(흐린 쐐기)만 남긴다
func feint(f, yaw: float) -> void:
	var mv: Dictionary = f.move
	spike(Vector3(f.pos.x, 0, f.pos.y), yaw, 0.35, float(mv["reach"]) * 0.7, 1.2, 0.05, Color(0.6, 0.75, 1.0, 0.45), 0.22)


func hit(at: Vector3, heavy: bool) -> void:
	spark(at, Color(1.0, 0.78, 0.45), 22 if heavy else 12, 5.5 if heavy else 4.0)
	flash(at, Color(1.0, 0.7, 0.4), 1.0 if heavy else 0.6, 0.1, 1.6)   # 몸 전체를 비추지 않게 약하고 좁게(폰 리뷰 2026-10-26)


func parry(at: Vector3) -> void:
	spark(at, Color(0.75, 0.88, 1.0), 34, 7.5, 0.4)
	spark(at, Color(1.0, 1.0, 1.0), 10, 3.0, 0.2)
	flash(at, Color(0.65, 0.8, 1.0), 6.0, 0.2, 5.0)


func block(at: Vector3) -> void:
	spark(at, Color(0.9, 0.9, 1.0), 10, 3.5)
	flash(at, Color(0.8, 0.85, 1.0), 1.6)


func finish(at: Vector3) -> void:
	spark(at, Color(1.0, 0.85, 0.5), 46, 8.0, 0.5)
	flash(at, Color(1.0, 0.8, 0.5), 8.0, 0.3, 6.0)
