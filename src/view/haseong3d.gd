extends "res://src/view/town3d.gd"
## 2장 무대(하성 본사 — 1부 p1:022-033) — 방(src/data/haseong.gd ROOMS theme)마다 바닥 · 벽 · 소품 · 빛. 1부 무대(town3d.gd —
## 공사장 · 폐차장)를 물려받고 하성 본사 실내 다섯만 여기서 그린다. build(theme, bounds, detail) 는 같다(LSP). 그리는 도구는 set3d.gd ·
## town3d.gd(_shared · _glow · _label …), 이 무대에만 쓰는 도구는 아래 _hs_*(set3d · town3d 는 고치지 않는다).
## 카메라 · 폰 규칙은 town3d.gd 머리와 같다: 볼거리는 뒤(-z) 벽 아래 1 ~ 3m · 걸을 곳 안에는 납작한 것만(깨진 유리 · 종이 · 화살표) ·
## 높은 소품은 걸을 곳 밖(뒤 띠 · 양옆) · 앞(+z)은 비운다.
## 원작 근거(castle_common canon — 화/컷, 모양은 conf ai 판독이라 연출에만):
##   haseong_lobby     하성 본사(쌍둥이 빌딩) 1층 로비 — '유리벽 · 격자 창'(p1:027/191-207 · 028/000-070), 정장을 유리벽에 걷어차 박음
##                     (028/042-043 — 금 간 유리 한 장), 손도끼가 날아감(028/016-017). 회사 간판은 원작 표기 HASUNG(2부 035 · 074 판독 'HASUNG
##                     간판' · locations haseonggroup_bonsa '빗속의 HASUNG 쌍둥이 빌딩') — 글은 SIGN 한 곳. 밤(습격 — 024/019-031 작전)
##   haseong_stairs    우측 빌딩 로비 · 중앙계단(구름다리 층으로 이어짐 — 024/061-088 · 025/161-171), '밝은 회색 바닥'(027/165-190)
##   haseong_corridor  대표실 앞 복도(025/058-075 — 경호원들이 서 있거나 소파에 앉아 대기 · 026/045-048 대표실 문이 열림) ·
##                     복도 옆 사무실(칸막이 · 유리벽 028/101-128) · 엘리베이터(028/072-100 — 도지웅이 멈춤 024/039-062)
##   haseong_upper     위층 복도(대표실 앞 — '엘리베이터 · 타일 벽'(029/125-139) · 남궁혁 '내 뒤 계단으로 가면 직통'(024/113-122)) —
##                     corridor 와 같은 층, 불이 나가 비상등만. 김신이 남궁혁 옆을 스쳐 복도 끝으로 빠져나감(030/000-024) → 오른쪽 끝 출구
##                     (haseong.gd upper_corridor escape exit 자리: 바닥 초록 화살표 · 테두리 · 열린 계단문 · 비상구 등)
##   haseong_office    대표실(불 꺼짐 — 026/019-025 벽의 큰 지도 화면 · 026/060-063 청화백자 항아리 진열장 · 029/029-047 큰 책상(탄 장전
##                     029/048-066) · 029/067-080 창에 두 발을 쏴 깸 · 029/081-096 깨진 창(고층 · 바람)으로 걷어참 · 030/065-074 조각상) ·
##                     024/032-038 와인잔을 바닥에 던져 깸. 창밖 = 밤 도시 + 폐쇄된 좌측 빌딩 · 중앙 구름다리(locations haseong_hq)
## 폰 성능(town3d 와 같음): 점광 3개 이하 · 그림자는 위(_top) 하나 · 같은 값 재질은 하나(_shared · _glow · _hs_glass) · 결은 32px 이하
##   (대리석 · 카펫 · 지도 — 무대 안에서 나눠 씀) · 깨진 유리 조각은 메시 하나(ArrayMesh).
##   메시(상세 / 헤드리스): lobby 111 / 88 · stairs 99 / 86 · corridor 93 / 73 · upper 100 / 84 · office 139 / 90(창밖 도시 몫) · 점광 3 ·
##   만드는 데 3 ~ 5ms(헤드리스에서 잰 값 — 처음 결 만들기 포함).
##   상세(detail — 헤드리스는 끔)일 때만 그림자 · 바닥 결 · 작은 소품(종이 · 칼 · 유리 조각 · 모니터 · 책상 위 물건)

## 이 그림이 그리는 무대 이름(시험 test_campaign 이 장 표의 theme 이 여기 있는지 본다)
const HASEONG_THEMES := ["haseong_lobby", "haseong_corridor", "haseong_stairs", "haseong_office", "haseong_upper", "junkyard_office", "haseong_ceo"]
## haseong_ceo: 대표실 앞 복도 → 대표실을 한 맵으로(2026-11-12 사용자 rc.16 6번 "프롤로그 군터처럼 방으로 자연스럽게 이어지도록") — 걸을 곳 왼쪽
## CEO_CORRIDOR m 는 복도(장 표 haseong.gd guard_corridor 의 복도 자리 그대로), 오른쪽 CEO_OFFICE m 는 대표실(대표실 자리는 옛 대표실 + CEO_OX),
## 그 사이는 대표실 왼쪽 띠(책상) — 복도 끝 문틀로 걸어 들어간다
const CEO_CORRIDOR := 19.6
const CEO_OFFICE := 11.2
const CEO_OX := 19.4

const SIGN := "HASUNG"                 # 회사 간판 글(원작 표기 — 머리 주석)
const FLOOR_NO := "33"                 # 최상층 아래 층 번호(원작에 없음 — 그림만)

## 이 무대에서 만든 결(대리석 · 카펫 · 지도) — 같은 결은 한 번만(static 으로 두면 끝날 때 자원이 남는다 — 방마다 새로)
var _tex := {}

## haseong_ceo 를 그리는 중(복도 · 대표실이 빛 · 끝 벽을 겹쳐 그리지 않게)
var _hs_joined := false

## 비상등(위층 복도) — 천천히 깜빡이는 재질(나눠 쓰지 않는 것)
var _blink: Array = []


static func themes() -> Array:
	return THEMES + HASEONG_THEMES


func build(th: String, b: Rect2, detail := true) -> void:
	match th:
		"haseong_lobby":
			_hs_begin(th, detail)
			_hs_lobby(b)
		"haseong_stairs":
			_hs_begin(th, detail)
			_hs_stairs(b)
		"haseong_corridor":
			_hs_begin(th, detail)
			_hs_top_floor(b, false)
		"haseong_upper":
			_hs_begin(th, detail)
			_hs_top_floor(b, true)
		"haseong_office":
			_hs_begin(th, detail)
			_hs_office(b)
		"junkyard_office":
			_hs_begin(th, detail)
			_hs_junk_office(b)
		"haseong_ceo":
			_hs_begin(th, detail)
			_hs_ceo(b)
		_:
			super.build(th, b, detail)


func _hs_begin(th: String, detail: bool) -> void:
	theme = th
	_detail = detail


## 비상등 깜빡임(위층 복도) — 그림만
func _process(dt: float) -> void:
	super._process(dt)
	if _blink.is_empty():
		return
	_t += dt
	var on := fmod(_t * 0.7, 1.0) < 0.55
	for m in _blink:
		m.emission_energy_multiplier = 3.2 if on else 0.7


# ======================== 1층 로비 ========================

