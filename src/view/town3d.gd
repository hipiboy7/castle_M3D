extends "res://src/view/set3d.gd"
## 0 · 1장 무대(1부 처음 — 블라디보스토크 호텔 · 회암시) — 방(src/data/prologue.gd · hoeam.gd ROOMS theme)마다 바닥 · 벽 · 소품 · 빛.
## 그리는 도구(_env · _top · _sun · _floor · _ground · _omni · _shared …)는 src/view/set3d.gd(호텔 무대와 같이 쓴다). build(theme, bounds, detail) 는 같다(LSP).
## 카메라는 +z 쪽 위에서 내려다본다(camera_rig OFFSET) — 화면 위쪽 띠에는 뒤(-z) 벽 · 건물의 아래 1 ~ 3m 만 보이므로 볼거리(문 · 간판 ·
## 창 불빛)는 낮게, 걸을 곳(bounds) 바로 뒤에 둔다. 걸을 곳 안에는 납작한 것(카펫 · 선 · 얼룩)만, 높은 소품은 밖에(앞 +z 쪽은 비운다).
## 같은 무대 이름을 크기가 다른 방이 쓴다(hoeam_street 셋) — 자리는 모두 bounds 에서 잰다.
## 원작 근거(castle_common canon — 화/컷, 모양은 conf ai 판독이라 연출에만):
##   vlad_corridor  밤의 호텔 복도, 경호원들이 권총 · 우지 난사(p1:002/013-020) — 붉은 카펫 · 객실 문 · 벽등 · 벽의 총알 자국 · 탄피
##   gunter_suite   군터의 방 '최후의 만찬 그림 · 아치 창'(p1:002/021-029) — 탁자(밑에서 리볼버) · 위스키 병 · 잔('까앙' 깨지는 잔) · 시가,
##                  창밖은 눈 오는 밤 도시
##   vlad_night     경찰차가 몰린 밤거리(p1:002/029-031) — 호텔 정문(간판 Владивосток гостиница — 글꼴에 키릴 문자가 없어 라틴 글자) · 눈
##   site_alley     회암시 공사장(굴착기 있는 골목 — fight:kimhyeokju, 밤거리를 걸어 온다 p1:003/023) — 굴착기 · 가설 울타리 · 벽돌 벽
##                  (칼이 '뒤쪽 벽에 꽂힘')
##   junkyard_*     부진폐차장(locations bujinpyechajang) — 폐차가 겹겹이 쌓인 공터(p1:009/009) · 컨테이너 사무실(007/006-011) ·
##                  리프트 위 폐차(007/024) · 드럼통(010/016) · 승합차(김신이 처박힘 008/004-007) · 간판(007/013).
##                  밤(fight:pyechajang) / 노을(fight:kimdaegeon_pyechajang p1:014 '노을 아래' — 해가 낮아 그림자가 길다)
##   hoeam_street   회암시 거리(낮 — fight:yundeoksu p1:018-020) — 아스팔트 · 노란 겹 중앙선(020/000-002) · 상가(HOLLSY COFFEE 020/057) ·
##                  세워 둔 차 · 횡단보도. 중앙선은 걸을 곳 가운데(z) — 길은 x 로 달리고 상가가 뒤에 선다
## 폰 성능: 점광 3개 이하 · 그림자는 해(달) 하나 · 같은 값 재질은 하나(_shared) · 결은 작은 그림(64px 이하) 하나를 되풀이 · 무대마다
##   메시 90 ~ 190 개(가장 많은 군터의 방은 창밖 도시 몫 — 11장 71층 복도 160 과 같은 급) · 눈 입자 260 ~ 420 개 · 만드는 데 6ms 안.
##   상세(detail — 헤드리스는 끔)일 때만 그림자 · 내리는 눈(입자) · 땅 결 · 작은 소품(탄피 · 총알 자국 · 얼룩)

## 이 그림이 그리는 무대 이름(시험 test_campaign 이 장 표의 theme 이 여기 있는지 본다)
const THEMES := ["vlad_corridor", "gunter_suite", "vlad_night", "site_alley", "junkyard_night", "junkyard_dusk", "hoeam_street"]

const FONT = preload("res://assets/fonts/Galmuri11-Bold.ttf")

## 경광등(vlad_night) — [빨강 재질, 파랑 재질, 빨강 점광, 파랑 점광]. 그림만(판정과 상관없음)
var _siren: Array = []
var _t := 0.0


func build(th: String, b: Rect2, detail := true) -> void:
	theme = th
	_detail = detail
	match th:
		"vlad_corridor":
			_vlad_corridor(b)
		"gunter_suite":
			_gunter_suite(b)
		"vlad_night":
			_vlad_night(b)
		"site_alley":
			_site_alley(b)
		"junkyard_night":
			_junkyard(b, false)
		"junkyard_dusk":
			_junkyard(b, true)
		"hoeam_street":
			_hoeam_street(b)


## 경광등 — 빨강 · 파랑이 번갈아, 각각 빠르게 두 번씩 번쩍
func _process(dt: float) -> void:
	if _siren.is_empty():
		return
	_t += dt
	var half := fmod(_t * 1.4, 1.0) < 0.5
	var pulse := fmod(_t * 5.6, 1.0) < 0.55
	var red_on := half and pulse
	var blue_on := (not half) and pulse
	_siren[0].emission_energy_multiplier = 6.0 if red_on else 0.25
	_siren[1].emission_energy_multiplier = 6.0 if blue_on else 0.25
	_siren[2].light_energy = 3.0 if red_on else 0.0
	_siren[3].light_energy = 3.4 if blue_on else 0.0


# ======================== 0장 프롤로그 — 블라디보스토크 ========================

## 호텔 복도(밤) — 짙은 초록 벽지 · 나무 판벽 · 붉은 카펫 · 객실 문 넷 · 벽등 다섯 · 오른쪽 끝 군터 방 문
func _vlad_corridor(b: Rect2) -> void:
	var cx := b.get_center().x
	var wz := b.position.y - 0.8 + 0.15               # 뒷벽 앞면(_back_wall 두께 0.3)
	var w := b.size.x + 4.0
	_env(Color(0.3, 0.24, 0.2), 0.6, Color(0.02, 0.015, 0.015))
	_top(Color(1.0, 0.86, 0.68), 0.5)
	_floor(b, Color(0.2, 0.12, 0.07), 0.4, false)
	_back_wall(b, Color(0.13, 0.19, 0.15), 3.2)
	var g1 := Color(0.12, 0.18, 0.14)
	var g2 := Color(0.16, 0.24, 0.18)
	var gold := Color(0.36, 0.3, 0.17)
	var paper := _stripe_tex([g1, g1, g1, g2, g2, g2, gold, g2, g2, g2, g1, g1])     # 벽지(짙은 초록 줄 + 금줄)
	var wd := Color(0.22, 0.12, 0.07)
	var wood := _stripe_tex([wd, wd, wd, wd, wd, wd, wd, wd, wd.darkened(0.45)])       # 허리 판벽(0.9m 마다 이음)
	_panel(Vector3(cx, 2.11, wz + 0.004), Vector2(w, 2.18), paper,
		Vector2(w / 0.6, 1), Color.WHITE, 0.85)
	_panel(Vector3(cx, 0.55, wz + 0.006), Vector2(w, 0.9), wood,
		Vector2(w / 0.9, 1), Color.WHITE, 0.45)
	var brass := _shared(Color(0.62, 0.46, 0.22), 0.35, 0.0, 0.6)
	_mesh(self, _box(Vector3(w, 0.07, 0.06)), brass, Vector3(cx, 1.02, wz + 0.03))          # 허리띠
	_runner(Rect2(b.position.x - 0.5, b.get_center().y - 1.0, b.size.x + 0.95, 2.0))
	for sx in [-1.0, 1.0]:                                                                 # 복도 양 끝 벽(높게 — 옆이라 가리지 않는다)
		var ex: float = b.position.x - 0.62 if sx < 0.0 else b.end.x + 0.62
		var ez := (wz + b.end.y + 0.8) * 0.5
		var ed := b.size.y + 1.6
		_mesh(self, _box(Vector3(0.2, 3.2, ed)), _shared(g1, 0.85), Vector3(ex, 1.6, ez))
		var face: float = ex - sx * 0.105                                                       # 안쪽 면 — 벽지 · 판벽을 같이
		_panel(Vector3(face, 2.11, ez), Vector2(ed, 2.18), paper,
			Vector2(ed / 0.6, 1), Color.WHITE, 0.85, -90.0 * sx)
		_panel(Vector3(face - sx * 0.002, 0.55, ez), Vector2(ed, 0.9), wood,
			Vector2(ed / 0.9, 1), Color.WHITE, 0.45, -90.0 * sx)
	var doors := [cx - 5.4, cx - 1.8, cx + 1.8, cx + 5.4]
	for i in doors.size():
		_room_door(Vector3(doors[i], 0, wz), str(501 + i * 2))
	for i in 5:
		_wall_lamp(Vector3(cx - 7.2 + i * 3.6, 1.72, wz))
	for x in [cx - 3.6, cx + 3.6]:
		_console(Vector3(x, 0, wz))
	_double_door(Vector3(b.end.x + 0.45, 0, b.get_center().y))                                 # 군터의 방으로
	for x in [cx - 3.6, cx, cx + 3.6]:
		_omni(Vector3(x, 2.0, wz + 0.5), Color(1.0, 0.74, 0.46), 1.5, 5.5)
	if not _detail:
		return
	# 난사 자국(원작 002/013-015 '타타타타') — 벽 · 문의 총알 자국, 바닥의 탄피(오른쪽 — 경호원들이 선 쪽)
	var r := RandomNumberGenerator.new()
	r.seed = 2
	var hole := _shared(Color(0.03, 0.025, 0.02), 0.95)
	var n := 0
	while n < 16:
		var x := cx + r.randf_range(-0.5, 6.8)
		var on_door := false
		for d in doors:
			on_door = on_door or absf(x - float(d)) < 0.66
		var h := _mesh(self, _cyl(0.028, 0.028, 0.01), hole, Vector3(x, r.randf_range(0.75, 2.4), wz + (0.1 if on_door else 0.012)))
		h.rotation_degrees.x = 90
		n += 1
	var shell := _shared(Color(0.82, 0.62, 0.26), 0.3, 0.0, 0.9)
	for i in 20:
		var c := _mesh(self, _cyl(0.012, 0.012, 0.045), shell,
			Vector3(cx + r.randf_range(0.8, 6.6), 0.02, r.randf_range(b.position.y + 0.2, b.end.y - 0.2)))
		c.rotation_degrees = Vector3(0, r.randf() * 360.0, 90)


## 복도 카펫 — 붉은 바탕 · 금빛 마름모가 1m 마다(그림 하나를 되풀이), 가장자리 금줄
func _runner(r: Rect2) -> void:
	var m := _mat(Color.WHITE, 0.95)
	m.albedo_texture = _carpet_tex()
	m.uv1_scale = Vector3(r.size.x / 1.0, 1, 1)
	var pm := PlaneMesh.new()
	pm.size = r.size
	_mesh(self, pm, m, Vector3(r.get_center().x, 0.006, r.get_center().y))


