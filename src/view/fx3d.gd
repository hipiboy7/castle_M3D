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
		if it.size() > 6:
			it[0].scale = Vector3.ONE * lerpf(float(it[6]), float(it[5]), k * k)   # 퍼지는 고리: 처음 크기 → 끝 크기
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


## 퍼지는 고리 (바닥 충격파 · 주먹 충격): 반지름 r 의 띠를 s0 → s1 배로 키우며 흐려진다. up = 세운 고리(정면을 본다)
func ring(at: Vector3, yaw: float, r: float, width: float, col: Color, life: float, s0: float, s1: float, up := false) -> void:
	var m := _add_mat(col)
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, m)
	var n := 28
	for i in n + 1:
		var a := TAU * i / n
		var d := Vector3(cos(a), sin(a), 0) if up else Vector3(cos(a), 0, sin(a))
		im.surface_set_color(Color(0.15, 0.15, 0.15, 0.15))
		im.surface_add_vertex(d * (r - width))
		im.surface_set_color(Color(1, 1, 1, 1))
		im.surface_add_vertex(d * r)
	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = at
	mi.rotation.y = yaw
	mi.scale = Vector3.ONE * s0
	add_child(mi)
	_items.append([mi, life, life, m, m.albedo_color, s0, s1])


## 몸 둘레에서 솟는 입자 (엇엇박 부하) — 몸통 크기 상자에서 위로
func rise(at: Vector3, col: Color, amount: int, life: float) -> void:
	var p := CPUParticles3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.03, 0.09, 0.03)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = col
	mesh.material = m
	p.mesh = mesh
	p.amount = amount
	p.lifetime = life * 0.6
	p.one_shot = true
	p.explosiveness = 0.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = Vector3(0.32, 0.8, 0.32)
	p.direction = Vector3(0, 1, 0)
	p.spread = 15.0
	p.initial_velocity_min = 1.2
	p.initial_velocity_max = 2.6
	p.gravity = Vector3(0, 1.5, 0)
	p.particle_flag_align_y = true
	p.position = at + Vector3(0, 0.95, 0)
	add_child(p)
	p.emitting = true
	_items.append([p, life + 0.3, life + 0.3, null, 0.0])


## 엇엇박 브레이크: 온몸에 부하 — 붉은 기운이 솟고, 발밑에 고리가 퍼지고, 몸을 붉게 비춘다 (인형은 떨며 달아오른다)
func strain(f) -> void:
	var at := Vector3(f.pos.x, 0, f.pos.y)
	rise(at, Color(1.0, 0.35, 0.18), 46, 0.5)
	ring(at + Vector3(0, 0.04, 0), 0.0, 0.7, 0.18, Color(1.0, 0.4, 0.2, 0.8), 0.32, 0.4, 1.6)
	flash(at + Vector3(0, 1.1, 0), Color(1.0, 0.35, 0.2), 2.2, 0.45, 2.2)


## 각법 바닥 찍기: 발이 닿는 자리에 큰 충격파 두 겹 · 흙먼지 · 불빛
func slam(at: Vector3) -> void:
	ring(at + Vector3(0, 0.04, 0), 0.0, 0.6, 0.22, Color(1.0, 0.9, 0.7, 0.9), 0.38, 0.3, 3.6)
	ring(at + Vector3(0, 0.05, 0), 0.0, 0.6, 0.12, Color(1.0, 0.75, 0.45, 0.7), 0.55, 0.2, 2.4)
	spark(at + Vector3(0, 0.05, 0), Color(0.75, 0.68, 0.58), 40, 4.5, 0.45)
	spark(at + Vector3(0, 0.1, 0), Color(1.0, 0.85, 0.6), 16, 6.0, 0.3)
	flash(at + Vector3(0, 0.4, 0), Color(1.0, 0.8, 0.55), 2.5, 0.18, 3.0)