## 1층 로비(밤) — 밝은 대리석 바닥 · 가운데 돌벽(간판 HASUNG · 쌍둥이 표) · 안내 데스크 · 양옆 격자 유리벽(왼쪽 유리문) 너머 밤 광장 ·
## 기둥 · 왼쪽 대기 소파 · 오른쪽 출입 게이트. 바닥엔 난투 흔적(금 간 유리 · 유리 조각 · 종이 · 손도끼 · 칼)
func _hs_lobby(b: Rect2) -> void:
	var cx := b.get_center().x
	var wz := b.position.y - 1.2                     # 뒷벽 앞면 — 벽과 걸을 곳 사이에 안내 데스크
	var half := b.size.x * 0.5 + 3.8
	_env(Color(0.22, 0.24, 0.32), 0.6, Color(0.01, 0.015, 0.03))
	_top(Color(0.9, 0.92, 1.0), 0.42)
	_hs_floor(Rect2(cx - half, wz, half * 2.0, b.end.y + 5.0 - wz), Color(0.5, 0.5, 0.5), Color(0.34, 0.34, 0.37), 1.2, 1)
	var inlay := Vector3(cx, 0, b.get_center().y)                                              # 바닥 무늬(어두운 돌 원 · 금 테)
	_mesh(self, _hs_disc(1.7), _shared(Color(0.3, 0.3, 0.32), 0.2), inlay + Vector3(0, 0.003, 0))
	_mesh(self, _hs_disc(1.45), _shared(Color(0.55, 0.45, 0.26), 0.25, 0.0, 0.5), inlay + Vector3(0, 0.005, 0))
	_mesh(self, _hs_disc(1.37), _shared(Color(0.3, 0.3, 0.32), 0.2), inlay + Vector3(0, 0.007, 0))
	# 밖(유리 너머 광장 — 낮은 곳만 보인다)
	_mesh(self, _hs_plane(Vector2(half * 2.0 + 20.0, 18.0)), _shared(Color(0.08, 0.085, 0.1), 0.6), Vector3(cx, -0.01, wz - 9.0))
	for i in 8:
		_mesh(self, _cyl(0.09, 0.09, 0.7), _glow(Color(1.0, 0.9, 0.7), 1.8), Vector3(cx - 10.5 + i * 3.0, 0.35, wz - 1.6))
	for x in [cx - 7.5, cx + 7.5]:
		_lamp_post(Vector3(x, 0, wz - 3.4), Color(1.0, 0.85, 0.6), 4.2, 0.9, true)
	_mesh(self, _box(Vector3(half * 2.0, 0.5, 0.8)), _shared(Color(0.2, 0.2, 0.22), 0.8), Vector3(cx, 0.25, wz - 2.6))   # 화단
	_mesh(self, _box(Vector3(half * 2.0 - 0.2, 0.35, 0.7)), _shared(Color(0.08, 0.16, 0.08), 0.9), Vector3(cx, 0.6, wz - 2.6))
	# 가운데 돌벽 · 간판
	var stone := _shared(Color(0.14, 0.13, 0.13), 0.3, 0.0, 0.1)
	_mesh(self, _box(Vector3(7.2, 4.4, 0.3)), stone, Vector3(cx, 2.2, wz - 0.15))
	_mesh(self, _box(Vector3(7.2, 0.12, 0.06)), _glow(Color(1.0, 0.85, 0.6), 1.2), Vector3(cx, 3.0, wz + 0.03))
	_hs_twin_mark(Vector3(cx - 2.45, 2.15, wz + 0.02), 0.62)
	_label(Vector3(cx + 0.35, 2.15, wz + 0.03), SIGN, Color(0.92, 0.8, 0.52), 96, 0.0075)
	_label(Vector3(cx, 1.55, wz + 0.03), "하성그룹 본사", Color(0.8, 0.74, 0.6), 40, 0.005)
	_hs_reception(Vector3(cx, 0, b.position.y - 0.52), 4.8)
	# 격자 유리벽(양옆) — 왼쪽에 유리문(밖 → 로비, 청년회가 들어온 쪽)
	var frame := _shared(Color(0.16, 0.17, 0.19), 0.4, 0.0, 0.6)
	_hs_curtain(cx - half, cx - 3.6, wz - 0.1, 4.4, 1.3, [1.1, 2.4, 3.6], frame)
	_hs_curtain(cx + 3.6, cx + half, wz - 0.1, 4.4, 1.3, [1.1, 2.4, 3.6], frame)
	var dx := cx - 5.8
	_mesh(self, _box(Vector3(2.2, 0.1, 0.16)), frame, Vector3(dx, 2.35, wz - 0.06))
	for sx in [-1.0, 0.0, 1.0]:
		_mesh(self, _box(Vector3(0.1, 2.35, 0.16)), frame, Vector3(dx + sx * 1.1, 1.17, wz - 0.06))
	var steel := _shared(Color(0.75, 0.76, 0.78), 0.2, 0.0, 0.9)
	for sx in [-1.0, 1.0]:
		_mesh(self, _box(Vector3(0.04, 0.8, 0.05)), steel, Vector3(dx + sx * 0.14, 1.1, wz + 0.02))
	# 기둥(뒤 띠 — 걸을 곳 밖)
	for x in [cx - 5.0, cx + 5.0]:
		_hs_column(Vector3(x, 0, wz + 0.45), 0.36, 4.4, Color(0.78, 0.76, 0.72))
	# 양옆: 왼쪽 대기 소파 · 화분, 오른쪽 출입 게이트(엘리베이터 쪽)
	_hs_sofa(Vector3(b.position.x - 1.2, 0, b.get_center().y - 0.4), 90.0, Color(0.16, 0.16, 0.18), 2.0)
	_hs_planter(Vector3(b.position.x - 1.1, 0, b.position.y - 0.2))
	_hs_planter(Vector3(b.end.x + 1.1, 0, b.position.y - 0.2))
	for i in 3:
		_hs_gate(Vector3(b.end.x + 1.0, 0, b.get_center().y - 1.2 + i * 1.2))
	for sx in [-1.0, 1.0]:                                                                    # 옆벽(낮게)
		_mesh(self, _box(Vector3(0.3, 1.2, b.size.y + 2.8)), stone, Vector3(cx + sx * half, 0.6, b.get_center().y - 0.6))
	_omni(Vector3(cx - 3.6, 3.2, -0.6), Color(1.0, 0.9, 0.76), 1.3, 8.5)
	_omni(Vector3(cx + 3.6, 3.2, -0.6), Color(1.0, 0.9, 0.76), 1.3, 8.5)
	_omni(Vector3(cx, 2.0, b.position.y - 0.4), Color(1.0, 0.82, 0.55), 1.0, 4.5)            # 데스크 · 간판
	if not _detail:
		return
	# 난투 흔적 — 금 간 유리(왼쪽 유리벽 028/042) · 유리 조각 · 흩어진 서류 · 손도끼 · 칼
	_hs_crack(Vector3(cx - 4.25, 1.3, wz - 0.07), 0.9, 3)
	_mesh(self, _hs_shards(Rect2(cx - 5.4, b.position.y + 0.1, 2.4, 1.2), 14, 4), _hs_glass(Color(0.8, 0.9, 1.0, 0.55)), Vector3.ZERO)
	_hs_papers(Rect2(cx - 2.5, b.position.y + 0.1, 5.0, 2.2), 7, 5)
	_hs_hatchet(Vector3(cx + 2.2, 0, 1.1), 35.0)
	_hs_knife(Vector3(cx - 1.4, 0, 1.7), -20.0)
	_hs_knife(Vector3(cx + 4.4, 0, -1.3), 110.0)


## 안내 데스크(앞 = +z) — 어두운 돌 몸 · 밝은 상판 · 발밑 띠 조명 · 앞판 간판 · 모니터 둘 · 의자 둘
func _hs_reception(at: Vector3, w: float) -> void:
	_mesh(self, _box(Vector3(w, 1.05, 0.7)), _shared(Color(0.2, 0.19, 0.19), 0.25, 0.0, 0.1), at + Vector3(0, 0.525, 0))
	_mesh(self, _box(Vector3(w + 0.12, 0.05, 0.86)), _shared(Color(0.5, 0.48, 0.45), 0.2), at + Vector3(0, 1.075, 0.06))
	_mesh(self, _box(Vector3(w - 0.3, 0.04, 0.02)), _glow(Color(1.0, 0.85, 0.55), 1.8), at + Vector3(0, 0.1, 0.36))
	_label(at + Vector3(0, 0.62, 0.356), SIGN, Color(0.85, 0.74, 0.5), 56, 0.005)
	for sx in [-1.0, 1.0]:
		_mesh(self, _box(Vector3(0.55, 0.45, 0.5)), _shared(Color(0.08, 0.08, 0.09), 0.5), at + Vector3(sx * 1.2, 0.45, -0.7))   # 의자
		_mesh(self, _box(Vector3(0.55, 0.6, 0.1)), _shared(Color(0.08, 0.08, 0.09), 0.5), at + Vector3(sx * 1.2, 0.9, -0.95))
	if _detail:
		for sx in [-1.0, 1.0]:
			_mesh(self, _box(Vector3(0.5, 0.32, 0.03)), _shared(Color(0.05, 0.05, 0.06), 0.3), at + Vector3(sx * 1.2, 1.3, -0.15))
			_mesh(self, _box(Vector3(0.46, 0.27, 0.01)), _glow(Color(0.35, 0.55, 0.9), 1.2), at + Vector3(sx * 1.2, 1.3, -0.17))


## 쌍둥이 빌딩 표(빛나는 세로 막대 둘 + 가운데 구름다리)
func _hs_twin_mark(at: Vector3, h: float) -> void:
	var m := _glow(Color(0.95, 0.82, 0.52), 1.6)
	for sx in [-1.0, 1.0]:
		_mesh(self, _box(Vector3(0.14, h, 0.03)), m, at + Vector3(sx * 0.13, 0, 0))
	_mesh(self, _box(Vector3(0.12, 0.05, 0.03)), m, at + Vector3(0, -h * 0.08, 0))


## 로비 출입 게이트(낮은 기둥 + 유리 날개)
func _hs_gate(at: Vector3) -> void:
	_mesh(self, _box(Vector3(1.1, 0.95, 0.18)), _shared(Color(0.7, 0.71, 0.73), 0.25, 0.0, 0.8), at + Vector3(0, 0.475, 0))
	_mesh(self, _box(Vector3(0.04, 0.6, 0.42)), _hs_glass(Color(0.6, 0.75, 0.95, 0.3)), at + Vector3(-0.3, 0.75, 0.3))
	_mesh(self, _box(Vector3(0.3, 0.02, 0.1)), _glow(Color(0.3, 1.0, 0.5), 2.0), at + Vector3(0.25, 0.96, 0))


# ======================== 우측 빌딩 로비 · 중앙계단 ========================