func _carpet_tex() -> ImageTexture:
	var img := Image.create(16, 32, false, Image.FORMAT_RGB8)
	var field := Color(0.36, 0.06, 0.07)
	var dark := Color(0.14, 0.03, 0.03)
	var gold := Color(0.58, 0.44, 0.18)
	for y in 32:
		for x in 16:
			var c := field
			var d := absf(x - 7.5) * 2.0 + absf(y - 15.5)
			if y <= 1 or y >= 30:
				c = dark
			elif y == 2 or y == 29:
				c = gold
			elif y <= 4 or y >= 27:
				c = Color(0.24, 0.05, 0.05) if (x + y) % 4 < 2 else dark
			elif d > 8.0 and d < 10.5:
				c = gold
			elif d < 4.0:
				c = Color(0.12, 0.1, 0.22)
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## 객실 문(짙은 나무 · 판 둘 · 놋쇠 손잡이 · 번호판)
func _room_door(at: Vector3, num: String) -> void:
	var trim := _shared(Color(0.34, 0.2, 0.1), 0.45)
	var leaf := _shared(Color(0.19, 0.1, 0.055), 0.4)
	var pan := _shared(Color(0.25, 0.14, 0.08), 0.4)
	var brass := _shared(Color(0.85, 0.66, 0.3), 0.3, 0.0, 0.85)
	_mesh(self, _box(Vector3(1.26, 2.36, 0.05)), trim, at + Vector3(0, 1.18, 0.025))
	_mesh(self, _box(Vector3(1.04, 2.22, 0.05)), leaf, at + Vector3(0, 1.11, 0.05))
	for y in [0.62, 1.58]:
		_mesh(self, _box(Vector3(0.76, 0.78, 0.02)), pan, at + Vector3(0, y, 0.085))
	_mesh(self, _sphere(0.045), brass, at + Vector3(0.4, 1.02, 0.11))
	_mesh(self, _box(Vector3(0.28, 0.13, 0.012)), brass, at + Vector3(0, 1.62, 0.1))
	_label(at + Vector3(0, 1.62, 0.108), num, Color(0.16, 0.08, 0.03), 26, 0.004)


## 벽등(놋쇠 받침 · 빛나는 갓)
func _wall_lamp(at: Vector3) -> void:
	var brass := _shared(Color(0.8, 0.6, 0.28), 0.3, 0.0, 0.8)
	_mesh(self, _box(Vector3(0.12, 0.24, 0.03)), brass, at + Vector3(0, -0.04, 0.015))
	_mesh(self, _box(Vector3(0.04, 0.04, 0.16)), brass, at + Vector3(0, -0.08, 0.09))
	_mesh(self, _cyl(0.08, 0.12, 0.2), _glow(Color(1.0, 0.72, 0.42), 1.3), at + Vector3(0, 0.04, 0.17))


## 벽 탁자(꽃병)
func _console(at: Vector3) -> void:
	var wood := _shared(Color(0.17, 0.09, 0.05), 0.35)
	_mesh(self, _box(Vector3(1.1, 0.05, 0.3)), wood, at + Vector3(0, 0.82, 0.16))
	_mesh(self, _box(Vector3(1.0, 0.16, 0.26)), wood, at + Vector3(0, 0.72, 0.15))
	for sx in [-0.47, 0.47]:
		_mesh(self, _box(Vector3(0.05, 0.64, 0.05)), wood, at + Vector3(sx, 0.32, 0.26))
	_mesh(self, _cyl(0.06, 0.09, 0.3), _shared(Color(0.75, 0.78, 0.85), 0.2), at + Vector3(0.24, 1.0, 0.15))
	_mesh(self, _sphere(0.11), _shared(Color(0.14, 0.26, 0.12), 0.9), at + Vector3(0.24, 1.2, 0.13))     # 잎
	var bloom := _shared(Color(0.62, 0.1, 0.14), 0.8)
	for p in [Vector3(0.16, 1.27, 0.18), Vector3(0.3, 1.3, 0.16), Vector3(0.24, 1.22, 0.25)]:
		_mesh(self, _sphere(0.055), bloom, at + p)


## 군터의 방 — 붉은 벽 · 아치 창 둘(밖은 눈 오는 밤 도시) · 가운데 '최후의 만찬' · 탁자(위스키 · 시가 · 은행 등) · 가죽 소파 · 장식장
func _gunter_suite(b: Rect2) -> void:
	var cx := b.get_center().x
	var cz := b.get_center().y
	var wz := b.position.y - 1.05                    # 뒷벽 가운데(앞면 wz + 0.15) — 벽과 걸을 곳 사이에 탁자
	var half := b.size.x * 0.5 + 1.6
	var hh := 3.6
	_env(Color(0.3, 0.22, 0.17), 0.6, Color(0.01, 0.012, 0.025))
	_top(Color(1.0, 0.85, 0.66), 0.5)
	_floor(Rect2(b.position.x, b.position.y - 0.8, b.size.x, b.size.y + 0.8), Color(0.13, 0.075, 0.045), 0.35, false)
	var outer := PlaneMesh.new()                       # 옆벽 너머(방 밖)도 어둡게 — 창밖 도시는 뒷벽 뒤(아래)에만 보인다
	outer.size = Vector2(80.0, 30.0)
	_mesh(self, outer, _shared(Color(0.03, 0.02, 0.02), 1.0), Vector3(cx, -0.02, wz + 15.0))
	_persian(Rect2(cx - 3.4, cz - 1.8, 6.8, 3.6))
	var wall := _shared(Color(0.3, 0.12, 0.09), 0.8)
	var ww := half * 2.0
	_mesh(self, _box(Vector3(ww, 0.45, 0.3)), wall, Vector3(cx, 0.225, wz))                   # 창 밑
	_mesh(self, _box(Vector3(ww, hh - 2.45, 0.3)), wall, Vector3(cx, (2.45 + hh) * 0.5, wz))   # 창 위
	for seg in [[-half, -4.0], [-2.4, 2.4], [4.0, half]]:
		var sw: float = seg[1] - seg[0]
		_mesh(self, _box(Vector3(sw, 2.0, 0.3)), wall, Vector3(cx + (seg[0] + seg[1]) * 0.5, 1.45, wz))
	var trim := _shared(Color(0.42, 0.3, 0.15), 0.4, 0.0, 0.5)
	_mesh(self, _box(Vector3(ww, 0.14, 0.34)), trim, Vector3(cx, 0.07, wz + 0.02))
	for sx in [-1.0, 1.0]:                                                                       # 옆벽(낮게)
		_mesh(self, _box(Vector3(0.3, 1.2, b.size.y + 2.6)), wall, Vector3(cx + sx * half, 0.6, cz - 0.5))
	for sx in [-1.0, 1.0]:
		_arch_window(Vector3(cx + 3.2 * sx, 0, wz), 1.6, 0.45, 2.45, hh)
	_last_supper(Vector3(cx, 1.45, wz + 0.15))
	_snow_city(wz - 1.0, ww + 30.0)
	_snow(Vector3(cx, -2.5, wz - 5.0), Vector3(half + 2.0, 5.0, 4.0), 260)
	# 탁자 — 군터 자리(2.6, -0.4) 뒤. 의자는 옆으로 밀려 있다(일어나 리볼버를 뽑았다)
	var tx := cx + 2.2
	_gunter_table(Vector3(tx, 0, b.position.y - 0.42))
	_armchair(Vector3(tx + 1.55, 0, b.position.y - 0.5), -70.0)
	_chesterfield(Vector3(b.position.x - 0.95, 0, cz - 0.1), 90.0)
	_floor_lamp(Vector3(b.position.x - 0.9, 0, cz - 1.75))
	_sideboard(Vector3(b.end.x + 0.85, 0, cz + 0.4))
	_omni(Vector3(b.position.x - 0.6, 1.9, cz - 1.5), Color(1.0, 0.74, 0.46), 1.2, 5.5)
	_omni(Vector3(tx + 0.5, 1.6, b.position.y - 0.1), Color(1.0, 0.8, 0.55), 1.3, 5.0)
	_omni(Vector3(cx, 2.2, wz + 1.0), Color(0.5, 0.6, 1.0), 0.9, 8.0)                    # 창으로 드는 밤빛


func _persian(r: Rect2) -> void:
	var m := _mat(Color.WHITE, 0.95)
	m.albedo_texture = _persian_tex()
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	var pm := PlaneMesh.new()
	pm.size = r.size
	_mesh(self, pm, m, Vector3(r.get_center().x, 0.006, r.get_center().y))


## 페르시아 양탄자 그림(64x32 — 점 하나 약 10cm) — 남색 테두리(금 무늬) · 금줄 · 붉은 바탕(작은 점 격자) · 가운데 겹 마름모 · 귀퉁이
func _persian_tex() -> ImageTexture:
	var img := Image.create(64, 32, false, Image.FORMAT_RGB8)
	var navy := Color(0.07, 0.08, 0.15)
	var gold := Color(0.42, 0.32, 0.14)
	var red := Color(0.27, 0.05, 0.045)
	var ivory := Color(0.52, 0.46, 0.35)
	for y in 32:
		for x in 64:
			var e := mini(mini(x, 63 - x), mini(y, 31 - y))
			var d := absf(x - 31.5) * 0.5 + absf(y - 15.5)
			var dc := minf(absf(x - 0.0) * 0.5 + absf(y - 0.0), absf(x - 63.0) * 0.5 + absf(y - 0.0))
			dc = minf(dc, minf(absf(x - 0.0) * 0.5 + absf(y - 31.0), absf(x - 63.0) * 0.5 + absf(y - 31.0)))
			var c := red
			var along := x if (y <= 4 or y >= 27) else y          # 테두리를 따라가는 자리
			if e == 0:
				c = gold.darkened(0.3)
			elif e <= 4:
				c = gold if (e == 2 and along % 4 != 0) or ((e == 1 or e == 3) and along % 4 == 2) else navy   # 금 사슬 무늬
			elif e == 5:
				c = gold
			elif d < 2.5:
				c = ivory
			elif d < 4.5:
				c = navy
			elif d < 5.5:
				c = gold
			elif d < 8.5:
				c = red.darkened(0.35) if int(d) % 2 else red
			elif d < 9.5:
				c = gold.darkened(0.2)
			elif dc < 10.5:
				c = navy if dc > 9.5 or dc < 8.0 else red.darkened(0.3)
			elif x % 6 == 3 and y % 4 == 2:
				c = gold.darkened(0.25)
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## 아치 창 — 유리 · 흰 창틀 · 세로살 · 가로살 · 반원(아치) · 벨벳 커튼
func _arch_window(at: Vector3, w: float, y0: float, y1: float, hh: float) -> void:
	var frame := _shared(Color(0.82, 0.78, 0.7), 0.5)
	var glass := _mat(Color(0.55, 0.65, 0.9, 0.12), 0.05, 0.4, 0.0)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var h := y1 - y0
	_mesh(self, _box(Vector3(w, h, 0.02)), glass, at + Vector3(0, y0 + h * 0.5, 0))
	_mesh(self, _box(Vector3(w + 0.16, 0.08, 0.4)), frame, at + Vector3(0, y0, 0.02))          # 창턱
	for sx in [-1.0, 1.0]:
		_mesh(self, _box(Vector3(0.08, h, 0.1)), frame, at + Vector3(sx * w * 0.5, y0 + h * 0.5, 0.12))
	_mesh(self, _box(Vector3(0.05, h, 0.06)), frame, at + Vector3(0, y0 + h * 0.5, 0.0))
	_mesh(self, _box(Vector3(w, 0.05, 0.06)), frame, at + Vector3(0, y0 + h * 0.64, 0.0))
	var arch := _mat(Color(0.08, 0.1, 0.18), 0.1)
	arch.emission_enabled = true
	arch.emission = Color(0.12, 0.16, 0.3)
	arch.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mesh(self, _arc(0.0, w * 0.5, 12), arch, at + Vector3(0, y1, 0.16))
	var ring := _mat(Color(0.82, 0.78, 0.7), 0.5)
	ring.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mesh(self, _arc(w * 0.5 - 0.06, w * 0.5 + 0.04, 12), ring, at + Vector3(0, y1, 0.17))
	var cur := _shared(Color(0.3, 0.04, 0.05), 0.9)
	for sx in [-1.0, 1.0]:
		_mesh(self, _box(Vector3(0.34, hh - 0.2, 0.14)), cur, at + Vector3(sx * (w * 0.5 + 0.22), (hh - 0.2) * 0.5, 0.24))