## 주먹 한 대: 맞은 자리에 세운 충격 고리 · 불꽃 (셋째 대는 크게)
func impact(at: Vector3, yaw: float, big: bool) -> void:
	var sc := 1.7 if big else 1.0
	ring(at, yaw, 0.32, 0.1, Color(1.0, 0.95, 0.8, 0.9), 0.2 * sc, 0.3, 1.6 * sc, true)
	if big:
		ring(at, yaw, 0.32, 0.06, Color(1.0, 0.7, 0.4, 0.8), 0.32, 0.2, 2.8, true)
	spark(at, Color(1.0, 0.9, 0.65), int(18 * sc), 5.0 * sc, 0.3)
	flash(at, Color(1.0, 0.8, 0.5), 0.8 * sc, 0.1, 1.8)


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
		"offbeat":
			# 엇박 · 엇엇박: 길고 굵은 찌르기 — 바깥 푸른 띠 + 안쪽 흰 심
			spike(at, yaw, 0.3, reach + radius + 0.55, 1.18, 0.13, Color(0.55, 0.75, 1.0, 0.8), 0.22)
			spike(at, yaw, 0.4, reach + radius + 0.45, 1.18, 0.05, steel, 0.16)
		"offbeat_rev":
			spike(at, yaw, 0.35, reach + radius + 0.15, 1.15, 0.07, Color(0.6, 0.8, 1.0, 0.75), 0.14)
		"axe":
			arc_v(at, yaw, 125.0, -30.0, 0.7, 1.2, 0.95, Color(1.0, 0.95, 0.85, 0.95), 0.26)
			var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
			slam(at + fwd * (reach + 0.15))
		"punch":
			spike(at, yaw, 0.3, reach + radius * 0.7, 1.25, 0.09, Color(1.0, 0.95, 0.85, 0.85), 0.12)
		"shot":
			# 총: 총구 불꽃 + 가는 탄 궤적(사거리 끝까지)
			var fwd2 := Vector3(-sin(yaw), 0, -cos(yaw))
			var muzzle := at + fwd2 * 0.75 + Vector3(0, 1.35, 0)
			flash(muzzle, Color(1.0, 0.8, 0.4), 3.0, 0.08, 3.0)
			spark(muzzle, Color(1.0, 0.85, 0.5), 10, 3.0, 0.12)
			spike(at, yaw, 0.8, reach, 1.35, 0.025, Color(1.0, 0.9, 0.6, 0.8), 0.08)
		_:
			_swing_more(mv, at, yaw, reach, radius, arc_deg, -1.0 if left_hand else 1.0)