## 우측 빌딩 로비 · 중앙계단(구름다리 층으로) — 뒤 가운데 넓은 계단(유리 난간 · 스테인리스 손잡이 · 디딤판 발밑 등)이 위로 올라가
## 화면 밖으로 사라진다(높은 천장 느낌) · 양옆 높은 돌벽(세로로 긴 창) · 높은 기둥 · 구름다리 안내판 · 'TOWER B' 글
func _hs_stairs(b: Rect2) -> void:
	var cx := b.get_center().x
	var wz := b.position.y - 0.8
	var half := b.size.x * 0.5 + 3.6
	var sw := 5.0                                    # 계단 폭
	var n := 14
	var rise := 0.19
	var run := 0.31
	_env(Color(0.3, 0.28, 0.27), 0.62, Color(0.015, 0.015, 0.025))
	_top(Color(1.0, 0.95, 0.88), 0.48)
	_hs_floor(Rect2(cx - half, wz, half * 2.0, b.end.y + 5.0 - wz), Color(0.56, 0.55, 0.53), Color(0.4, 0.4, 0.42), 1.2, 2)
	var step := _shared(Color(0.62, 0.61, 0.58), 0.3)
	var nose := _shared(Color(0.3, 0.3, 0.32), 0.4, 0.0, 0.4)
	var led := _glow(Color(1.0, 0.88, 0.65), 1.6)
	for i in n:
		var top := rise * (i + 1)
		var z := wz - run * (i + 0.5)
		_mesh(self, _box(Vector3(sw, top, run)), step, Vector3(cx, top * 0.5, z))
		_mesh(self, _box(Vector3(sw, 0.02, 0.05)), nose, Vector3(cx, top + 0.005, z + run * 0.5 - 0.03))
		if i % 2 == 0:
			for sx in [-1.0, 1.0]:
				_mesh(self, _box(Vector3(0.03, 0.04, 0.12)), led, Vector3(cx + sx * (sw * 0.5 - 0.06), top - rise * 0.5, z + run * 0.5 + 0.005))
	var top_y := rise * n
	var land := 3.0
	_mesh(self, _box(Vector3(sw + 1.0, top_y, land)), step, Vector3(cx, top_y * 0.5, wz - run * n - land * 0.5))       # 층참(구름다리 층)
	_mesh(self, _box(Vector3(sw + 6.0, 8.0, 0.3)), _shared(Color(0.2, 0.19, 0.19), 0.5), Vector3(cx, 4.0, wz - run * n - land))
	# 유리 난간 · 손잡이(기운 판 — 계단 기울기)
	var slope := atan2(rise, run)
	var ln := run * n / cos(slope)
	var glass := _hs_glass(Color(0.6, 0.75, 0.9, 0.22))
	var steel := _shared(Color(0.78, 0.79, 0.81), 0.2, 0.0, 0.9)
	for sx in [-1.0, 1.0]:
		var x: float = cx + sx * (sw * 0.5 - 0.03)
		var mid := Vector3(x, top_y * 0.5, wz - run * n * 0.5)
		var g := _mesh(self, _box(Vector3(0.025, 0.95, ln)), glass, mid + Vector3(0, 0.55, 0))
		g.rotation_degrees.x = rad_to_deg(slope)
		var r := _mesh(self, _box(Vector3(0.06, 0.06, ln)), steel, mid + Vector3(0, 1.05, 0))
		r.rotation_degrees.x = rad_to_deg(slope)
		_mesh(self, _cyl(0.05, 0.05, 1.1), steel, Vector3(x, 0.55, wz - 0.06))                          # 첫 기둥
		_mesh(self, _box(Vector3(0.12, top_y, run * n)), _shared(Color(0.3, 0.3, 0.32), 0.3, 0.0, 0.3),
			Vector3(cx + sx * (sw * 0.5 + 0.06), top_y * 0.5, wz - run * n * 0.5))                        # 옆판
	# 양옆 높은 돌벽 · 세로 창 · 기둥
	var wall := _shared(Color(0.62, 0.6, 0.57), 0.45)
	var seg := half - sw * 0.5 - 0.6
	for sx in [-1.0, 1.0]:
		var wx: float = cx + sx * (sw * 0.5 + 0.6 + seg * 0.5)
		_mesh(self, _box(Vector3(seg, 7.0, 0.3)), wall, Vector3(wx, 3.5, wz - 0.15))
		_mesh(self, _box(Vector3(seg, 0.14, 0.34)), _shared(Color(0.3, 0.3, 0.32), 0.4), Vector3(wx, 0.07, wz - 0.13))
		for k in 2:
			var x: float = cx + sx * (sw * 0.5 + 2.4 + k * 2.6)
			_mesh(self, _box(Vector3(0.9, 5.4, 0.04)), _glow(Color(0.1, 0.16, 0.32), 0.6), Vector3(x, 3.6, wz + 0.01))   # 세로 창(밤)
			_mesh(self, _box(Vector3(1.04, 0.1, 0.08)), _shared(Color(0.22, 0.22, 0.24), 0.4, 0.0, 0.6), Vector3(x, 0.9, wz + 0.03))
			_mesh(self, _box(Vector3(0.06, 5.4, 0.08)), _shared(Color(0.22, 0.22, 0.24), 0.4, 0.0, 0.6), Vector3(x, 3.6, wz + 0.04))
		_hs_column(Vector3(cx + sx * (sw * 0.5 + 0.95), 0, wz + 0.45), 0.34, 7.0, Color(0.8, 0.78, 0.74))
		_mesh(self, _box(Vector3(0.3, 1.2, b.size.y + 2.4)), wall, Vector3(cx + sx * half, 0.6, b.get_center().y - 0.4))   # 옆벽(낮게)
	# 안내판(구름다리 층) · 빌딩 글 · 화분
	var pole := _shared(Color(0.25, 0.25, 0.27), 0.4, 0.0, 0.6)
	var sx0 := cx - sw * 0.5 - 1.75
	_mesh(self, _cyl(0.03, 0.03, 1.2), pole, Vector3(sx0, 0.6, wz + 0.4))
	_mesh(self, _box(Vector3(0.9, 0.5, 0.04)), _shared(Color(0.12, 0.13, 0.16), 0.4), Vector3(sx0, 1.4, wz + 0.4))
	_label(Vector3(sx0, 1.5, wz + 0.425), "구름다리 ▲", Color(0.95, 0.9, 0.75), 30, 0.004)
	_label(Vector3(sx0, 1.32, wz + 0.425), "SKY BRIDGE", Color(0.7, 0.75, 0.85), 22, 0.004)
	var gx := cx + sw * 0.5 + 3.0
	_hs_twin_mark(Vector3(gx - 1.25, 1.95, wz + 0.03), 0.42)
	_label(Vector3(gx + 0.2, 1.95, wz + 0.03), SIGN + "  TOWER B", Color(0.3, 0.28, 0.26), 48, 0.005)
	_hs_planter(Vector3(cx - half + 1.0, 0, wz + 0.5))
	_hs_planter(Vector3(cx + half - 1.0, 0, wz + 0.5))
	_omni(Vector3(cx - 2.6, 3.4, -0.4), Color(1.0, 0.9, 0.75), 1.3, 8.0)
	_omni(Vector3(cx + 2.8, 3.4, 0.2), Color(1.0, 0.9, 0.75), 1.2, 8.0)
	_omni(Vector3(cx, 3.4, wz - 1.8), Color(0.8, 0.85, 1.0), 1.4, 6.0)                       # 계단 위(구름다리 층에서 오는 빛)
	if not _detail:
		return
	# 난투 흔적 — 넘어진 화분 · 흙 · 칼 · 서류
	var pot := _mesh(self, _cyl(0.24, 0.18, 0.55), _shared(Color(0.85, 0.84, 0.8), 0.4), Vector3(cx + 4.1, 0.22, b.position.y + 0.5))
	pot.rotation_degrees = Vector3(0, 0, 80)
	var q2 := _mesh(self, _sphere(0.4), _shared(Color(0.14, 0.28, 0.12), 0.9), Vector3(cx + 3.55, 0.3, b.position.y + 0.55))
	q2.scale = Vector3(1.2, 0.6, 1.0)
	_stain(Vector3(cx + 3.1, 0, b.position.y + 0.7), 0.35, _shared(Color(0.2, 0.14, 0.09), 0.95), 21)
	_hs_knife(Vector3(cx - 1.8, 0, 1.4), 60.0)
	_hs_knife(Vector3(cx + 1.2, 0, -1.6), -30.0)
	_hs_papers(Rect2(cx - 4.0, -1.0, 3.0, 2.4), 5, 8)


# ======================== 최상층 아래 — 대표실 앞 복도 · 위층 복도 ========================