## 반원 고리(r_in = 0 이면 반원판) — xy 평면, 위쪽 반
func _arc(r_in: float, r_out: float, segs: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in segs:
		var a0 := PI * i / segs
		var a1 := PI * (i + 1) / segs
		var d0 := Vector3(cos(a0), sin(a0), 0)
		var d1 := Vector3(cos(a1), sin(a1), 0)
		for v in [d0 * r_in, d0 * r_out, d1 * r_out, d0 * r_in, d1 * r_out, d1 * r_in]:
			st.set_normal(Vector3(0, 0, 1))
			st.add_vertex(v)
	return st.commit()


## '최후의 만찬'(원작 002/021-029 군터의 방 벽) — 금테 · 작은 그림(48x20) · 그림 등
func _last_supper(at: Vector3) -> void:
	_mesh(self, _box(Vector3(2.5, 1.18, 0.06)), _shared(Color(0.75, 0.58, 0.25), 0.35, 0.0, 0.8), at + Vector3(0, 0, 0.03))
	var m := _mat(Color.WHITE, 0.8)
	m.albedo_texture = _supper_tex()
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	var q := QuadMesh.new()
	q.size = Vector2(2.3, 1.0)
	_mesh(self, q, m, at + Vector3(0, 0, 0.065))
	_mesh(self, _box(Vector3(0.5, 0.04, 0.07)), _glow(Color(0.9, 0.72, 0.45), 0.7), at + Vector3(0, 0.65, 0.1))


func _supper_tex() -> ImageTexture:
	var img := Image.create(48, 20, false, Image.FORMAT_RGB8)
	img.fill(Color(0.36, 0.3, 0.2))
	img.fill_rect(Rect2i(0, 0, 48, 3), Color(0.2, 0.16, 0.1))                 # 천장
	img.fill_rect(Rect2i(0, 3, 6, 10), Color(0.26, 0.21, 0.14))               # 옆벽(원근)
	img.fill_rect(Rect2i(42, 3, 6, 10), Color(0.26, 0.21, 0.14))
	var sky := Color(0.72, 0.74, 0.64)
	img.fill_rect(Rect2i(21, 4, 6, 7), sky)                                   # 뒤 창 셋(가운데가 크다)
	img.fill_rect(Rect2i(15, 5, 3, 5), sky)
	img.fill_rect(Rect2i(30, 5, 3, 5), sky)
	img.fill_rect(Rect2i(0, 17, 48, 3), Color(0.24, 0.19, 0.13))              # 바닥
	var robes := [Color(0.55, 0.15, 0.1), Color(0.2, 0.3, 0.5), Color(0.3, 0.42, 0.25), Color(0.62, 0.46, 0.2), Color(0.45, 0.3, 0.4)]
	var skin := Color(0.8, 0.6, 0.44)
	var xs := [4, 7, 10, 14, 17, 20, 28, 31, 34, 37, 40, 43]                 # 열둘 — 셋씩 넷 무리
	for i in xs.size():
		var x: int = xs[i]
		var y := 9 + (i % 2)
		img.fill_rect(Rect2i(x - 1, y + 1, 3, 4), robes[i % robes.size()])
		img.fill_rect(Rect2i(x, y - 1, 2, 2), skin)
	img.fill_rect(Rect2i(23, 9, 3, 5), Color(0.6, 0.1, 0.08))                # 가운데(붉은 옷 · 푸른 겉옷)
	img.fill_rect(Rect2i(22, 10, 1, 4), Color(0.15, 0.25, 0.55))
	img.fill_rect(Rect2i(26, 10, 1, 4), Color(0.15, 0.25, 0.55))
	img.fill_rect(Rect2i(23, 7, 3, 2), skin)
	img.fill_rect(Rect2i(3, 13, 42, 2), Color(0.84, 0.8, 0.7))                # 식탁(흰 천)
	img.fill_rect(Rect2i(3, 15, 42, 2), Color(0.3, 0.22, 0.13))
	return ImageTexture.create_from_image(img)


## 창밖 눈 오는 밤 도시(이 방은 높은 층 — 건물 지붕이 발밑 아래로). 눈 덮인 지붕 · 불 켜진 창 · 아래 거리 가로등 줄. 결정적(seed)
func _snow_city(z0: float, width: float) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 3
	var body := _shared(Color(0.07, 0.08, 0.11), 0.9)
	var roof := _shared(Color(0.72, 0.77, 0.88), 0.9)
	var lit := _glow(Color(1.0, 0.8, 0.5), 2.0)
	var n := 26 if _detail else 12
	for i in n:
		var x := r.randf_range(-width * 0.5, width * 0.5)
		var z := z0 - r.randf_range(4.0, 28.0)
		var w := r.randf_range(2.0, 5.0)
		var top := r.randf_range(-13.0, -3.5)
		_mesh(self, _box(Vector3(w, 30.0, w)), body, Vector3(x, top - 15.0, z))
		_mesh(self, _box(Vector3(w + 0.1, 0.16, w + 0.1)), roof, Vector3(x, top + 0.05, z))
		for k in 3:
			if r.randf() < 0.75:
				_mesh(self, _box(Vector3(w * 0.3, 0.32, 0.05)), lit, Vector3(x + r.randf_range(-w * 0.3, w * 0.3), top - 1.0 - k * 1.5, z + w * 0.5 + 0.03))
	_mesh(self, _box(Vector3(width * 2.0, 0.2, 60.0)), _shared(Color(0.42, 0.46, 0.58), 0.95), Vector3(0, -15.2, z0 - 30.0))
	var lamp := _glow(Color(1.0, 0.68, 0.32), 3.0)
	for i in 12:
		_mesh(self, _box(Vector3(0.35, 0.35, 0.35)), lamp, Vector3(-27.0 + i * 4.6, -14.6, z0 - 21.0))


## 군터의 탁자 — 위스키 병 · 잔 둘 · 재떨이 · 불 붙은 시가 · 초록 갓 은행 등
func _gunter_table(at: Vector3) -> void:
	var wood := _shared(Color(0.24, 0.11, 0.05), 0.3)
	_mesh(self, _box(Vector3(1.9, 0.07, 0.66)), wood, at + Vector3(0, 0.76, 0))
	_mesh(self, _box(Vector3(1.8, 0.14, 0.58)), wood, at + Vector3(0, 0.66, 0))
	for sx in [-0.85, 0.85]:
		for sz in [-0.25, 0.25]:
			_mesh(self, _box(Vector3(0.07, 0.6, 0.07)), wood, at + Vector3(sx, 0.3, sz))
	var amber := _mat(Color(0.55, 0.28, 0.06, 0.8), 0.08, 0.3, 0.0)
	amber.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var glass := _mat(Color(0.85, 0.9, 0.95, 0.3), 0.05, 0.5, 0.0)
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var y := 0.795
	_mesh(self, _cyl(0.05, 0.055, 0.24), amber, at + Vector3(-0.55, y + 0.12, -0.1))
	_mesh(self, _cyl(0.018, 0.024, 0.09), amber, at + Vector3(-0.55, y + 0.285, -0.1))
	_mesh(self, _box(Vector3(0.08, 0.08, 0.005)), _shared(Color(0.9, 0.85, 0.7), 0.6), at + Vector3(-0.55, y + 0.11, -0.048))
	for p in [Vector3(-0.3, 0, 0.12), Vector3(0.12, 0, 0.16)]:
		_mesh(self, _cyl(0.038, 0.034, 0.085), glass, at + p + Vector3(0, y + 0.043, 0))
		_mesh(self, _cyl(0.031, 0.03, 0.03), amber, at + p + Vector3(0, y + 0.017, 0))
	_mesh(self, _cyl(0.075, 0.075, 0.02), _shared(Color(0.15, 0.18, 0.2), 0.1, 0.0, 0.3), at + Vector3(0.42, y + 0.01, 0.05))
	var cigar := _mesh(self, _cyl(0.011, 0.011, 0.13), _shared(Color(0.32, 0.18, 0.08), 0.8), at + Vector3(0.42, y + 0.03, 0.05))
	cigar.rotation_degrees.z = 90
	_mesh(self, _sphere(0.013), _glow(Color(1.0, 0.4, 0.1), 4.0), at + Vector3(0.487, y + 0.03, 0.05))
	var brass := _shared(Color(0.8, 0.6, 0.28), 0.3, 0.0, 0.8)
	_mesh(self, _cyl(0.06, 0.07, 0.03), brass, at + Vector3(0.72, y + 0.015, -0.18))
	_mesh(self, _cyl(0.012, 0.012, 0.3), brass, at + Vector3(0.72, y + 0.17, -0.18))
	_mesh(self, _box(Vector3(0.34, 0.07, 0.13)), _glow(Color(0.15, 0.55, 0.28), 1.3), at + Vector3(0.72, y + 0.33, -0.12))


## 높은 등받이 가죽 의자(앞 = +z)
func _armchair(at: Vector3, yaw: float) -> void:
	var g := _group(at, yaw)
	var lea := _shared(Color(0.27, 0.07, 0.05), 0.45)
	_mesh(g, _box(Vector3(0.8, 0.45, 0.66)), lea, Vector3(0, 0.225, 0))
	_mesh(g, _box(Vector3(0.8, 0.95, 0.16)), lea, Vector3(0, 0.9, -0.28))
	for sx in [-0.4, 0.4]:
		_mesh(g, _box(Vector3(0.14, 0.64, 0.66)), lea, Vector3(sx, 0.32, 0))


## 가죽 소파(앞 = +z — yaw 90 이면 +x 를 본다)
func _chesterfield(at: Vector3, yaw: float) -> void:
	var g := _group(at, yaw)
	var lea := _shared(Color(0.3, 0.15, 0.08), 0.45)
	_mesh(g, _box(Vector3(2.0, 0.42, 0.8)), lea, Vector3(0, 0.21, 0))
	_mesh(g, _box(Vector3(2.0, 0.55, 0.2)), lea, Vector3(0, 0.66, -0.31))
	for sx in [-1.0, 1.0]:
		_mesh(g, _box(Vector3(0.2, 0.66, 0.8)), lea, Vector3(sx, 0.33, 0))
	for sx in [-0.5, 0.5]:
		_mesh(g, _box(Vector3(0.94, 0.1, 0.64)), _shared(Color(0.34, 0.18, 0.1), 0.5), Vector3(sx, 0.46, 0.05))


func _floor_lamp(at: Vector3) -> void:
	var brass := _shared(Color(0.8, 0.6, 0.28), 0.3, 0.0, 0.8)
	_mesh(self, _cyl(0.16, 0.18, 0.04), brass, at + Vector3(0, 0.02, 0))
	_mesh(self, _cyl(0.02, 0.02, 1.5), brass, at + Vector3(0, 0.75, 0))
	_mesh(self, _cyl(0.18, 0.26, 0.32), _glow(Color(0.85, 0.6, 0.36), 0.45), at + Vector3(0, 1.6, 0))


## 장식장(옆벽 쪽, 낮게) — 술병 셋
func _sideboard(at: Vector3) -> void:
	var wood := _shared(Color(0.2, 0.1, 0.05), 0.35)
	_mesh(self, _box(Vector3(0.5, 0.9, 1.9)), wood, at + Vector3(0, 0.45, 0))
	var bottle := _shared(Color(0.25, 0.35, 0.2), 0.1, 0.3, 0.2)
	for z in [-0.5, -0.2, 0.25]:
		_mesh(self, _cyl(0.045, 0.05, 0.28), bottle, at + Vector3(0, 1.04, z))


## 호텔 밖(밤 · 눈) — 눈 덮인 길 · 바퀴 자국 · 호텔 정문(차양 · 간판 · 불 켜진 창) · 경찰차 셋(경광등) · 가로등 · 눈더미
func _vlad_night(b: Rect2) -> void:
	var cx := b.get_center().x
	var cz := b.get_center().y
	var zc := b.position.y - 0.35                     # 뒤 연석(인도 시작)
	var zf := b.position.y - 1.2                      # 호텔 정면
	var ex := b.position.x + 2.6                      # 정문(김신이 나온 자리 위)
	var ll := b.size.x + 24.0
	_env(Color(0.22, 0.26, 0.36), 0.7, Color(0.02, 0.03, 0.06))
	_sun(Color(0.62, 0.7, 0.95), 0.35, Vector3(-62, 25, 0))
	_ground(b, Color(0.48, 0.52, 0.62), Color(0.68, 0.72, 0.8), 0.85, 3, 9.0, 1.8)
	# 바퀴 자국(진창) — 두 줄씩 두 쌍, 3m 마다 조금씩 어긋나 흔들린다(반투명)
	var slush := _mat(Color(0.32, 0.34, 0.4, 0.4), 0.25)
	slush.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var rt := RandomNumberGenerator.new()
	rt.seed = 5
	for zt in [cz - 0.9, cz + 1.5]:
		var wob := 0.0
		var tx := cx - ll * 0.5
		while tx < cx + ll * 0.5:
			wob = clampf(wob + rt.randf_range(-0.06, 0.06), -0.15, 0.15)
			for dz in [-0.75, 0.75]:
				_decal(Rect2(tx, zt + dz + wob - 0.11, 4.0, 0.22), slush, 0.003)
			tx += 4.0
	var walk := _shared(Color(0.8, 0.82, 0.88), 0.9)
	_mesh(self, _box(Vector3(ll, 0.15, zc - zf)), walk, Vector3(cx, 0.075, (zc + zf) * 0.5))
	_mesh(self, _box(Vector3(ll, 0.16, 0.12)), _shared(Color(0.45, 0.46, 0.5), 0.8), Vector3(cx, 0.08, zc))
	# 호텔 정면 — 돌벽 · 화강암 굽 · 1층 창(따뜻한 불빛) · 정문
	_mesh(self, _box(Vector3(ll, 7.0, 0.4)), _shared(Color(0.46, 0.42, 0.37), 0.85), Vector3(cx, 3.5, zf - 0.2))
	_mesh(self, _box(Vector3(ll, 0.7, 0.46)), _shared(Color(0.28, 0.27, 0.27), 0.6), Vector3(cx, 0.35, zf - 0.2))
	var wframe := _shared(Color(0.2, 0.18, 0.16), 0.5)
	var wlit := _glow(Color(1.0, 0.76, 0.48), 1.3)
	var x := cx - ll * 0.5 + 1.0
	while x < cx + ll * 0.5:
		if absf(x - ex) > 2.4:
			_mesh(self, _box(Vector3(1.5, 1.8, 0.06)), wframe, Vector3(x, 1.75, zf + 0.02))
			_mesh(self, _box(Vector3(1.3, 1.6, 0.04)), wlit, Vector3(x, 1.75, zf + 0.05))
			_mesh(self, _box(Vector3(0.05, 1.6, 0.03)), wframe, Vector3(x, 1.75, zf + 0.08))
			_mesh(self, _box(Vector3(1.3, 0.05, 0.03)), wframe, Vector3(x, 2.15, zf + 0.08))
		x += 2.6
	var brass := _shared(Color(0.8, 0.62, 0.3), 0.3, 0.0, 0.8)
	_mesh(self, _box(Vector3(2.6, 2.7, 0.06)), brass, Vector3(ex, 1.5, zf + 0.02))
	_mesh(self, _box(Vector3(2.3, 2.4, 0.04)), _glow(Color(1.0, 0.84, 0.6), 2.0), Vector3(ex, 1.45, zf + 0.05))
	for dx in [-0.6, 0.0, 0.6]:
		_mesh(self, _box(Vector3(0.05, 2.4, 0.03)), brass, Vector3(ex + dx, 1.45, zf + 0.08))
	_mesh(self, _box(Vector3(3.4, 0.15, 0.7)), _shared(Color(0.35, 0.33, 0.32), 0.6), Vector3(ex, 0.22, zf + 0.35))   # 계단
	_mesh(self, _box(Vector3(3.8, 0.2, 1.3)), _shared(Color(0.3, 0.07, 0.06), 0.6), Vector3(ex, 2.95, zf + 0.65))     # 차양
	_mesh(self, _box(Vector3(3.8, 0.06, 1.3)), walk, Vector3(ex, 3.08, zf + 0.65))
	_label(Vector3(ex, 2.95, zf + 1.31), "HOTEL VLADIVOSTOK", Color(1.0, 0.85, 0.5), 40, 0.0045)
	for sx in [-1.0, 1.0]:
		_mesh(self, _cyl(0.04, 0.04, 2.85), brass, Vector3(ex + sx * 1.75, 1.5, zf + 1.22))
	_lamp_post(Vector3(ex + 5.2, 0.15, zc - 0.3), Color(1.0, 0.75, 0.45))
	_lamp_post(Vector3(ex - 5.0, 0.15, zc - 0.3), Color(1.0, 0.75, 0.45))
	# 눈더미(연석 따라 · 정문 앞은 치웠다)
	var snowm := _shared(Color(0.86, 0.88, 0.94), 0.95)
	var r := RandomNumberGenerator.new()
	r.seed = 4
	x = cx - ll * 0.5 + 2.0
	while x < cx + ll * 0.5:
		if absf(x - ex) > 2.2:
			var s := _mesh(self, _sphere(0.5), snowm, Vector3(x + r.randf_range(-0.4, 0.4), 0.15, zc - 0.32))
			s.scale = Vector3(r.randf_range(1.2, 2.0), 0.42, 0.7)
		x += 2.3
	# 경찰차 — 흰 차체 · 파란 띠 · 지붕 경광등(빨강 · 파랑, _process 가 번쩍인다)
	var red_m := _mat(Color(1.0, 0.1, 0.08), 0.4)
	red_m.emission_enabled = true
	red_m.emission = Color(1.0, 0.08, 0.05)
	var blue_m := _mat(Color(0.15, 0.35, 1.0), 0.4)
	blue_m.emission_enabled = true
	blue_m.emission = Color(0.1, 0.3, 1.0)
	var cars := [[Vector3(b.position.x - 1.7, 0, cz - 0.7), 100.0], [Vector3(b.position.x - 2.2, 0, b.end.y + 1.9), 128.0],
		[Vector3(b.end.x + 1.7, 0, cz - 0.3), 76.0]]
	for c in cars:
		var g := _car(c[0], c[1], Color(0.86, 0.88, 0.92))
		_mesh(g, _box(Vector3(4.32, 0.16, 1.78)), _shared(Color(0.1, 0.25, 0.62), 0.4), Vector3(0, 0.62, 0))
		_mesh(g, _box(Vector3(0.28, 0.07, 1.14)), _shared(Color(0.1, 0.1, 0.1), 0.5), Vector3(-0.3, 1.48, 0))
		_mesh(g, _box(Vector3(0.24, 0.1, 0.52)), red_m, Vector3(-0.3, 1.56, -0.28))
		_mesh(g, _box(Vector3(0.24, 0.1, 0.52)), blue_m, Vector3(-0.3, 1.56, 0.28))
	var p0: Vector3 = cars[0][0]
	_omni(p0 + Vector3(0.9, 1.9, -0.4), Color(1.0, 0.15, 0.1), 0.0, 7.0)
	var lr: OmniLight3D = get_child(-1)
	_omni(p0 + Vector3(0.9, 1.9, 0.4), Color(0.2, 0.4, 1.0), 0.0, 7.0)
	var lb: OmniLight3D = get_child(-1)
	_siren = [red_m, blue_m, lr, lb]
	_omni(Vector3(ex, 2.3, zf + 1.4), Color(1.0, 0.8, 0.55), 1.6, 6.5)
	_snow(Vector3(cx, 1.9, cz - 1.0), Vector3(b.size.x * 0.5 + 6.0, 1.9, b.size.y * 0.5 + 2.5), 420)   # 카메라 바로 앞은 비운다


# ======================== 1장 범죄도시 회암 ========================

## 공사장 골목(밤) — 왼쪽은 공사장(굴착기 · 가설 울타리 · 작업등 · 자재 · 고깔), 오른쪽은 낡은 벽돌 건물 뒷벽(철문 · 등 · 실외기 · 창살 창 ·
## 나트륨 등). 땅은 흙 · 자갈, 웅덩이와 궤도 자국
func _site_alley(b: Rect2) -> void:
	var cx := b.get_center().x
	var cz := b.get_center().y
	var split := cx - 0.6                              # 이 왼쪽 = 공사장, 오른쪽 = 벽돌 벽
	var zw := b.position.y - 0.85                      # 벽돌 벽 가운데(앞면 zw + 0.15)
	_env(Color(0.2, 0.22, 0.29), 0.6, Color(0.015, 0.018, 0.03))
	_sun(Color(0.55, 0.62, 0.85), 0.35, Vector3(-65, -30, 0))
	_ground(b, Color(0.19, 0.17, 0.14), Color(0.36, 0.33, 0.28), 0.95, 5, 9.0, 1.6)
	for z in [cz - 0.95, cz + 0.9]:                    # 궤도 자국(굴착기가 지나간 줄 — 마디 무늬)
		_tread(Rect2(cx - 9.0, z - 0.3, 10.0, 0.6), Color(0.1, 0.09, 0.07))
	if _detail:
		var pud := _mat(Color(0.1, 0.12, 0.16, 0.55), 0.05)              # 웅덩이(물빛 — 등불이 비친다)
		pud.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		pud.metallic_specular = 1.0
		for p in [Vector3(cx + 1.6, 0.0, cz + 1.1), Vector3(cx - 2.6, 0.0, cz - 0.4), Vector3(cx + 4.2, 0.0, cz - 1.2)]:
			_stain(p, 0.45, pud, int(p.x * 10.0))
	# 공사장 — 굴착기(붐을 왼쪽 앞으로 뻗어 버킷을 걸을 곳 밖 땅에 내려 둠) · 울타리 · 작업등
	_excavator(Vector3(cx - 3.2, 0, b.position.y - 1.9), 4.0, 193.0)
	_fence(cx - 16.0, split - 0.1, b.position.y - 3.4, 2.6)
	_work_light(Vector3(split - 0.4, 0, b.position.y - 0.75))
	for x in [cx - 6.0, cx - 1.6]:
		_cone(Vector3(x, 0, b.position.y - 0.6))
	_cone(Vector3(b.position.x - 0.7, 0, b.end.y - 0.4))
	_sandbags(Vector3(cx - 6.2, 0, b.position.y - 1.2))
	_rebar(Vector3(b.position.x - 1.1, 0, cz + 0.2))
	_barriers(b.position.x - 0.75, cz - 0.9, 3)
	# 벽돌 벽(오른쪽)
	var bw := b.end.x + 8.0 - split
	_mesh(self, _box(Vector3(bw, 5.0, 0.3)), _shared(Color(0.32, 0.17, 0.12), 0.9), Vector3(split + bw * 0.5, 2.5, zw))
	_panel(Vector3(split + bw * 0.5, 2.5, zw + 0.152), Vector2(bw, 5.0), _brick_tex(), Vector2(bw / 1.0, 5.0 / 0.5), Color.WHITE, 0.9)
	var dx := split + 2.4
	var steel := _shared(Color(0.22, 0.28, 0.26), 0.5, 0.0, 0.4)
	_mesh(self, _box(Vector3(1.16, 2.2, 0.04)), _shared(Color(0.12, 0.12, 0.12), 0.6), Vector3(dx, 1.1, zw + 0.17))
	_mesh(self, _box(Vector3(1.0, 2.08, 0.05)), steel, Vector3(dx, 1.04, zw + 0.19))
	_mesh(self, _box(Vector3(0.05, 0.22, 0.05)), _shared(Color(0.6, 0.6, 0.6), 0.3, 0.0, 0.9), Vector3(dx + 0.38, 1.0, zw + 0.24))
	_mesh(self, _box(Vector3(0.32, 0.14, 0.16)), _glow(Color(1.0, 0.86, 0.55), 2.6), Vector3(dx, 2.42, zw + 0.24))
	_mesh(self, _box(Vector3(0.85, 0.65, 0.32)), _shared(Color(0.72, 0.72, 0.7), 0.6), Vector3(dx + 1.5, 0.33, zw + 0.31))   # 실외기
	var fan := _mesh(self, _cyl(0.22, 0.22, 0.02), _shared(Color(0.15, 0.15, 0.15), 0.7), Vector3(dx + 1.42, 0.35, zw + 0.48))
	fan.rotation_degrees.x = 90
	var wx := split + 5.6
	_mesh(self, _box(Vector3(1.1, 0.85, 0.04)), _glow(Color(0.25, 0.32, 0.3), 0.6), Vector3(wx, 1.65, zw + 0.16))
	for i in 5:
		_mesh(self, _box(Vector3(0.03, 0.85, 0.03)), _shared(Color(0.1, 0.1, 0.1), 0.5, 0.0, 0.6), Vector3(wx - 0.44 + i * 0.22, 1.65, zw + 0.2))
	_mesh(self, _box(Vector3(1.2, 0.06, 0.12)), _shared(Color(0.4, 0.4, 0.38), 0.8), Vector3(wx, 1.2, zw + 0.2))
	var pipe := _shared(Color(0.42, 0.43, 0.44), 0.5, 0.0, 0.4)
	for px in [split + 0.25, split + 7.4]:
		_mesh(self, _cyl(0.06, 0.06, 5.0), pipe, Vector3(px, 2.5, zw + 0.24))
	var bag := _shared(Color(0.04, 0.04, 0.05), 0.2)
	for p in [Vector3(wx - 1.6, 0.28, zw + 0.48), Vector3(wx - 1.05, 0.22, zw + 0.42), Vector3(wx - 1.35, 0.5, zw + 0.4)]:
		var s := _mesh(self, _sphere(0.3), bag, p)
		s.scale = Vector3(1.0, 0.85, 0.8)
	_label(Vector3(split + 4.0, 1.25, zw + 0.16), "DS", Color(0.85, 0.2, 0.15), 64, 0.008)          # 벽 낙서
	_wall_light(Vector3(split + 7.0, 3.0, zw + 0.15))
	_omni(Vector3(split - 0.4, 2.6, b.position.y - 0.3), Color(0.9, 0.95, 1.0), 2.2, 9.0)        # 작업등
	_omni(Vector3(dx, 2.3, zw + 0.8), Color(1.0, 0.8, 0.5), 1.2, 5.0)                            # 철문 위 등
	_omni(Vector3(split + 7.0, 2.8, zw + 1.0), Color(1.0, 0.58, 0.22), 2.2, 8.0)                 # 나트륨 등


## 벽돌 그림(32x24 — 1m x 0.5m 에 벽돌 4 x 8 줄, 줄마다 반 칸 어긋남). 벽돌마다 빛깔이 조금씩 다르다
func _brick_tex() -> ImageTexture:
	var img := Image.create(32, 24, false, Image.FORMAT_RGB8)
	var mortar := Color(0.36, 0.34, 0.31)
	var r := RandomNumberGenerator.new()
	r.seed = 6
	img.fill(mortar)
	for row in 8:
		var off := 4 if row % 2 else 0
		for k in 5:
			var c := Color(0.42, 0.2, 0.14).lerp(Color(0.56, 0.3, 0.2), r.randf()).darkened(r.randf() * 0.2)
			var x0 := k * 8 - off
			for y in range(row * 3, row * 3 + 2):
				for x in range(x0, x0 + 7):
					if x >= 0 and x < 32:
						img.set_pixel(x, y, c)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## 굴착기(노랑 — 궤도 · 몸통 · 운전석 · 붐 · 암 · 버킷). turn = 위 몸통을 돌린 각(붐이 앞 +x)
func _excavator(at: Vector3, yaw: float, turn: float) -> void:
	var g := _group(at, yaw)
	var yel := _shared(Color(0.92, 0.66, 0.08), 0.5)
	var blk := _shared(Color(0.07, 0.07, 0.07), 0.8)
	var steel := _shared(Color(0.32, 0.32, 0.34), 0.5, 0.0, 0.6)
	var glass := _shared(Color(0.2, 0.26, 0.32), 0.1, 0.0, 0.4)
	for sz in [-0.95, 0.95]:
		_mesh(g, _box(Vector3(3.4, 0.72, 0.6)), blk, Vector3(0, 0.36, sz))
		_mesh(g, _box(Vector3(3.0, 0.1, 0.64)), steel, Vector3(0, 0.66, sz))
	_mesh(g, _box(Vector3(1.6, 0.4, 1.4)), blk, Vector3(0, 0.75, 0))
	var u := Node3D.new()
	u.position = Vector3(0, 0.95, 0)
	u.rotation_degrees.y = turn
	g.add_child(u)
	_mesh(u, _box(Vector3(2.5, 0.9, 2.2)), yel, Vector3(-0.2, 0.45, 0))
	_mesh(u, _box(Vector3(0.6, 0.85, 2.2)), blk, Vector3(-1.5, 0.45, 0))
	var hz := _mat(Color.WHITE, 0.6)                                   # 평형추 뒤 노랑 · 검정 경고 줄
	hz.albedo_texture = _stripe_tex([Color(0.92, 0.66, 0.08), Color(0.92, 0.66, 0.08), Color(0.07, 0.07, 0.07), Color(0.07, 0.07, 0.07)])
	hz.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	hz.uv1_scale = Vector3(6, 1, 1)
	var q := QuadMesh.new()
	q.size = Vector2(2.2, 0.36)
	var back := _mesh(u, q, hz, Vector3(-1.81, 0.55, 0))
	back.rotation_degrees.y = -90
	_mesh(u, _box(Vector3(1.3, 0.12, 1.9)), _shared(Color(0.75, 0.53, 0.06), 0.5), Vector3(-0.75, 0.96, 0.1))   # 엔진 덮개
	_mesh(u, _box(Vector3(0.12, 0.5, 0.12)), blk, Vector3(-0.6, 1.25, 0.7))                                     # 배기통
	_mesh(u, _cyl(0.07, 0.07, 0.12), _shared(Color(0.9, 0.45, 0.08), 0.4), Vector3(0.55, 2.25, -0.6))          # 경광등(꺼짐)
	_mesh(u, _box(Vector3(1.0, 1.25, 0.95)), glass, Vector3(0.55, 1.5, -0.6))
	_mesh(u, _box(Vector3(1.06, 0.08, 1.0)), yel, Vector3(0.55, 2.15, -0.6))
	for p in [Vector3(1.04, 1.5, -0.14), Vector3(1.04, 1.5, -1.06)]:
		_mesh(u, _box(Vector3(0.06, 1.25, 0.06)), yel, p)
	var boom := Node3D.new()
	boom.position = Vector3(0.9, 0.9, 0.4)
	boom.rotation_degrees.z = 30
	u.add_child(boom)
	_mesh(boom, _box(Vector3(3.3, 0.44, 0.38)), yel, Vector3(1.65, 0, 0))
	var hyd := _mesh(boom, _cyl(0.07, 0.07, 1.6), steel, Vector3(0.9, -0.36, 0))
	hyd.rotation_degrees.z = 90
	var arm := Node3D.new()
	arm.position = Vector3(3.3, 0, 0)
	arm.rotation_degrees.z = -112
	boom.add_child(arm)
	_mesh(arm, _box(Vector3(2.6, 0.32, 0.3)), yel, Vector3(1.3, 0, 0))
	var bk := Node3D.new()
	bk.position = Vector3(2.6, 0, 0)
	bk.rotation_degrees.z = -45
	arm.add_child(bk)
	_mesh(bk, _box(Vector3(0.7, 0.55, 0.9)), steel, Vector3(0.3, 0, 0))


## 가설 울타리(골함석 · 아래 초록 띠 · 기둥 · '안전제일')
func _fence(x0: float, x1: float, z: float, h: float) -> void:
	var a := Color(0.74, 0.76, 0.76)
	var ribs := _stripe_tex([a, a, a.darkened(0.2), a.lightened(0.1)])
	var w := x1 - x0
	_panel(Vector3((x0 + x1) * 0.5, h * 0.5, z), Vector2(w, h), ribs, Vector2(w / 0.25, 1), Color.WHITE, 0.6)
	_mesh(self, _box(Vector3(w, 0.4, 0.04)), _shared(Color(0.1, 0.4, 0.24), 0.6), Vector3((x0 + x1) * 0.5, 0.3, z + 0.02))
	var post := _shared(Color(0.25, 0.26, 0.27), 0.6, 0.0, 0.5)
	var x := x0
	while x <= x1:
		_mesh(self, _box(Vector3(0.08, h + 0.1, 0.08)), post, Vector3(x, (h + 0.1) * 0.5, z + 0.05))
		x += 2.0
	_label(Vector3(x1 - 2.2, 1.35, z + 0.03), "안전제일", Color(0.1, 0.45, 0.25), 64, 0.006)
	_label(Vector3(x1 - 6.4, 1.35, z + 0.03), "공사중", Color(0.75, 0.15, 0.1), 64, 0.006)


## 작업등(삼각대 · 빛나는 판) — 빛은 _omni 로 따로
func _work_light(at: Vector3) -> void:
	var steel := _shared(Color(0.2, 0.2, 0.22), 0.5, 0.0, 0.6)
	for a in [0.0, 120.0, 240.0]:
		var leg := _mesh(self, _cyl(0.025, 0.025, 2.2), steel, at + Vector3(sin(deg_to_rad(a)) * 0.35, 1.05, cos(deg_to_rad(a)) * 0.35))
		leg.rotation_degrees = Vector3(cos(deg_to_rad(a)) * -10.0, 0, sin(deg_to_rad(a)) * 10.0)
	var head := _mesh(self, _box(Vector3(0.6, 0.45, 0.12)), _glow(Color(0.95, 0.97, 1.0), 4.0), at + Vector3(0, 2.25, 0.05))
	head.rotation_degrees.x = -30


func _cone(at: Vector3) -> void:
	_mesh(self, _box(Vector3(0.4, 0.04, 0.4)), _shared(Color(0.08, 0.08, 0.08), 0.8), at + Vector3(0, 0.02, 0))
	_mesh(self, _cyl(0.035, 0.17, 0.7), _shared(Color(1.0, 0.38, 0.05), 0.6), at + Vector3(0, 0.39, 0))
	_mesh(self, _cyl(0.085, 0.11, 0.1), _shared(Color(0.92, 0.92, 0.9), 0.5), at + Vector3(0, 0.45, 0))


func _sandbags(at: Vector3) -> void:
	var m := _shared(Color(0.5, 0.45, 0.34), 0.95)
	for i in 5:
		var row := 0 if i < 3 else 1
		var p := Vector3(-0.55 + (i % 3) * 0.55 + row * 0.27, 0.12 + row * 0.22, 0)
		var s := _mesh(self, _sphere(0.3), m, at + p)
		s.scale = Vector3(1.0, 0.42, 0.7)


## 철근 묶음 · 쇠 파이프(옆, 바닥에 눕힘)
func _rebar(at: Vector3) -> void:
	var rust := _shared(Color(0.36, 0.2, 0.12), 0.8, 0.0, 0.4)
	for i in 6:
		var c := _mesh(self, _cyl(0.025, 0.025, 4.0), rust, at + Vector3(-0.15 + (i % 3) * 0.06, 0.05 + int(i / 3.0) * 0.05, 0))
		c.rotation_degrees.x = 90
	var pipe := _shared(Color(0.4, 0.42, 0.44), 0.5, 0.0, 0.5)
	for i in 3:
		var c := _mesh(self, _cyl(0.09, 0.09, 3.0), pipe, at + Vector3(0.35 + i * 0.19, 0.09, -1.8))
		c.rotation_degrees.x = 90


## 플라스틱 방호벽(빨강 · 하양 번갈아) — x 에 세워 z 로 n 개
func _barriers(x: float, z0: float, n: int) -> void:
	for i in n:
		var col := Color(0.85, 0.12, 0.1) if i % 2 == 0 else Color(0.9, 0.9, 0.88)
		_mesh(self, _box(Vector3(0.45, 0.8, 1.15)), _shared(col, 0.5), Vector3(x, 0.4, z0 + i * 1.22))


## 벽에 단 나트륨 등(받침 + 주황 갓)
func _wall_light(at: Vector3) -> void:
	_mesh(self, _box(Vector3(0.06, 0.06, 0.5)), _shared(Color(0.2, 0.2, 0.2), 0.5, 0.0, 0.6), at + Vector3(0, 0, 0.25))
	_mesh(self, _box(Vector3(0.4, 0.12, 0.26)), _glow(Color(1.0, 0.6, 0.25), 3.2), at + Vector3(0, -0.06, 0.5))


## 부진폐차장 — 뒤에 폐차 더미(2 ~ 3 층) · 컨테이너 사무실(간판) · 드럼통 · 리프트 위 폐차, 옆에 더미 · 승합차 · 타이어, 투광등.
## 밤(dusk = false): 달빛 + 투광등 둘 + 사무실 창. 노을(dusk): 낮은 주황 해(긴 그림자) · 붉은 하늘빛 · 투광등 꺼짐
func _junkyard(b: Rect2, dusk: bool) -> void:
	var cx := b.get_center().x
	var cz := b.get_center().y
	var zs := b.position.y - 1.5                      # 뒤 더미 줄(앞 끝이 걸을 곳 뒤 0.3m 안팎)
	if dusk:
		_env(Color(0.34, 0.28, 0.4), 0.6, Color(0.5, 0.24, 0.16))                    # 그늘은 보랏빛
		_sun(Color(1.0, 0.6, 0.32), 1.25, Vector3(-24, -35, 0), Color(0.45, 0.4, 0.85), 0.4)   # 해는 앞 왼쪽 낮게 — 얼굴이 노을빛, 그림자는 뒤로 길게
		_fog(Color(0.8, 0.45, 0.3), 0.004)
	else:
		_env(Color(0.17, 0.19, 0.28), 0.6, Color(0.01, 0.015, 0.035))
		_sun(Color(0.55, 0.62, 0.9), 0.3, Vector3(-62, 20, 0))
	_ground(b, Color(0.19, 0.17, 0.14), Color(0.33, 0.29, 0.24), 0.95, 7, 10.0, 1.8)
	var r := RandomNumberGenerator.new()
	r.seed = 8
	if _detail:
		var oil := _mat(Color(0.03, 0.03, 0.04, 0.45), 0.5)               # 기름 얼룩(반투명)
		oil.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		for i in (3 if dusk else 6):                   # 노을엔 긴 그림자와 헷갈리지 않게 적게
			_stain(Vector3(cx + r.randf_range(-b.size.x * 0.45, b.size.x * 0.45), 0.0, cz + r.randf_range(-b.size.y * 0.4, b.size.y * 0.4)),
				r.randf_range(0.35, 0.7), oil, i)
		for zt in [cz - 1.2, cz + 1.0]:                # 바퀴 자국(지게차 · 견인차)
			_tread(Rect2(b.position.x - 4.0, zt - 0.14, b.size.x + 8.0, 0.28), Color(0.12, 0.1, 0.08))
	var paints := [Color(0.5, 0.18, 0.14), Color(0.25, 0.32, 0.42), Color(0.62, 0.62, 0.58), Color(0.4, 0.3, 0.2),
		Color(0.22, 0.36, 0.26), Color(0.55, 0.5, 0.35), Color(0.18, 0.18, 0.2), Color(0.7, 0.68, 0.62)]
	var cont_x := b.position.x + 2.4                   # 컨테이너 사무실(뒤 왼쪽)
	var lift_x := b.end.x - 2.6                        # 리프트(뒤 오른쪽)
	var busy := [[cont_x - 3.1, cont_x + 4.7], [lift_x - 2.1, lift_x + 2.1]]   # 더미를 두지 않는 x 구간(사무실 + 드럼통 · 리프트)
	var x := b.position.x - 11.0
	while x < b.end.x + 11.0:
		var free := true
		for iv in busy:
			free = free and (x + 2.15 < iv[0] or x - 2.15 > iv[1])
		if free:
			_stack(Vector3(x, 0, zs + r.randf_range(-0.15, 0.15)), 0.0, 2 + (1 if r.randf() < 0.5 else 0), paints, r)
			x += 4.4
		else:
			x += 0.5
	x = b.position.x - 9.0                             # 뒷줄 더미(사무실 · 리프트 뒤로 보이는 겹 — 낮게) · 골함석 담
	while x < b.end.x + 9.0:
		if x + 2.15 < lift_x - 1.6 or x - 2.15 > lift_x + 1.6:
			_stack(Vector3(x, 0, zs - 2.7 + r.randf_range(-0.15, 0.15)), 0.0, 1 + (1 if r.randf() < 0.4 else 0), paints, r)
		x += 4.6
	var wall_c := Color(0.3, 0.27, 0.24)
	_panel(Vector3(cx, 1.6, zs - 4.2), Vector2(b.size.x + 24.0, 3.2), _stripe_tex([wall_c, wall_c, wall_c.darkened(0.3), wall_c.lightened(0.1)]),
		Vector2((b.size.x + 24.0) / 0.3, 1), Color.WHITE, 0.8)
	for sx in [-1.0, 1.0]:                             # 옆 더미(z 로) — 오른쪽 앞은 승합차 자리
		var z := b.position.y - 0.2
		while z < b.end.y + 6.0:
			if sx < 0.0 or z < cz - 2.2:
				var px := b.position.x - 1.95 if sx < 0.0 else b.end.x + 1.95
				_stack(Vector3(px, 0, z + 2.1), 90.0, 1 + (1 if r.randf() < 0.6 else 0), paints, r)
			z += 4.4
	_container_office(Vector3(cont_x, 0, b.position.y - 1.75), 0.6 if dusk else 1.6)
	var rust := Color(0.42, 0.22, 0.12)
	_barrel(Vector3(cont_x + 3.5, 0, b.position.y - 0.95), Color(0.15, 0.25, 0.45))
	_barrel(Vector3(cont_x + 4.15, 0, b.position.y - 1.35), rust)
	_barrel(Vector3(cont_x + 3.75, 0, b.position.y - 1.7), rust)
	_car_lift(Vector3(lift_x, 0, b.position.y - 2.55), paints[1])
	_van(Vector3(b.end.x + 1.7, 0, cz + 0.9), 93.0)
	_tires(Vector3(b.position.x - 0.85, 0, b.end.y + 0.3), 5)
	_tires(Vector3(b.position.x - 0.8, 0, b.end.y - 0.55), 3)
	_tires(Vector3(lift_x + 2.9, 0, b.position.y - 0.75), 4)
	var fl := [Vector3(cx - 0.6, 0, b.position.y - 0.75), Vector3(b.end.x + 0.75, 0, b.position.y - 0.55)]
	for p in fl:
		_flood(p, not dusk)
	if not dusk:
		for p in fl:
			_omni(p + Vector3(0, 3.9, 1.3), Color(0.85, 0.9, 1.0), 2.4, 11.0)
	_omni(Vector3(cont_x + 0.9, 1.6, b.position.y - 0.1), Color(1.0, 0.7, 0.4), 0.6 if dusk else 1.3, 5.0)


## 폐차 더미 — n 대를 조금씩 돌려 쌓는다(yaw = 더미 방향, 90 이면 z 로 길다)
func _stack(at: Vector3, yaw: float, n: int, paints: Array, r: RandomNumberGenerator) -> void:
	for k in n:
		_wreck(self, at + Vector3(r.randf_range(-0.2, 0.2), k * 1.0, r.randf_range(-0.1, 0.1)), yaw + r.randf_range(-6.0, 6.0),
			paints[r.randi() % paints.size()], r.randf_range(-5.0, 5.0))


## 컨테이너 사무실 — 골함석 파란 몸 · 문 · 블라인드 친 창(불빛 lit) · 지붕 간판 '부진폐차장'(원작 007/013)
func _container_office(at: Vector3, lit: float) -> void:
	var c := Color(0.17, 0.32, 0.48)
	_mesh(self, _box(Vector3(6.0, 2.6, 2.4)), _shared(c, 0.6, 0.0, 0.3), at + Vector3(0, 1.3, 0))
	_panel(at + Vector3(0, 1.3, 1.205), Vector2(6.0, 2.6), _stripe_tex([c, c, c.darkened(0.3), c.lightened(0.12)]), Vector2(6.0 / 0.3, 1), Color.WHITE, 0.6)
	_mesh(self, _box(Vector3(0.95, 2.0, 0.05)), _shared(Color(0.72, 0.73, 0.72), 0.5, 0.0, 0.4), at + Vector3(-1.6, 1.0, 1.24))
	_mesh(self, _box(Vector3(0.05, 0.2, 0.05)), _shared(Color(0.2, 0.2, 0.2), 0.5), at + Vector3(-1.25, 1.0, 1.28))
	_mesh(self, _box(Vector3(1.2, 0.2, 0.55)), _shared(Color(0.45, 0.44, 0.42), 0.9), at + Vector3(-1.6, 0.1, 1.5))
	var alu := _shared(Color(0.7, 0.72, 0.74), 0.4, 0.0, 0.6)
	_mesh(self, _box(Vector3(1.6, 1.05, 0.05)), alu, at + Vector3(0.9, 1.5, 1.23))
	_mesh(self, _box(Vector3(1.46, 0.92, 0.02)), _glow(Color(1.0, 0.74, 0.42), lit), at + Vector3(0.9, 1.5, 1.26))
	for i in 5:
		_mesh(self, _box(Vector3(1.46, 0.04, 0.02)), _shared(Color(0.5, 0.42, 0.3), 0.6), at + Vector3(0.9, 1.15 + i * 0.17, 1.28))
	var post := _shared(Color(0.3, 0.3, 0.3), 0.5, 0.0, 0.5)
	for sx in [-1.3, 1.3]:
		_mesh(self, _box(Vector3(0.06, 0.5, 0.06)), post, at + Vector3(sx, 2.85, 0.85))
	_mesh(self, _box(Vector3(3.4, 0.72, 0.08)), _shared(Color(0.92, 0.92, 0.88), 0.6), at + Vector3(0, 3.3, 0.9))
	_label(at + Vector3(0, 3.3, 0.95), "부진폐차장", Color(0.75, 0.1, 0.08), 64, 0.0075)


## 2주식 리프트(노란 기둥 둘 — 차는 그 사이에 z 로) 위 폐차
func _car_lift(at: Vector3, body: Color) -> void:
	var post := _shared(Color(0.85, 0.6, 0.1), 0.5)
	for sx in [-1.25, 1.25]:
		_mesh(self, _box(Vector3(0.3, 3.4, 0.4)), post, at + Vector3(sx, 1.7, 0))
		for sz in [-0.7, 0.7]:
			_mesh(self, _box(Vector3(0.5, 0.08, 0.1)), _shared(Color(0.3, 0.3, 0.32), 0.5, 0.0, 0.6), at + Vector3(sx * 0.78, 1.62, sz))
	_mesh(self, _box(Vector3(2.8, 0.18, 0.3)), post, at + Vector3(0, 3.45, 0))
	_wreck(self, at + Vector3(0, 1.66, 0), 90.0, body)


## 승합차(앞 = +x) — 김신이 날아가 처박힌 차(원작 008/004-007), 옆면이 우그러졌다
func _van(at: Vector3, yaw: float) -> void:
	var g := _group(at, yaw)
	var paint := _shared(Color(0.78, 0.78, 0.75), 0.5)
	var glass := _shared(Color(0.16, 0.2, 0.25), 0.1, 0.0, 0.5)
	var tire := _shared(Color(0.05, 0.05, 0.05), 0.9)
	_mesh(g, _box(Vector3(4.9, 1.7, 1.9)), paint, Vector3(0, 1.05, 0))
	_mesh(g, _box(Vector3(3.3, 0.5, 1.92)), glass, Vector3(-0.4, 1.55, 0))
	_mesh(g, _box(Vector3(0.06, 0.62, 1.66)), glass, Vector3(2.45, 1.5, 0))
	_mesh(g, _box(Vector3(1.1, 0.7, 0.06)), _shared(Color(0.55, 0.55, 0.52), 0.8), Vector3(-0.5, 0.95, -0.95))   # 우그러진 자리(-z 옆)
	for wx in [-1.6, 1.6]:
		for wz in [-0.85, 0.85]:
			var w := _mesh(g, _cyl(0.34, 0.34, 0.24), tire, Vector3(wx, 0.34, wz))
			w.rotation_degrees.x = 90


## 투광등(기둥 + 등판). on 이면 빛나는 판(빛은 _omni 로 따로)
func _flood(at: Vector3, on: bool) -> void:
	var steel := _shared(Color(0.22, 0.22, 0.24), 0.5, 0.0, 0.6)
	_mesh(self, _cyl(0.08, 0.1, 4.6), steel, at + Vector3(0, 2.3, 0))
	var m: StandardMaterial3D = _glow(Color(0.92, 0.95, 1.0), 4.0) if on else _shared(Color(0.35, 0.36, 0.38), 0.3, 0.0, 0.5)
	for sx in [-0.4, 0.4]:
		var h := _mesh(self, _box(Vector3(0.7, 0.42, 0.14)), m, at + Vector3(sx, 4.55, 0.22))
		h.rotation_degrees.x = -35


## 회암시 거리(낮) — 아스팔트 · 노란 겹 중앙선 · 횡단보도 · 정지선, 뒤에 인도 · 상가(간판 · 유리창 · 차양) · 가로등 · 가로수 · 볼라드 ·
## 소화전 · 배달 오토바이, 앞에 낮은 인도. 차는 걸을 곳 양 끝 밖에 세워 둔다
func _hoeam_street(b: Rect2) -> void:
	var cx := b.get_center().x
	var cz := b.get_center().y
	var zc := b.position.y - 0.4                       # 뒤 연석
	var zf := b.position.y - 1.45                      # 상가 앞면
	var zc2 := b.end.y + 0.45                          # 앞 연석
	var ll := b.size.x + 26.0
	_env(Color(0.58, 0.62, 0.7), 0.8, Color(0.62, 0.72, 0.86))
	_sun(Color(1.0, 0.95, 0.86), 1.1, Vector3(-55, 35, 0), Color(0.75, 0.8, 1.0), 0.25)
	_ground(b, Color(0.16, 0.16, 0.17), Color(0.29, 0.29, 0.3), 0.85, 11, 12.0, 2.0)
	var yel := _shared(Color(0.95, 0.72, 0.1), 0.6)
	var wht := _shared(Color(0.9, 0.9, 0.88), 0.6)
	var xw := b.end.x - 2.2                            # 횡단보도(오른쪽) — 중앙선은 그 앞뒤에서 끊긴다
	for dz in [-0.11, 0.11]:
		_decal(Rect2(cx - ll * 0.5, cz + dz - 0.06, xw - 2.6 - (cx - ll * 0.5), 0.12), yel)
		_decal(Rect2(xw + 2.4, cz + dz - 0.06, cx + ll * 0.5 - xw - 2.4, 0.12), yel)
	var z := zc + 0.45
	while z < zc2 - 0.5:
		_decal(Rect2(xw - 1.5, z, 3.0, 0.45), wht, 0.005)
		z += 0.95
	_decal(Rect2(xw - 2.4, cz + 0.3, 0.3, zc2 - cz - 0.6), wht, 0.005)       # 정지선(앞 차로 — 차는 오른쪽으로 달린다)
	_decal(Rect2(xw + 2.1, zc + 0.3, 0.3, cz - zc - 0.6), wht, 0.005)        # 정지선(뒤 차로)
	# 인도(뒤 · 앞) — 보도블록 결
	var tile := _tile_tex(Color(0.6, 0.55, 0.52), Color(0.46, 0.42, 0.4))
	_walk(Rect2(cx - ll * 0.5, zf, ll, zc - zf), tile)
	_walk(Rect2(cx - ll * 0.5, zc2, ll, 4.0), tile)
	# 상가
	var shops := [
		["HOLLSY COFFEE", Color(0.12, 0.28, 0.2), Color(0.95, 0.92, 0.85), "COFFEE · DESSERT"],
		["회암 부동산", Color(0.12, 0.2, 0.42), Color(1, 1, 1), "매매 · 전세 · 월세"],
		["분식", Color(0.85, 0.35, 0.1), Color(1, 1, 1), "떡볶이 · 순대 · 튀김"],
		["24 편의점", Color(0.1, 0.5, 0.35), Color(1, 1, 1), "24시"],
		["철물", Color(0.6, 0.1, 0.1), Color(1.0, 0.9, 0.6), "열쇠 · 공구"],
		["약국", Color(0.92, 0.92, 0.9), Color(0.1, 0.55, 0.3), "약"],
		["PC방", Color(0.3, 0.12, 0.45), Color(0.9, 0.95, 1.0), "24시 · 고사양"],
		["세탁소", Color(0.2, 0.45, 0.7), Color(1, 1, 1), "세탁 · 수선"],
	]
	var sw := 4.0
	var n := int(ceil((b.size.x + 18.0) / sw))
	var sx0 := cx - n * sw * 0.5
	_mesh(self, _box(Vector3(n * sw + 2.0, 7.0, 0.4)), _shared(Color(0.72, 0.66, 0.58), 0.8), Vector3(cx, 3.5, zf - 0.2))
	for i in n:
		var s: Array = shops[(i + 2) % shops.size()]
		_shopfront(Vector3(sx0 + (i + 0.5) * sw, 0.15, zf), sw, s, i)
	# 인도 소품
	var lx := [cx - 5.0, cx + 3.4]
	for x in lx:
		_lamp_post(Vector3(x, 0.15, zc - 0.25), Color(0.5, 0.5, 0.48), 4.4, 0.9, false)
	for x in [cx - 1.4, cx + 6.6]:
		_tree(Vector3(x, 0.15, zc - 0.6))
	for dx in [-1.9, -0.7, 0.7, 1.9]:
		_mesh(self, _cyl(0.07, 0.08, 0.8), _shared(Color(0.35, 0.36, 0.38), 0.5, 0.0, 0.5), Vector3(xw + dx, 0.55, zc - 0.22))
	_mesh(self, _cyl(0.13, 0.15, 0.62), _shared(Color(0.8, 0.12, 0.1), 0.5), Vector3(cx + 1.2, 0.46, zc - 0.3))   # 소화전
	_mesh(self, _sphere(0.13), _shared(Color(0.8, 0.12, 0.1), 0.5), Vector3(cx + 1.2, 0.78, zc - 0.3))
	_scooter(Vector3(cx - 3.0, 0.15, zc - 0.7), 8.0)
	_aframe(Vector3(sx0 + 2.5 * sw - 0.6, 0.15, zf + 0.5))
	# 세워 둔 차(걸을 곳 양 끝 밖 — 검은 세단 둘 · 흰 차 · 은색 차)
	_car(Vector3(b.position.x - 2.8, 0, b.position.y + 1.1), 0.0, Color(0.1, 0.1, 0.11), false)
	_car(Vector3(b.position.x - 7.6, 0, b.position.y + 1.1), 0.0, Color(0.55, 0.57, 0.6), false)
	_car(Vector3(b.end.x + 2.8, 0, b.end.y - 1.1), 180.0, Color(0.88, 0.88, 0.9), false)
	_car(Vector3(b.end.x + 7.4, 0, b.end.y - 1.1), 180.0, Color(0.1, 0.1, 0.11), false)


## 보도블록 결(16x16 — 한 칸 0.5m, 줄눈)
func _tile_tex(c: Color, line: Color) -> ImageTexture:
	var img := Image.create(16, 16, false, Image.FORMAT_RGB8)
	var r := RandomNumberGenerator.new()
	r.seed = 12
	for y in 16:
		for x in 16:
			var e := x % 8 == 0 or y % 8 == 0
			img.set_pixel(x, y, line if e else c.darkened(r.randf() * 0.06))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## 인도(높이 0.15 상자 + 윗면 결 + 연석)
func _walk(r: Rect2, tex: Texture2D) -> void:
	_mesh(self, _box(Vector3(r.size.x, 0.15, r.size.y)), _shared(Color(0.5, 0.47, 0.45), 0.9), Vector3(r.get_center().x, 0.075, r.get_center().y))
	var m := _mat(Color.WHITE, 0.9)
	m.albedo_texture = tex
	m.uv1_scale = Vector3(r.size.x / 1.0, r.size.y / 1.0, 1)
	var pm := PlaneMesh.new()
	pm.size = r.size
	_mesh(self, pm, m, Vector3(r.get_center().x, 0.152, r.get_center().y))
	var curb := _shared(Color(0.72, 0.72, 0.7), 0.7)
	for z in [r.position.y, r.end.y]:
		_mesh(self, _box(Vector3(r.size.x, 0.17, 0.14)), curb, Vector3(r.get_center().x, 0.085, z))


## 가게 앞면 하나(폭 w) — 기둥 · 유리 진열창 · 문 · 간판 띠(글) · 셋에 하나 차양
## s = [간판 글, 간판 빛깔, 글 빛깔, 유리창 글(눈높이 — 카메라에 늘 보이는 쪽)]
func _shopfront(at: Vector3, w: float, s: Array, i: int) -> void:
	var sign_c: Color = s[1]
	var text_c: Color = s[2]
	var pier := _shared(Color(0.55, 0.52, 0.5), 0.7)
	_mesh(self, _box(Vector3(0.3, 2.6, 0.12)), pier, at + Vector3(-w * 0.5 + 0.15, 1.3, 0.06))
	var frame := _shared(Color(0.24, 0.25, 0.27), 0.4, 0.0, 0.5)
	_mesh(self, _box(Vector3(w - 0.4, 1.95, 0.04)), frame, at + Vector3(0.15, 0.98, 0.03))
	_mesh(self, _box(Vector3(w - 0.55, 1.82, 0.04)), _shared(Color(0.3, 0.38, 0.44), 0.08, 0.0, 0.35), at + Vector3(0.15, 0.98, 0.06))
	var dxp := w * 0.25
	_mesh(self, _box(Vector3(0.9, 1.82, 0.03)), _shared(Color(0.18, 0.22, 0.26), 0.08, 0.0, 0.35), at + Vector3(dxp, 0.94, 0.085))
	_mesh(self, _box(Vector3(0.04, 0.5, 0.04)), _shared(Color(0.75, 0.75, 0.75), 0.3, 0.0, 0.9), at + Vector3(dxp - 0.32, 1.0, 0.12))
	_mesh(self, _box(Vector3(0.05, 1.82, 0.03)), frame, at + Vector3(-w * 0.12, 0.98, 0.085))
	_mesh(self, _box(Vector3(w - 0.2, 0.62, 0.14)), _shared(sign_c, 0.5), at + Vector3(0.15, 2.3, 0.1))
	_label(at + Vector3(0.15, 2.3, 0.175), s[0], text_c, 56, 0.0055)
	_mesh(self, _box(Vector3(w * 0.42, 0.26, 0.01)), _shared(sign_c, 0.6), at + Vector3(-w * 0.18, 1.2, 0.085))   # 유리 띠지
	_label(at + Vector3(-w * 0.18, 1.2, 0.092), s[3], text_c, 30, 0.0045)
	if i % 3 == 0:
		var aw := _mesh(self, _box(Vector3(w - 0.4, 0.05, 0.9)), _shared(sign_c.lightened(0.25), 0.7), at + Vector3(0.15, 1.92, 0.5))
		aw.rotation_degrees.x = 16


func _tree(at: Vector3) -> void:
	_mesh(self, _box(Vector3(0.9, 0.02, 0.9)), _shared(Color(0.15, 0.15, 0.15), 0.6, 0.0, 0.6), at + Vector3(0, 0.01, 0))
	_mesh(self, _cyl(0.1, 0.14, 2.8), _shared(Color(0.3, 0.22, 0.15), 0.9), at + Vector3(0, 1.4, 0))
	var leaf := _shared(Color(0.22, 0.42, 0.2), 0.9)
	_mesh(self, _sphere(1.0), leaf, at + Vector3(0, 3.3, 0))
	_mesh(self, _sphere(0.7), leaf, at + Vector3(0.6, 2.9, -0.3))


## 배달 오토바이(앞 = +x)
func _scooter(at: Vector3, yaw: float) -> void:
	var g := _group(at, yaw)
	var tire := _shared(Color(0.05, 0.05, 0.05), 0.9)
	for wx in [-0.55, 0.55]:
		var w := _mesh(g, _cyl(0.24, 0.24, 0.1), tire, Vector3(wx, 0.24, 0))
		w.rotation_degrees.x = 90
	_mesh(g, _box(Vector3(1.1, 0.3, 0.32)), _shared(Color(0.85, 0.85, 0.82), 0.4), Vector3(0, 0.5, 0))
	_mesh(g, _box(Vector3(0.5, 0.1, 0.3)), _shared(Color(0.1, 0.1, 0.1), 0.6), Vector3(-0.15, 0.7, 0))
	_mesh(g, _box(Vector3(0.45, 0.4, 0.45)), _shared(Color(0.9, 0.3, 0.1), 0.5), Vector3(-0.5, 0.95, 0))   # 배달 통
	_mesh(g, _box(Vector3(0.06, 0.6, 0.06)), _shared(Color(0.3, 0.3, 0.3), 0.4, 0.0, 0.6), Vector3(0.5, 0.85, 0))
	_mesh(g, _box(Vector3(0.06, 0.05, 0.6)), _shared(Color(0.3, 0.3, 0.3), 0.4, 0.0, 0.6), Vector3(0.5, 1.15, 0))


## 입간판(커피집 앞)
func _aframe(at: Vector3) -> void:
	var g := _group(at, 0.0)
	var board := _shared(Color(0.1, 0.12, 0.1), 0.6)
	for sz in [-1.0, 1.0]:
		var p := _mesh(g, _box(Vector3(0.55, 0.85, 0.03)), board, Vector3(0, 0.42, sz * 0.12))
		p.rotation_degrees.x = sz * 10.0
	var l := _label(at + Vector3(0, 0.55, 0.16), "COFFEE", Color(0.95, 0.92, 0.85), 32, 0.004)
	l.rotation_degrees.x = -10.0



## 바닥 얼룩(웅덩이 · 기름) — 납작한 원 둘을 겹쳐 모양을 흐트린다(반투명 재질 하나)
func _stain(at: Vector3, rad: float, mat: Material, seed_v: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 300 + seed_v
	for k in 2:
		var d := _mesh(self, _cyl(rad, rad, 0.004), mat, at + Vector3(r.randf_range(-0.3, 0.3) * rad, 0.003 + k * 0.001, r.randf_range(-0.3, 0.3) * rad))
		d.scale = Vector3(r.randf_range(0.9, 1.6), 1, r.randf_range(0.6, 1.0))


## 바퀴 · 궤도 자국 — 마디 무늬(가로 줄) 반투명 띠(PlaneMesh — 결이 띠 길이대로 되풀이)
func _tread(r: Rect2, col: Color) -> void:
	var m := _mat(Color(1, 1, 1, 0.32), 0.95)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_texture = _stripe_tex([col, col, col.lightened(0.15), col.lightened(0.15)])
	m.uv1_scale = Vector3(r.size.x / 0.3, 1, 1)
	var pm := PlaneMesh.new()
	pm.size = r.size
	_mesh(self, pm, m, Vector3(r.get_center().x, 0.002, r.get_center().y))

func _label(at: Vector3, txt: String, col: Color, size := 48, px := 0.005) -> Label3D:
	var l := Label3D.new()
	l.font = FONT
	l.text = txt
	l.font_size = size
	l.pixel_size = px
	l.modulate = col
	l.outline_size = 0
	l.position = at
	add_child(l)
	return l