## 맨손 · 발 · 잡기 · 무기 모양(src/view/poses.gd 2026-11-10 — 이름 끝 _L 은 없다, 왼쪽은 sg = -1 로 궤적을 뒤집는다).
## 모르는 모양은 효과음(sfx)으로 갈래를 고른다 — 칼(knife · slash) 베기 띠 · 발(kick) 굵은 쐐기 · 그 밖(주먹) 짧은 쐐기
func _swing_more(mv: Dictionary, at: Vector3, yaw: float, reach: float, radius: float, arc_deg: float, sg: float) -> void:
	var skin := Color(1.0, 0.95, 0.85, 0.85)
	var steel := Color(0.85, 0.92, 1.0, 0.9)
	var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
	match str(mv["shape"]):
		"jab", "straight", "palm", "guard_counter":
			spike(at, yaw, 0.3, reach + radius * 0.7, 1.28, 0.08, skin, 0.12)
		"body_blow":
			spike(at, yaw, 0.3, reach + radius * 0.6, 1.0, 0.09, skin, 0.12)
		"hook", "elbow", "backfist":
			var a := minf(arc_deg, 110.0) * 0.5
			var a0 := -a * sg if str(mv["shape"]) != "backfist" else a * sg   # 백피스트는 바깥으로 — 훅 · 팔꿈치와 반대
			arc(at, yaw, a0, -a0, reach * 0.35, reach + radius * 0.5, 1.25, skin, 0.14)
		"uppercut":
			arc_v(at, yaw, -40.0, 70.0, 0.25, 0.6, 1.0, skin, 0.16)
		"hammer_fist", "two_hand_slam":
			arc_v(at, yaw, 110.0, -20.0, 0.3, 0.75, 1.1, skin, 0.18)
		"headbutt", "shoulder_ram", "tackle", "grab", "choke":
			ring(at + fwd * (reach * 0.8) + Vector3(0, 1.1 if str(mv["shape"]) != "tackle" else 0.8, 0), yaw, 0.25, 0.08,
				Color(1.0, 0.95, 0.85, 0.7), 0.16, 0.4, 1.4, true)
		"knee", "flying_knee":
			spike(at, yaw, 0.3, reach + radius * 0.6, 1.05 if str(mv["shape"]) == "knee" else 1.3, 0.12, skin, 0.14)
		"front_kick", "spin_back_kick", "flying_kick":
			var h: float = {"front_kick": 1.0, "spin_back_kick": 1.05, "flying_kick": 1.4}[str(mv["shape"])]
			spike(at, yaw, 0.3, reach + radius + 0.2, h, 0.13, Color(1.0, 0.95, 0.85, 0.9), 0.18)
		"round_kick", "low_kick":
			var hk := 1.1 if str(mv["shape"]) == "round_kick" else 0.55
			var a2 := minf(arc_deg, 140.0) * 0.6
			arc(at, yaw, -a2 * sg, a2 * sg, reach * 0.4, reach + radius * 0.6, hk, Color(1.0, 0.95, 0.85, 0.9), 0.18)
		"sweep":
			arc(at, yaw, -150.0 * sg, 60.0 * sg, radius * 0.3, reach + radius * 0.6, 0.12, Color(1.0, 0.9, 0.75, 0.8), 0.24)
			spark(at + fwd * reach + Vector3(0, 0.05, 0), Color(0.75, 0.68, 0.58), 14, 3.0, 0.3)
		"axe_kick":
			arc_v(at, yaw, 115.0, -20.0, 0.6, 1.1, 0.9, Color(1.0, 0.95, 0.85, 0.95), 0.22)
		"stomp":
			ring(at + fwd * (reach * 0.8) + Vector3(0, 0.04, 0), 0.0, 0.4, 0.12, Color(1.0, 0.9, 0.7, 0.8), 0.3, 0.3, 1.8)
			spark(at + fwd * (reach * 0.8) + Vector3(0, 0.05, 0), Color(0.75, 0.68, 0.58), 16, 3.0, 0.3)
		"throw_slam":
			slam(at + fwd * (reach * 0.8))
		"overhead_chop":
			arc_v(at, yaw, 120.0, -25.0, 0.4, reach + radius * 0.5, 1.0, steel, 0.2)
		"rising_slash":
			arc_v(at, yaw, -30.0, 120.0, 0.4, reach + radius * 0.5, 1.0, steel, 0.2)
		"reverse_stab":
			arc_v(at, yaw, 80.0, 0.0, 0.3, reach + radius * 0.4, 1.1, steel, 0.16)
			spike(at, yaw, 0.35, reach + radius, 1.05, 0.06, steel, 0.12)
		"draw_shot":
			var muzzle := at + fwd * 0.75 + Vector3(0, 1.35, 0)
			flash(muzzle, Color(1.0, 0.8, 0.4), 3.0, 0.08, 3.0)
			spark(muzzle, Color(1.0, 0.85, 0.5), 10, 3.0, 0.12)
			spike(at, yaw, 0.8, reach, 1.35, 0.025, Color(1.0, 0.9, 0.6, 0.8), 0.08)
		"toss":
			spike(at, yaw, 0.6, reach + radius, 1.5, 0.04, Color(1.0, 0.95, 0.8, 0.7), 0.16)
			var land := at + fwd * (reach + radius * 0.5)
			if str(mv["fx"]) == "smoke":                             # 오울 연막 표식(054/024-025 보라 연막)
				rise(land + Vector3(0, 0.2, 0), Color(0.62, 0.45, 0.85, 0.75), 34, 1.6)
				ring(land, yaw, 0.6, 0.5, Color(0.6, 0.45, 0.85, 0.45), 1.2, 1.0, 2.6)
			elif str(mv["fx"]) == "blast":                           # 오울 수류탄(055/011-014)
				flash(land + Vector3(0, 0.5, 0), Color(1.0, 0.6, 0.25), 6.0, 0.22, 5.0)
				spark(land + Vector3(0, 0.4, 0), Color(1.0, 0.72, 0.3), 34, 6.0, 0.4)
				slam(land)
		"duck", "weave", "sidestep":
			pass                                                     # 피하기 — 궤적 없음
		_:
			var sfx := str(mv["sfx"])
			if sfx == "knife" or sfx == "slash":
				arc(at, yaw, -arc_deg * 0.6 * sg, arc_deg * 0.6 * sg, reach * 0.4, reach + radius * 0.6, 1.2, steel)
			elif sfx == "kick":
				spike(at, yaw, 0.3, reach + radius + 0.2, 1.0, 0.13, Color(1.0, 0.95, 0.85, 0.9), 0.18)
			else:
				spike(at, yaw, 0.3, reach + radius * 0.7, 1.25, 0.09, skin, 0.12)


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