## 대표실이 있는 층의 긴 복도(dark = false: 대표실 앞 · 불 켜짐 / true: 위층 복도 · 불 나감 — 비상등 · 오른쪽 끝 출구).
## 바닥 어두운 돌 판 + 남색 카펫(금줄). 뒷벽 왼쪽부터 사무실 유리벽(칸막이 · 젖빛 띠 · 안의 책상 · 모니터) · 타일 벽(엘리베이터 둘 —
## 멈춤) · 끝: 대표실 큰 문(나무 판벽) 또는 비상 계단문(열림 · 초록 비상구 등). 양 끝 벽은 높게(옆이라 가리지 않는다)
func _hs_top_floor(b: Rect2, dark: bool) -> void:
	var cx := b.get_center().x
	var cz := b.get_center().y
	var wz := b.position.y - 1.0                     # 뒷벽 앞면(띠 1m — 소파 · 화분)
	var ex0 := b.position.x - 0.6                    # 양 끝 벽
	var ex1 := b.end.x + 0.6
	var hh := 3.2
	if dark:
		_env(Color(0.07, 0.08, 0.12), 0.55, Color(0.005, 0.005, 0.01))
		_top(Color(0.6, 0.68, 0.9), 0.22)
	else:
		_env(Color(0.27, 0.23, 0.2), 0.58, Color(0.01, 0.01, 0.012))
		_top(Color(1.0, 0.9, 0.78), 0.45)
	_hs_floor(Rect2(ex0, wz, ex1 - ex0, b.end.y + 4.0 - wz), Color(0.24, 0.24, 0.26), Color(0.14, 0.14, 0.16), 0.8, 3, 0.4)
	_hs_runner(Rect2(ex0, cz - 0.95, ex1 - ex0, 1.9))
	var glass_end := cx - 1.8                       # 사무실 유리벽 오른쪽 끝
	var wood_x := cx + 3.4                           # (대표실 앞) 나무 판벽 시작
	# 사무실 유리벽 + 안(어두운 사무실)
	var frame := _shared(Color(0.18, 0.18, 0.2), 0.4, 0.0, 0.6)
	_hs_curtain(ex0, glass_end, wz - 0.05, hh, 1.2, [hh - 0.05], frame)
	_mesh(self, _box(Vector3(glass_end - ex0, 0.32, 0.01)), _hs_glass(Color(0.92, 0.94, 0.96, 0.55)), Vector3((ex0 + glass_end) * 0.5, 1.2, wz - 0.03))   # 젖빛 띠
	_mesh(self, _hs_plane(Vector2(glass_end - ex0, 4.0)), _shared(Color(0.12, 0.12, 0.13), 0.7), Vector3((ex0 + glass_end) * 0.5, 0.002, wz - 2.1))
	_mesh(self, _box(Vector3(glass_end - ex0, hh, 0.2)), _shared(Color(0.1, 0.1, 0.11), 0.9), Vector3((ex0 + glass_end) * 0.5, hh * 0.5, wz - 4.1))
	var desk := _shared(Color(0.55, 0.53, 0.5), 0.5)
	var part := _shared(Color(0.32, 0.34, 0.38), 0.8)
	var mon_on := _glow(Color(0.35, 0.55, 0.9), 1.4)
	var mon_off := _shared(Color(0.04, 0.04, 0.05), 0.3)
	var chair := _shared(Color(0.1, 0.1, 0.12), 0.6)
	var k := 0
	var x := ex0 + 1.1
	while x < glass_end - 0.6:
		_mesh(self, _box(Vector3(1.4, 0.05, 0.7)), desk, Vector3(x, 0.74, wz - 1.0))
		_mesh(self, _box(Vector3(1.4, 0.5, 0.04)), part, Vector3(x, 1.0, wz - 1.38))
		var lit := (k % 2 == 0) if not dark else (k == 1)
		_mesh(self, _box(Vector3(0.5, 0.32, 0.03)), mon_on if lit else mon_off, Vector3(x, 0.98, wz - 1.2))
		_mesh(self, _box(Vector3(0.5, 0.1, 0.5)), chair, Vector3(x + 0.2, 0.48, wz - 0.55))         # 의자(밀려 나옴)
		_mesh(self, _box(Vector3(0.5, 0.55, 0.08)), chair, Vector3(x + 0.2, 0.8, wz - 0.32))
		_mesh(self, _box(Vector3(1.4, 0.05, 0.7)), desk, Vector3(x, 0.74, wz - 2.2))                # 둘째 줄
		_mesh(self, _box(Vector3(0.5, 0.32, 0.03)), mon_off, Vector3(x, 0.98, wz - 2.4))
		k += 1
		x += 1.9
	# 타일 벽(엘리베이터)
	var tile_end := ex1 if dark else wood_x
	_hs_tile_wall(glass_end, tile_end, wz, hh)
	for ix in [cx - 0.3, cx + 1.6]:
		_hs_elevator(Vector3(ix, 0, wz), dark)
	_mesh(self, _box(Vector3(0.12, 0.3, 0.03)), _shared(Color(0.7, 0.7, 0.72), 0.3, 0.0, 0.8), Vector3(cx + 0.65, 1.15, wz + 0.015))
	_mesh(self, _box(Vector3(0.36, 0.56, 0.12)), _shared(Color(0.7, 0.1, 0.08), 0.5), Vector3(glass_end + 0.45, 0.45, wz + 0.06))   # 소화기 함
	_mesh(self, _box(Vector3(0.28, 0.08, 0.01)), _shared(Color(0.95, 0.95, 0.9), 0.6), Vector3(glass_end + 0.45, 0.62, wz + 0.125))
	_mesh(self, _box(Vector3(0.7, 0.36, 0.03)), _shared(Color(0.12, 0.12, 0.14), 0.4), Vector3(cx + 0.65, 1.9, wz + 0.015))         # 층 표지
	_label(Vector3(cx + 0.65, 1.9, wz + 0.035), FLOOR_NO + "F", Color(0.9, 0.88, 0.8), 40, 0.005)
	_mesh(self, _box(Vector3(ex1 - ex0, 0.1, 0.04)), _shared(Color(0.12, 0.12, 0.13), 0.5), Vector3(cx, 0.05, wz + 0.02))   # 굽도리
	if dark:
		_hs_exit(b, ex1)
	else:
		_hs_ceo_door(b, wz, wood_x, ex1, hh)
	for sx in ([-1.0] if _hs_joined else [-1.0, 1.0]):                                       # 양 끝 벽(높게 — 이어 그릴 때 오른쪽은 문틀)
		var exx: float = ex0 if sx < 0.0 else ex1
		_mesh(self, _box(Vector3(0.2, hh, b.size.y + 2.4)), _shared(Color(0.46, 0.44, 0.42) if not dark else Color(0.3, 0.3, 0.32), 0.7),
			Vector3(exx + sx * 0.1, hh * 0.5, (wz + b.end.y + 1.0) * 0.5))
	# 뒤 띠: 소파(경호원들이 앉아 대기 025/058) · 화분 · 정수기
	_hs_sofa(Vector3(ex0 + 2.0, 0, wz + 0.45), 0.0, Color(0.12, 0.12, 0.14), 1.8)
	_hs_sofa(Vector3(glass_end - 1.4, 0, wz + 0.45), 0.0, Color(0.12, 0.12, 0.14), 1.8)
	_hs_planter(Vector3(cx + 2.75, 0, wz + 0.4))
	_mesh(self, _box(Vector3(0.34, 1.05, 0.34)), _shared(Color(0.85, 0.85, 0.86), 0.4), Vector3(cx - 1.35, 0.525, wz + 0.22))   # 정수기
	_mesh(self, _cyl(0.13, 0.13, 0.36), _hs_glass(Color(0.5, 0.7, 0.95, 0.5)), Vector3(cx - 1.35, 1.23, wz + 0.22))
	if dark:
		for lx in [ex0 + 1.2, cx - 1.0, cx + 3.6]:                                             # 비상등(벽 위 — 붉게 깜빡)
			var m := _mat(Color(1.0, 0.2, 0.12), 0.5)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.18, 0.1)
			m.emission_energy_multiplier = 3.2
			_blink.append(m)
			_mesh(self, _box(Vector3(0.36, 0.12, 0.1)), m, Vector3(lx, 2.55, wz + 0.05))
		_omni(Vector3(cx - 2.6, 2.5, wz + 0.8), Color(1.0, 0.3, 0.22), 1.3, 7.5)
		_omni(Vector3(b.end.x - 0.4, 1.9, cz), Color(0.3, 1.0, 0.5), 1.3, 5.0)
		_omni(Vector3(ex0 + 1.8, 2.4, wz + 0.5), Color(0.45, 0.55, 1.0), 0.8, 7.0)           # 사무실 창으로 드는 밤빛
	else:
		_omni(Vector3(cx - 4.6, 2.7, cz - 0.6), Color(1.0, 0.85, 0.65), 1.4, 6.5)
		_omni(Vector3(cx + 0.4, 2.7, cz - 0.6), Color(1.0, 0.85, 0.65), 1.4, 6.5)
		_omni(Vector3(cx + 4.8, 2.7, cz - 0.6), Color(1.0, 0.82, 0.6), 1.4, 6.5)
	if not _detail:
		return
	# 작은 소품 — 떨어진 칼 · 서류(위층: 쓰러진 경호원들 자리 029/125 — 휴대폰 손전등 026/033-044)
	_hs_papers(Rect2(cx - 5.0, cz - 1.6, 4.0, 3.2), 5, 11 if dark else 12)
	_hs_knife(Vector3(cx - 2.6, 0, cz + 1.2), 70.0)
	if dark:
		_hs_knife(Vector3(cx + 0.2, 0, cz - 1.5), -40.0)
		_hs_knife(Vector3(cx - 4.8, 0, cz + 0.5), 15.0)
		_mesh(self, _box(Vector3(0.08, 0.012, 0.16)), _shared(Color(0.05, 0.05, 0.06), 0.3), Vector3(cx - 3.6, 0.006, cz - 1.0))   # 휴대폰(불 켜짐)
		_mesh(self, _box(Vector3(0.06, 0.004, 0.12)), _glow(Color(0.9, 0.95, 1.0), 2.5), Vector3(cx - 3.6, 0.014, cz - 1.0))
		_stain(Vector3(cx - 3.6, 0, cz - 0.7), 0.28, _hs_glass(Color(0.85, 0.9, 1.0, 0.12)), 31)                              # 손전등 빛 자국
	else:
		_hs_frame_art(Vector3(wood_x + 0.9, 1.75, wz + 0.02))
		_console(Vector3(wood_x + 0.9, 0, wz))                                                   # 벽 탁자 · 꽃병(town3d)


## 복도 → 대표실 한 맵(haseong_ceo)
func _hs_ceo(b: Rect2) -> void:
	_hs_joined = true
	var c := Rect2(b.position.x, b.position.y + 0.1, CEO_CORRIDOR, b.size.y - 0.2)
	_hs_top_floor(c, false)
	_hs_office(Rect2(b.end.x - CEO_OFFICE, b.position.y, CEO_OFFICE, b.size.y))
	_open_doorway(c.end.x + 0.6, c)                                       # 열린 문틀 — 대표실로 걸어 들어간다
	_hs_joined = false


## 대표실 문 — 나무 판벽 · 큰 두 짝 문(금 손잡이 · 위 띠) · 문패 '대표이사실' · 벽등 둘
func _hs_ceo_door(b: Rect2, wz: float, x0: float, x1: float, hh: float) -> void:
	var wd := Color(0.24, 0.14, 0.08)
	var wood := _hs_cached("wood", func() -> Texture2D: return _stripe_tex([wd, wd, wd, wd.darkened(0.15), wd, wd, wd, wd.darkened(0.5)]))
	var w := x1 - x0
	_mesh(self, _box(Vector3(w, hh, 0.3)), _shared(wd, 0.6), Vector3((x0 + x1) * 0.5, hh * 0.5, wz - 0.15))
	if _detail:
		_panel(Vector3((x0 + x1) * 0.5, hh * 0.5, wz + 0.004), Vector2(w, hh), wood, Vector2(w / 0.8, 1), Color.WHITE, 0.45)
	var dx := b.end.x - 1.6
	if _hs_joined:                                                        # 문은 오른쪽 끝 문틀(열림) — 판벽에는 문패 · 벽등만
		_mesh(self, _box(Vector3(0.7, 0.2, 0.02)), _shared(Color(0.86, 0.7, 0.32), 0.3, 0.0, 0.85), Vector3(x1 - 0.7, 1.6, wz + 0.01))
		_label(Vector3(x1 - 0.7, 1.6, wz + 0.025), "대표이사실 ▶", Color(0.2, 0.12, 0.05), 28, 0.0042)
		_mesh(self, _box(Vector3(0.14, 0.3, 0.06)), _glow(Color(1.0, 0.78, 0.5), 1.8), Vector3(x0 + 0.5, 2.0, wz + 0.03))
		return
	var trim := _shared(Color(0.14, 0.08, 0.04), 0.4)
	var leaf := _shared(Color(0.2, 0.11, 0.06), 0.35)
	var gold := _shared(Color(0.86, 0.7, 0.32), 0.3, 0.0, 0.85)
	_mesh(self, _box(Vector3(2.3, 2.95, 0.08)), trim, Vector3(dx, 1.475, wz + 0.04))
	for sx in [-1.0, 1.0]:
		_mesh(self, _box(Vector3(1.0, 2.75, 0.06)), leaf, Vector3(dx + sx * 0.52, 1.375, wz + 0.09))
		_mesh(self, _box(Vector3(0.04, 0.7, 0.05)), gold, Vector3(dx + sx * 0.12, 1.25, wz + 0.15))
	_mesh(self, _box(Vector3(2.3, 0.06, 0.1)), gold, Vector3(dx, 2.98, wz + 0.06))
	_mesh(self, _box(Vector3(0.7, 0.2, 0.02)), gold, Vector3(dx - 1.75, 1.6, wz + 0.01))
	_label(Vector3(dx - 1.75, 1.6, wz + 0.025), "대표이사실", Color(0.2, 0.12, 0.05), 28, 0.0042)
	for lx in [x0 + 0.5, dx + 1.55]:
		_mesh(self, _box(Vector3(0.14, 0.3, 0.06)), _glow(Color(1.0, 0.78, 0.5), 1.8), Vector3(lx, 2.0, wz + 0.03))


## 위층 복도 오른쪽 끝 출구(따돌리기 방 — haseong.gd upper_corridor escape exit Rect2(5.6, -2.0, 1.4, 4.0)) — 오른쪽 끝 벽(카메라에 늘 보이는
## 옆면)의 열린 비상 계단문(바깥으로 열림 — 안은 초록 빛 · 오르는 계단 실루엣) · 초록 비상구 등 · '대표실 ▲' · 바닥 초록 화살표 셋 ·
## 출구 칸 테두리(걸을 곳 안은 모두 납작)
func _hs_exit(b: Rect2, ex1: float) -> void:
	var exit := Rect2(b.end.x - 1.4, b.position.y, 1.4, b.size.y)
	var dz := b.get_center().y
	var steel := _shared(Color(0.4, 0.42, 0.42), 0.4, 0.0, 0.6)
	var hole := _mesh(self, _hs_plane(Vector2(2.2, 1.3)), _glow(Color(0.1, 0.42, 0.2), 0.9), Vector3(ex1 - 0.01, 1.1, dz))   # 문 안(계단실)
	hole.rotation_degrees = Vector3(0, 0, 90)
	var dark := _shared(Color(0.03, 0.06, 0.04), 0.9)
	for i in 4:
		var st := _mesh(self, _box(Vector3(0.01, 0.05, 1.2)), dark, Vector3(ex1 - 0.015, 0.3 + i * 0.42, dz))     # 오르는 계단 실루엣
		st.rotation_degrees.x = -25.0
	for sz in [-1.0, 1.0]:
		_mesh(self, _box(Vector3(0.14, 2.3, 0.1)), steel, Vector3(ex1 - 0.05, 1.15, dz + sz * 0.7))
	_mesh(self, _box(Vector3(0.14, 0.1, 1.5)), steel, Vector3(ex1 - 0.05, 2.3, dz))
	var green := _glow(Color(0.2, 1.0, 0.45), 2.6)
	_mesh(self, _box(Vector3(0.06, 0.26, 0.8)), green, Vector3(ex1 - 0.04, 2.62, dz))
	var l1 := _label(Vector3(ex1 - 0.075, 2.62, dz), "비상구 EXIT", Color(1, 1, 1), 26, 0.0042)
	l1.rotation_degrees.y = -90.0
	var l2 := _label(Vector3(ex1 - 0.01, 1.6, dz - 1.25), "대표실 ▲", Color(0.75, 1.0, 0.8), 30, 0.0045)
	l2.rotation_degrees.y = -90.0
	var floor_g := _glow(Color(0.2, 0.95, 0.4), 1.4)
	for ax in [exit.position.x - 2.6, exit.position.x - 1.4, exit.position.x + 0.3]:
		for sz in [-1.0, 1.0]:
			var c := _mesh(self, _box(Vector3(0.5, 0.006, 0.09)), floor_g, Vector3(ax, 0.007, b.get_center().y + sz * 0.16))
			c.rotation_degrees.y = sz * 40.0
	for e in [Rect2(exit.position.x, exit.position.y, 0.06, exit.size.y), Rect2(exit.position.x, exit.position.y, exit.size.x, 0.06),
			Rect2(exit.position.x, exit.end.y - 0.06, exit.size.x, 0.06)]:
		_decal(e, floor_g, 0.006)


## 타일 벽(큰 돌 판 — 결은 대리석 결을 판 크기로)
func _hs_tile_wall(x0: float, x1: float, wz: float, hh: float) -> void:
	var w := x1 - x0
	var base := Color(0.56, 0.55, 0.53)
	_mesh(self, _box(Vector3(w, hh, 0.3)), _shared(base, 0.4), Vector3((x0 + x1) * 0.5, hh * 0.5, wz - 0.15))
	if _detail:
		var t := _hs_marble(base, Color(0.42, 0.42, 0.43), 4)
		_panel(Vector3((x0 + x1) * 0.5, hh * 0.5, wz + 0.004), Vector2(w, hh), t, Vector2(w / 0.8, hh / 0.8), Color.WHITE, 0.3)


## 엘리베이터(멈춤 — 024/039 도지웅이 상황실에서 멈춤). stopped 면 붉은 '정지', 아니면 층 번호
func _hs_elevator(at: Vector3, stopped: bool) -> void:
	_mesh(self, _box(Vector3(1.5, 2.55, 0.08)), _shared(Color(0.3, 0.3, 0.32), 0.3, 0.0, 0.7), at + Vector3(0, 1.275, 0.04))
	for sx in [-1.0, 1.0]:
		_mesh(self, _box(Vector3(0.62, 2.3, 0.04)), _shared(Color(0.7, 0.7, 0.72), 0.2, 0.0, 0.9), at + Vector3(sx * 0.32, 1.15, 0.09))
	var ind := _glow(Color(1.0, 0.2, 0.1) if stopped else Color(1.0, 0.6, 0.2), 2.4)
	_mesh(self, _box(Vector3(0.42, 0.14, 0.03)), ind, at + Vector3(0, 2.72, 0.04))
	_label(at + Vector3(0, 2.72, 0.06), "정지" if stopped else FLOOR_NO, Color(1, 0.95, 0.85), 24, 0.004)


## 작은 그림(나무 판벽 — 금테)
func _hs_frame_art(at: Vector3) -> void:
	_mesh(self, _box(Vector3(0.9, 0.62, 0.04)), _shared(Color(0.75, 0.6, 0.28), 0.35, 0.0, 0.8), at)
	_mesh(self, _box(Vector3(0.78, 0.5, 0.01)), _shared(Color(0.22, 0.3, 0.36), 0.8), at + Vector3(0, 0, 0.022))


## 복도 카펫 — 남색 바탕 · 금줄 · 가장자리 짙은 띠(결 하나를 1m 마다)
func _hs_runner(r: Rect2) -> void:
	var c := Color(0.11, 0.13, 0.22)
	if not _detail:
		_decal(r, _shared(c, 0.95), 0.005)
		return
	var tex := _hs_cached("runner", func() -> Texture2D: return _hs_runner_tex())
	var m := _hs_cached_mat("runner_m", tex, Vector3(r.size.x / 1.0, 1, 1), 0.95)
	_mesh(self, _hs_plane(r.size), m, Vector3(r.get_center().x, 0.005, r.get_center().y))


func _hs_runner_tex() -> ImageTexture:
	var img := Image.create(16, 32, false, Image.FORMAT_RGB8)
	var field := Color(0.11, 0.13, 0.22)
	var dark := Color(0.05, 0.06, 0.1)
	var gold := Color(0.55, 0.44, 0.2)
	for y in 32:
		for x in 16:
			var c := field
			if y <= 1 or y >= 30:
				c = dark
			elif y == 3 or y == 28:
				c = gold
			elif (x == 7 or x == 8) and (y % 8 == 3 or y % 8 == 4):
				c = field.lightened(0.18)
			img.set_pixel(x, y, c)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


# ======================== 대표실(불 꺼짐) ========================

## 대표실(불 꺼짐) — 뒤: 왼쪽 나무 벽(큰 지도 화면 · 청화백자 진열장), 오른쪽 바닥까지 큰 고층 창(밤 도시 · 폐쇄된 좌측 빌딩 · 구름다리) —
## 창 하나는 깨짐(날카로운 유리 테 · 바람에 날리는 커튼 · 바닥에 유리 조각). 왼쪽 밖 넓은 책상(의자 · 리볼버 · 탄 · 문패),
## 오른쪽 밖 소파 · 낮은 탁자 · 조각상. 바닥 짙은 나무 · 양탄자 · 깨진 와인잔
func _hs_office(b: Rect2) -> void:
	var cx := b.get_center().x
	var cz := b.get_center().y
	var wz := b.position.y - 0.65
	var half := b.size.x * 0.5 + 3.4
	var hh := 3.6
	if not _hs_joined:                                                    # 이어 그릴 때는 복도의 환경 · 위 빛 하나(둘이면 겹친다)
		_env(Color(0.09, 0.11, 0.2), 0.6, Color(0.01, 0.015, 0.035))
		_top(Color(0.6, 0.7, 1.0), 0.35)
	# 바닥 — 짙은 나무 판 · 양탄자 · 방 밖 어둠
	var fw := Color(0.16, 0.1, 0.07)
	var fm := _mat(fw, 0.35)
	if _detail:
		fm.albedo_color = Color.WHITE
		fm.albedo_texture = _hs_cached("planks", func() -> Texture2D: return _stripe_tex([fw, fw, fw.lightened(0.06), fw, fw.darkened(0.12), fw, fw.lightened(0.03), fw.darkened(0.4)]))
		fm.uv1_scale = Vector3(1, (b.size.y + 6.0) / 1.2, 1)
	fm.metallic_specular = 0.7
	_mesh(self, _hs_plane(Vector2(half * 2.0, b.end.y + 5.0 - wz)), fm, Vector3(cx, 0, (wz + b.end.y + 5.0) * 0.5))
	_decal(Rect2(cx - 3.4, cz - 1.9, 6.8, 3.8), _shared(Color(0.17, 0.16, 0.2), 0.95), 0.005)
	_decal(Rect2(cx - 3.1, cz - 1.6, 6.2, 3.2), _shared(Color(0.24, 0.2, 0.17), 0.95), 0.007)
	# 뒷벽 왼쪽(나무) · 큰 지도 화면 · 진열장
	var gx0 := cx - 2.2                              # 유리창 시작
	var wall := _shared(Color(0.13, 0.09, 0.07), 0.55)
	_mesh(self, _box(Vector3(gx0 - (cx - half), hh, 0.3)), wall, Vector3((gx0 + cx - half) * 0.5, hh * 0.5, wz - 0.15))
	_hs_map_screen(Vector3(cx - 5.3, 1.75, wz + 0.02), Vector2(3.0, 1.5))
	_hs_vitrine(Vector3(cx - 3.0, 0, wz + 0.25))
	# 큰 창(바닥까지) — 칸마다 유리 한 장, 깨진 칸은 유리 테만
	var frame := _shared(Color(0.08, 0.08, 0.09), 0.4, 0.0, 0.6)
	var gx1 := cx + half
	var bay := 1.7
	var nb := int(ceil((gx1 - gx0) / bay))
	var broken := int(floor((cx + 2.4 - gx0) / bay))
	var glass := _hs_glass(Color(0.5, 0.62, 0.85, 0.1))
	for i in nb:
		var bx := gx0 + bay * (i + 0.5)
		if i == broken:
			# 김신이 총으로 깨는 칸(2026-11-12 사용자 '대표실 창문 쏴서 깨트리고') — 처음엔 성한 유리, 장면 fx glass 에 깨진 테로
			var whole := _mesh(self, _box(Vector3(bay, hh - 0.2, 0.02)), glass, Vector3(bx, hh * 0.5, wz))
			var shards := _mesh(self, _hs_jagged(bay, hh - 0.2, 5), _hs_glass(Color(0.7, 0.8, 0.95, 0.22)), Vector3(bx, 0.1, wz))
			_brk_glass(whole, shards, Vector2(bx, wz), 1.0)
		else:
			_mesh(self, _box(Vector3(bay, hh - 0.2, 0.02)), glass, Vector3(bx, hh * 0.5, wz))
		_mesh(self, _box(Vector3(0.08, hh, 0.14)), frame, Vector3(gx0 + bay * i, hh * 0.5, wz + 0.02))
	_mesh(self, _box(Vector3(gx1 - gx0, 0.1, 0.2)), frame, Vector3((gx0 + gx1) * 0.5, 0.05, wz))
	_mesh(self, _box(Vector3(gx1 - gx0, 0.12, 0.2)), frame, Vector3((gx0 + gx1) * 0.5, hh, wz))
	var bx0 := gx0 + bay * (broken + 0.5)
	var cur := _mesh(self, _box(Vector3(0.6, hh - 0.3, 0.02)), _hs_glass(Color(0.6, 0.62, 0.7, 0.16)), Vector3(bx0 + bay * 0.5 + 0.2, (hh - 0.3) * 0.5, wz + 0.35))
	cur.rotation_degrees = Vector3(0, -35, 4)                                                   # 바람에 날리는 얇은 커튼
	_hs_city(wz - 1.0, half * 2.0 + 30.0)
	for sx in ([1.0] if _hs_joined else [-1.0, 1.0]):                                         # 옆벽(낮게 — 이어 그릴 때 왼쪽은 문틀)
		_mesh(self, _box(Vector3(0.3, 1.2, b.size.y + 2.4)), wall, Vector3(cx + sx * half, 0.6, cz - 0.3))
	# 왼쪽 밖: 넓은 책상(앞 = +x) · 의자 — 이어 그릴 때는 왼쪽 띠가 복도에서 들어오는 길이라 책상을 뒤 창가로 돌려 놓는다(앞 = +z)
	var dg := _group(Vector3(b.position.x - 1.25, 0, cz - 0.6) if not _hs_joined else Vector3(b.position.x - 1.8, 0, wz + 1.35), 0.0 if not _hs_joined else -90.0)
	var dk := Vector3.ZERO
	var dw := _shared(Color(0.2, 0.11, 0.06), 0.3)
	_mesh(dg, _box(Vector3(1.1, 0.07, 2.8)), dw, dk + Vector3(0, 0.77, 0))
	_mesh(dg, _box(Vector3(0.95, 0.72, 2.6)), dw, dk + Vector3(-0.05, 0.36, 0))
	_mesh(dg, _box(Vector3(0.03, 0.04, 2.5)), _shared(Color(0.8, 0.65, 0.3), 0.3, 0.0, 0.8), dk + Vector3(0.48, 0.74, 0))
	var lea := _shared(Color(0.06, 0.05, 0.05), 0.45)
	_mesh(dg, _box(Vector3(0.7, 0.14, 0.7)), lea, dk + Vector3(-1.0, 0.5, 0.1))
	_mesh(dg, _box(Vector3(0.16, 1.05, 0.72)), lea, dk + Vector3(-1.32, 1.05, 0.1))
	# 오른쪽 밖: 소파 · 낮은 탁자 · 조각상
	_hs_sofa(Vector3(b.end.x + 1.35, 0, cz - 0.2), -90.0, Color(0.32, 0.3, 0.28), 2.4)
	_mesh(self, _box(Vector3(0.7, 0.4, 1.3)), _shared(Color(0.1, 0.1, 0.1), 0.2, 0.0, 0.3), Vector3(b.end.x + 0.45, 0.2, cz - 0.2))
	var sp := Vector3(b.end.x + 0.9, 0, wz + 0.55)
	_mesh(self, _box(Vector3(0.5, 0.9, 0.5)), _shared(Color(0.75, 0.73, 0.7), 0.4), sp + Vector3(0, 0.45, 0))
	var bronze := _shared(Color(0.32, 0.22, 0.12), 0.35, 0.0, 0.7)
	_mesh(self, _cyl(0.1, 0.16, 0.8), bronze, sp + Vector3(0, 1.3, 0))
	_mesh(self, _sphere(0.13), bronze, sp + Vector3(0, 1.82, 0))
	# 빛: 지도 화면(파랑) · 깨진 창으로 드는 도시빛 · 오른쪽 낮은 채움
	_omni(Vector3(cx - 5.3, 1.8, wz + 1.0), Color(0.35, 0.6, 1.0), 1.5, 6.5)
	_omni(Vector3(bx0, 2.2, wz + 0.8), Color(0.6, 0.7, 1.0), 1.1, 7.0)
	if not _hs_joined:                                                    # 이어 그릴 때는 복도 점광 셋 + 둘(폰 — 점광 다섯)
		_omni(Vector3(b.end.x + 0.4, 2.2, cz + 0.6), Color(0.85, 0.75, 0.65), 0.5, 5.5)
	if not _detail:
		return
	# 작은 소품 — 바닥 유리 조각(깨진 창 앞) · 깨진 와인잔 · 책상 위(리볼버 · 탄 · 문패 · 끈 등)
	_mesh(self, _hs_shards(Rect2(bx0 - 1.1, b.position.y + 0.05, 2.2, 1.4), 22, 6), _hs_glass(Color(0.75, 0.82, 0.95, 0.3)), Vector3.ZERO)
	_stain(Vector3(b.position.x + 0.8, 0, cz - 1.0), 0.3, _shared(Color(0.22, 0.02, 0.04), 0.9), 41)
	_mesh(self, _hs_shards(Rect2(b.position.x + 0.5, cz - 1.3, 0.7, 0.6), 6, 7), _hs_glass(Color(0.9, 0.92, 1.0, 0.6)), Vector3.ZERO)
	var y := 0.81
	var gun := _shared(Color(0.7, 0.72, 0.75), 0.25, 0.0, 0.9)
	_mesh(dg, _box(Vector3(0.05, 0.04, 0.24)), gun, dk + Vector3(0.1, y + 0.02, -0.4))
	var q3 := _mesh(dg, _box(Vector3(0.05, 0.12, 0.05)), _shared(Color(0.3, 0.18, 0.1), 0.5), dk + Vector3(0.1, y + 0.03, -0.25))
	q3.rotation_degrees.x = 70
	var brass := _shared(Color(0.85, 0.66, 0.3), 0.3, 0.0, 0.85)
	for i in 4:
		_mesh(dg, _cyl(0.008, 0.008, 0.03), brass, dk + Vector3(0.2 + 0.04 * i, y + 0.015, -0.1 + 0.03 * (i % 2)))
	_mesh(dg, _box(Vector3(0.42, 0.08, 0.06)), _shared(Color(0.05, 0.04, 0.03), 0.3), dk + Vector3(0.2, y + 0.04, 1.0))
	_label_in(dg, dk + Vector3(0.2, y + 0.045, 1.035), "대표이사", Color(0.85, 0.7, 0.35), 22, 0.004)


## 부진폐차장 사무실(2장 끝 — 2026-11-12 사용자 "사무실로 가서 김신, 김대건, 서진태, 차수민, 이슬이 차수민 폐차장 내부 쇼파에 다 같이
## 앉아서 멘트하는걸로"): 컨테이너 사무실 — 낡은 나무 바닥 · 함석 벽 · 창 너머 폐차 더미 불빛 · ㄷ 자 소파 셋(뒤 · 왼쪽 · 오른쪽)과 낮은 탁자 ·
## 차수민 책상(서류 · 전화) · 철제 서류장 · 달력. 앉는 자리는 haseong.gd junkyard_end standing(소파 위)
func _hs_junk_office(b: Rect2) -> void:
	var cx := b.get_center().x
	var cz := b.get_center().y
	_env(Color(0.3, 0.24, 0.18), 0.6, Color(0.02, 0.015, 0.01))
	_top(Color(1.0, 0.85, 0.65), 0.5)
	var fw := Color(0.3, 0.22, 0.15)
	var fm := _mat(fw, 0.7)
	if _detail:
		fm.albedo_color = Color.WHITE
		fm.albedo_texture = _hs_cached("junk_planks", func() -> Texture2D: return _stripe_tex([fw, fw.darkened(0.1), fw, fw.lightened(0.05), fw.darkened(0.35)]))
		fm.uv1_scale = Vector3(1, (b.size.y + 4.0) / 1.0, 1)
	_mesh(self, _hs_plane(Vector2(b.size.x + 4.0, b.size.y + 4.0)), fm, Vector3(cx, 0, cz + 1.0))
	_back_wall(b, Color(0.36, 0.38, 0.36), 3.0)
	var wz := b.position.y - 1.07                                         # 뒷벽 앞면 = wz + 0.42(_back_wall z - 0.8 + 0.15)
	for k in 9:                                                           # 함석 골
		_mesh(self, _box(Vector3(0.04, 2.9, 0.03)), _shared(Color(0.28, 0.3, 0.28), 0.6, 0.0, 0.4), Vector3(cx - 4.0 + k, 1.45, wz + 0.42))
	# 창(밤 폐차장 — 주황 작업등 · 쌓인 차) · 달력 · 시계
	_mesh(self, _box(Vector3(2.2, 1.1, 0.04)), _glow(Color(0.95, 0.6, 0.3), 0.6), Vector3(cx + 1.8, 1.7, wz + 0.45))
	_mesh(self, _box(Vector3(2.3, 0.08, 0.1)), _shared(Color(0.2, 0.2, 0.2), 0.5), Vector3(cx + 1.8, 1.12, wz + 0.48))
	_mesh(self, _box(Vector3(0.05, 1.1, 0.08)), _shared(Color(0.2, 0.2, 0.2), 0.5), Vector3(cx + 1.8, 1.7, wz + 0.48))
	_mesh(self, _box(Vector3(0.5, 0.7, 0.02)), _shared(Color(0.92, 0.9, 0.85), 0.9), Vector3(cx - 1.6, 1.8, wz + 0.44))
	_mesh(self, _box(Vector3(0.5, 0.12, 0.025)), _shared(Color(0.75, 0.15, 0.12), 0.8), Vector3(cx - 1.6, 2.1, wz + 0.45))
	# ㄷ 자 소파(낡은 갈색 가죽 · 녹색 천) · 낮은 탁자(재떨이 · 캔)
	_hs_sofa(Vector3(cx, 0, cz - 1.35), 0.0, Color(0.36, 0.24, 0.16), 2.6)
	_hs_sofa(Vector3(cx - 2.25, 0, cz + 0.15), 90.0, Color(0.22, 0.3, 0.24), 2.0)
	_hs_sofa(Vector3(cx + 2.25, 0, cz + 0.15), -90.0, Color(0.22, 0.3, 0.24), 2.0)
	var tb := Vector3(cx, 0, cz + 0.05)
	_mesh(self, _box(Vector3(1.6, 0.06, 0.9)), _shared(Color(0.22, 0.14, 0.08), 0.4), tb + Vector3(0, 0.42, 0))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_mesh(self, _box(Vector3(0.06, 0.4, 0.06)), _shared(Color(0.15, 0.1, 0.06), 0.5), tb + Vector3(0.7 * sx, 0.2, 0.38 * sz))
	_mesh(self, _cyl(0.09, 0.07, 0.04), _shared(Color(0.55, 0.55, 0.58), 0.3, 0.0, 0.7), tb + Vector3(-0.3, 0.47, 0.1))
	for k in 3:
		_mesh(self, _cyl(0.035, 0.035, 0.12), _shared([Color(0.75, 0.1, 0.1), Color(0.2, 0.45, 0.8), Color(0.85, 0.8, 0.2)][k], 0.3, 0.0, 0.6),
			tb + Vector3(0.2 + 0.12 * k, 0.51, -0.12 + 0.1 * (k % 2)))
	# 간이침대(탁자 앞 — 신태진이 눕는다, 방 표 junkyard_end lie_bed · 2026-11-12 사용자 "침대에 좀 눕혀줘"): 쇠 다리 · 매트 · 베개 · 담요
	var cot := Vector3(cx + 0.3, 0, cz + 1.35)
	var steel := _shared(Color(0.3, 0.32, 0.33), 0.4, 0.0, 0.7)
	_mesh(self, _box(Vector3(2.1, 0.06, 0.86)), steel, cot + Vector3(0, 0.36, 0))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_mesh(self, _box(Vector3(0.05, 0.36, 0.05)), steel, cot + Vector3(1.0 * sx, 0.18, 0.39 * sz))
	_mesh(self, _box(Vector3(2.0, 0.12, 0.8)), _shared(Color(0.62, 0.6, 0.52), 0.9), cot + Vector3(0, 0.45, 0))
	_mesh(self, _box(Vector3(0.42, 0.1, 0.6)), _shared(Color(0.85, 0.84, 0.78), 0.9), cot + Vector3(-0.76, 0.55, 0))
	_mesh(self, _box(Vector3(1.0, 0.05, 0.84)), _shared(Color(0.3, 0.34, 0.26), 0.95), cot + Vector3(0.45, 0.52, 0))
	# 차수민 책상 · 의자 · 서류장(오른쪽 뒤)
	var dk := Vector3(b.end.x + 0.6, 0, b.position.y + 0.3)
	_mesh(self, _box(Vector3(1.6, 0.06, 0.8)), _shared(Color(0.4, 0.32, 0.22), 0.5), dk + Vector3(0, 0.76, 0))
	_mesh(self, _box(Vector3(1.5, 0.72, 0.7)), _shared(Color(0.32, 0.25, 0.17), 0.6), dk + Vector3(0, 0.36, 0))
	_mesh(self, _box(Vector3(0.5, 0.04, 0.35)), _shared(Color(0.95, 0.93, 0.88), 0.9), dk + Vector3(-0.3, 0.8, 0.05))
	_mesh(self, _box(Vector3(0.22, 0.09, 0.18)), _shared(Color(0.08, 0.08, 0.08), 0.4), dk + Vector3(0.45, 0.83, 0.0))
	var fc := Vector3(b.position.x - 0.5, 0, b.position.y + 0.1)
	_mesh(self, _box(Vector3(0.6, 1.4, 0.55)), _shared(Color(0.42, 0.45, 0.44), 0.5, 0.0, 0.5), fc + Vector3(0, 0.7, 0))
	for k in 3:
		_mesh(self, _box(Vector3(0.5, 0.02, 0.02)), _shared(Color(0.2, 0.2, 0.2), 0.4), fc + Vector3(0, 0.35 + 0.42 * k, 0.28))
	# 빛: 천장 형광등(살짝 푸른) · 창 너머 주황 · 탁자 위 따뜻한 채움
	_omni(Vector3(cx, 2.7, cz - 0.4), Color(0.9, 0.95, 1.0), 1.2, 7.0)
	_omni(Vector3(cx + 1.8, 1.8, wz + 1.2), Color(1.0, 0.6, 0.3), 0.6, 4.5)
	_omni(Vector3(cx, 1.4, cz + 1.2), Color(1.0, 0.82, 0.6), 0.5, 4.0)


## 큰 지도 화면(026/019 — 불 꺼진 방에서 빛나는 벽 화면): 검은 테 · 파란 지도 결(32x16 — 땅 · 격자 · 붉은 점)
func _hs_map_screen(at: Vector3, size: Vector2) -> void:
	_mesh(self, _box(Vector3(size.x + 0.12, size.y + 0.12, 0.05)), _shared(Color(0.03, 0.03, 0.035), 0.3), at)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(0.9, 0.95, 1.0)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	m.albedo_texture = _hs_cached("map", func() -> Texture2D: return _hs_map_tex()) if _detail else null
	if not _detail:
		m.albedo_color = Color(0.12, 0.3, 0.55)
	var q := QuadMesh.new()
	q.size = size
	_mesh(self, q, m, at + Vector3(0, 0, 0.03))


func _hs_map_tex() -> ImageTexture:
	var r := RandomNumberGenerator.new()
	r.seed = 77
	var img := Image.create(32, 16, false, Image.FORMAT_RGB8)
	var sea := Color(0.04, 0.12, 0.26)
	var land := Color(0.2, 0.55, 0.85)
	var blobs: Array = []
	for i in 7:
		blobs.append(Vector3(r.randf_range(3, 29), r.randf_range(3, 13), r.randf_range(2.0, 4.5)))
	for y in 16:
		for x in 32:
			var c := sea
			for bl in blobs:
				if Vector2(x, y).distance_to(Vector2(bl.x, bl.y)) < bl.z * (0.8 + 0.3 * sin(x * 1.7 + y)):
					c = land
			if x % 8 == 0 or y % 8 == 0:
				c = c.lightened(0.12)
			img.set_pixel(x, y, c)
	for p in [Vector2i(9, 6), Vector2i(22, 9), Vector2i(17, 4)]:
		img.set_pixel(p.x, p.y, Color(1.0, 0.25, 0.2))
	return ImageTexture.create_from_image(img)


## 청화백자 항아리 진열장(026/060 — 낮은 받침 · 유리 상자 · 항아리 둘)
func _hs_vitrine(at: Vector3) -> void:
	_mesh(self, _box(Vector3(1.6, 0.75, 0.45)), _shared(Color(0.1, 0.07, 0.05), 0.4), at + Vector3(0, 0.375, 0))
	_mesh(self, _box(Vector3(1.6, 0.9, 0.45)), _hs_glass(Color(0.7, 0.8, 0.9, 0.12)), at + Vector3(0, 1.2, 0))
	var porc := _shared(Color(0.88, 0.9, 0.92), 0.2)
	var blue := _shared(Color(0.15, 0.25, 0.6), 0.3)
	for sx in [-1.0, 1.0]:
		var p := at + Vector3(sx * 0.42, 0, 0)
		var q5 := _mesh(self, _sphere(0.22), porc, p + Vector3(0, 1.05, 0))
		q5.scale = Vector3(1, 1.15, 1)
		_mesh(self, _cyl(0.226, 0.226, 0.06), blue, p + Vector3(0, 1.08, 0))
		_mesh(self, _cyl(0.09, 0.12, 0.12), porc, p + Vector3(0, 1.36, 0))
	_mesh(self, _box(Vector3(1.0, 0.03, 0.06)), _glow(Color(1.0, 0.9, 0.75), 1.0), at + Vector3(0, 1.62, 0.15))


## 창밖 도시(고층 — 건물은 발밑 아래로) + 폐쇄된 좌측 빌딩(어두움) · 중앙 구름다리 · 지붕 항공등. 결정적(seed)
func _hs_city(z0: float, width: float) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 24
	var body := _shared(Color(0.05, 0.06, 0.09), 0.9)
	var lit := _glow(Color(1.0, 0.82, 0.5), 2.0)
	var lit2 := _glow(Color(0.6, 0.78, 1.0), 1.8)
	var red := _glow(Color(1.0, 0.1, 0.05), 4.0)
	var n := 24 if _detail else 12
	for i in n:
		var x := r.randf_range(-width * 0.5, width * 0.5)
		var z := z0 - r.randf_range(7.0, 42.0)
		var w := r.randf_range(2.0, 5.0)
		var top := r.randf_range(-20.0, -4.0)
		_mesh(self, _box(Vector3(w, 40.0, w)), body, Vector3(x, top - 20.0, z))
		for k in 2:
			_mesh(self, _box(Vector3(w * 0.7, 0.25, 0.05)), lit if r.randf() < 0.65 else lit2, Vector3(x, top - 1.2 - k * 1.8, z + w * 0.5 + 0.03))
		if i % 6 == 0:
			_mesh(self, _box(Vector3(0.2, 0.2, 0.2)), red, Vector3(x, top + 0.15, z))
	# 쌍둥이 — 폐쇄된 좌측 빌딩(불 꺼짐) · 구름다리
	var tw := Vector3(-14.0, 0, z0 - 12.0)
	_mesh(self, _box(Vector3(7.0, 60.0, 7.0)), _shared(Color(0.07, 0.08, 0.11), 0.5, 0.0, 0.3), tw + Vector3(0, -30.0 + 4.0, 0))
	_mesh(self, _box(Vector3(8.0, 2.2, 3.0)), _shared(Color(0.1, 0.12, 0.16), 0.4, 0.0, 0.4), tw + Vector3(6.5, -13.0, 0))
	_mesh(self, _box(Vector3(7.6, 0.3, 0.06)), lit2, tw + Vector3(6.5, -12.6, 1.52))
	_mesh(self, _box(Vector3(1.2, 0.5, 0.05)), lit, tw + Vector3(-1.5, -6.0, 3.53))
	_mesh(self, _box(Vector3(width * 2.0, 0.3, 0.2)), lit, Vector3(0, -22.0, z0 - 70.0))      # 먼 불빛 띠


# ======================== 이 무대 도구 ========================

## 대리석 바닥(r 안) — 상세면 판(tile m) 결을 되풀이, 아니면 바탕 빛깔 하나. 반들반들(빛 번짐)
func _hs_floor(r: Rect2, base: Color, vein: Color, tile: float, seed_v: int, rough := 0.24) -> void:
	var m := _mat(base, rough)
	m.metallic_specular = 0.85
	if _detail:
		m.albedo_color = Color.WHITE
		m.albedo_texture = _hs_marble(base, vein, seed_v)
		m.uv1_scale = Vector3(r.size.x / tile, r.size.y / tile, 1)
	_mesh(self, _hs_plane(r.size), m, Vector3(r.get_center().x, 0, r.get_center().y))


func _hs_marble(base: Color, vein: Color, seed_v: int) -> Texture2D:
	return _hs_cached("marble/%s/%d" % [base.to_html(), seed_v], func() -> Texture2D: return _hs_marble_tex(base, vein, seed_v))


## 대리석 판 결(32x32 = 판 하나, 위 · 왼 가장자리 줄눈) — 바탕 잔점 + 비스듬한 물결 결. 결정적(seed)
func _hs_marble_tex(base: Color, vein: Color, seed_v: int) -> ImageTexture:
	var r := RandomNumberGenerator.new()
	r.seed = 500 + seed_v
	var ph := r.randf() * TAU
	var grout := base.darkened(0.35)
	var img := Image.create(32, 32, false, Image.FORMAT_RGB8)
	for y in 32:
		for x in 32:
			if x == 0 or y == 0:
				img.set_pixel(x, y, grout)
				continue
			var s := sin((x * 0.09 + y * 0.16) * TAU * 0.5 + sin(y * 0.2 + ph) * 1.4)
			var v := pow(1.0 - absf(s), 10.0)
			img.set_pixel(x, y, base.darkened(r.randf() * 0.05).lerp(vein, v * 0.7))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


## 무리(group) 안 글 — 무리가 돌아 있어도 글은 카메라 쪽(+z)을 본다
func _label_in(g: Node3D, at: Vector3, txt: String, col: Color, size := 48, px := 0.005) -> void:
	var l := _label(at, txt, col, size, px)
	remove_child(l)
	g.add_child(l)
	l.position = at
	l.rotation_degrees.y = -g.rotation_degrees.y


## 결 나눠 쓰기(이 무대 안)
func _hs_cached(key: String, make: Callable) -> Texture2D:
	if not _tex.has(key):
		_tex[key] = make.call()
	return _tex[key]


## 결 재질 나눠 쓰기(이 무대 안 — _mats)
func _hs_cached_mat(key: String, tex: Texture2D, uv: Vector3, rough: float) -> StandardMaterial3D:
	if not _mats.has(key):
		var m := _mat(Color.WHITE, rough)
		m.albedo_texture = tex
		m.uv1_scale = uv
		_mats[key] = m
	return _mats[key]


## 투명 재질(유리 · 젖빛 띠 · 얼룩) — 같은 값이면 하나
func _hs_glass(c: Color) -> StandardMaterial3D:
	var k := "hsglass/%s" % c.to_html()
	if not _mats.has(k):
		var m := _mat(c, 0.05, 0.3, 0.0)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.metallic_specular = 0.9
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mats[k] = m
	return _mats[k]


## 납작한 원판(바닥 무늬 — 둥글게 보이게 마디 48)
func _hs_disc(rad: float) -> CylinderMesh:
	var c := _cyl(rad, rad, 0.006)
	c.radial_segments = 48
	return c


func _hs_plane(size: Vector2) -> PlaneMesh:
	var pm := PlaneMesh.new()
	pm.size = size
	return pm


## 격자 유리벽(앞 = +z) — x0 ~ x1, 높이 h: 유리 한 장 · 아래 턱 · 가로살(rows 높이) · 세로살(sp 마다)
func _hs_curtain(x0: float, x1: float, z: float, h: float, sp: float, rows: Array, frame: Material) -> void:
	var w := x1 - x0
	var mx := (x0 + x1) * 0.5
	_mesh(self, _box(Vector3(w, h, 0.02)), _hs_glass(Color(0.45, 0.6, 0.85, 0.12)), Vector3(mx, h * 0.5, z))
	_mesh(self, _box(Vector3(w, 0.12, 0.18)), frame, Vector3(mx, 0.06, z))
	for y in rows:
		_mesh(self, _box(Vector3(w, 0.06, 0.1)), frame, Vector3(mx, y, z + 0.03))
	var n := maxi(1, int(round(w / sp)))
	for i in n + 1:
		_mesh(self, _box(Vector3(0.07, h, 0.12)), frame, Vector3(x0 + w * i / n, h * 0.5, z + 0.03))


## 둥근 기둥(받침 · 위 띠) — 3 메시
func _hs_column(at: Vector3, rad: float, h: float, col: Color) -> void:
	_mesh(self, _cyl(rad, rad, h), _shared(col, 0.25, 0.0, 0.1), at + Vector3(0, h * 0.5, 0))
	_mesh(self, _box(Vector3(rad * 2.4, 0.14, rad * 2.4)), _shared(col.darkened(0.4), 0.3), at + Vector3(0, 0.07, 0))
	_mesh(self, _cyl(rad + 0.02, rad + 0.02, 0.06), _glow(Color(1.0, 0.85, 0.6), 1.0), at + Vector3(0, 2.8, 0))


## 소파(앞 = +z — yaw 90 이면 +x 를 본다). 폭 w
func _hs_sofa(at: Vector3, yaw: float, col: Color, w: float) -> void:
	var g := _group(at, yaw)
	var m := _shared(col, 0.6)
	_mesh(g, _box(Vector3(w, 0.42, 0.72)), m, Vector3(0, 0.21, 0))
	_mesh(g, _box(Vector3(w, 0.45, 0.16)), m, Vector3(0, 0.62, -0.28))
	for sx in [-1.0, 1.0]:
		_mesh(g, _box(Vector3(0.16, 0.58, 0.72)), m, Vector3(sx * (w * 0.5 - 0.08), 0.29, 0))


## 네모 화분(돌 상자 + 잎)
func _hs_planter(at: Vector3) -> void:
	_mesh(self, _box(Vector3(0.6, 0.6, 0.6)), _shared(Color(0.22, 0.22, 0.24), 0.4), at + Vector3(0, 0.3, 0))
	var q6 := _mesh(self, _sphere(0.45), _shared(Color(0.1, 0.24, 0.12), 0.9), at + Vector3(0, 1.0, 0))
	q6.scale = Vector3(1, 1.3, 1)


## 금 간 유리(점 하나에서 뻗는 가는 금 n 줄 — 유리 앞면)
func _hs_crack(at: Vector3, ln: float, seed_v: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 600 + seed_v
	var m := _hs_glass(Color(0.95, 0.97, 1.0, 0.75))
	for i in 5:
		var a := TAU * i / 5.0 + r.randf_range(-0.3, 0.3)
		var l := ln * r.randf_range(0.5, 1.0)
		var c := _mesh(self, _box(Vector3(l, 0.015, 0.01)), m, at + Vector3(cos(a), sin(a), 0) * l * 0.5)
		c.rotation_degrees.z = rad_to_deg(a)


## 바닥 유리 조각(작은 삼각형 n 개 — 메시 하나). 납작(y 0.004)
func _hs_shards(r: Rect2, n: int, seed_v: int) -> ArrayMesh:
	var rg := RandomNumberGenerator.new()
	rg.seed = 700 + seed_v
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in n:
		var c := Vector3(rg.randf_range(r.position.x, r.end.x), 0.004, rg.randf_range(r.position.y, r.end.y))
		var s := rg.randf_range(0.03, 0.09)
		var a := rg.randf() * TAU
		for k in 3:
			var aa := a + TAU * k / 3.0 + rg.randf_range(-0.5, 0.5)
			st.set_normal(Vector3.UP)
			st.add_vertex(c + Vector3(cos(aa), 0, sin(aa)) * s * rg.randf_range(0.5, 1.0))
	return st.commit()


## 깨진 창 칸(폭 w · 높이 h — 아래 가운데가 원점): 테두리에 남은 날카로운 유리 삼각형들(메시 하나 — xy 평면)
func _hs_jagged(w: float, h: float, seed_v: int) -> ArrayMesh:
	var rg := RandomNumberGenerator.new()
	rg.seed = 800 + seed_v
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw := w * 0.5
	var edges := [[Vector2(-hw, 0), Vector2(hw, 0), Vector2(0, 1)], [Vector2(-hw, h), Vector2(hw, h), Vector2(0, -1)],
		[Vector2(-hw, 0), Vector2(-hw, h), Vector2(1, 0)], [Vector2(hw, 0), Vector2(hw, h), Vector2(-1, 0)]]
	for e in edges:
		var a: Vector2 = e[0]
		var c: Vector2 = e[1]
		var inward: Vector2 = e[2]
		var m := 4
		for i in m:
			var p0 := a.lerp(c, float(i) / m)
			var p1 := a.lerp(c, float(i + 1) / m)
			var tip := p0.lerp(p1, rg.randf_range(0.2, 0.8)) + inward * rg.randf_range(0.06, 0.32)
			for v in [p0, p1, tip]:
				st.set_normal(Vector3(0, 0, 1))
				st.add_vertex(Vector3(v.x, v.y, 0))
	return st.commit()


## 흩어진 서류(흰 종이 n 장 — 납작)
func _hs_papers(r: Rect2, n: int, seed_v: int) -> void:
	var rg := RandomNumberGenerator.new()
	rg.seed = 900 + seed_v
	var m := _shared(Color(0.68, 0.68, 0.66), 0.9)
	for i in n:
		var p := _mesh(self, _box(Vector3(0.21, 0.004, 0.3)), m,
			Vector3(rg.randf_range(r.position.x, r.end.x), 0.004 + i * 0.0005, rg.randf_range(r.position.y, r.end.y)))
		p.rotation_degrees.y = rg.randf() * 360.0


## 떨어진 칼(회칼 — 날 · 손잡이, 바닥에 누움)
func _hs_knife(at: Vector3, yaw: float) -> void:
	var g := _group(at, yaw)
	_mesh(g, _box(Vector3(0.26, 0.01, 0.035)), _shared(Color(0.82, 0.84, 0.86), 0.15, 0.0, 0.95), Vector3(0.13, 0.008, 0))
	_mesh(g, _box(Vector3(0.12, 0.025, 0.03)), _shared(Color(0.12, 0.1, 0.08), 0.6), Vector3(-0.06, 0.014, 0))


## 떨어진 손도끼(028/016-017)
func _hs_hatchet(at: Vector3, yaw: float) -> void:
	var g := _group(at, yaw)
	_mesh(g, _box(Vector3(0.4, 0.03, 0.04)), _shared(Color(0.35, 0.22, 0.12), 0.7), Vector3(0, 0.02, 0))
	_mesh(g, _box(Vector3(0.08, 0.02, 0.16)), _shared(Color(0.5, 0.52, 0.55), 0.3, 0.0, 0.8), Vector3(0.18, 0.015, 0.05))
