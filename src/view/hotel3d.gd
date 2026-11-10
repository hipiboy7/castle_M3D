extends "res://src/view/set3d.gd"
## 11장 호텔 캐슬 무대 — 방(src/data/hotel.gd ROOMS theme)마다 바닥 · 벽 · 소품 · 빛. 카메라는 +z 쪽 위에서 내려다보므로
## 뒷벽(-z)이 보인다 — 높은 층은 뒷벽을 유리창으로 두고 그 너머 아래로 도시 야경(기획서 03 3절 '높이 · 유리창 · 도시 야경').
## 원작 근거(canon beats): 28층 중앙홀 = 손님이 있는 홀 · 엘리베이터(057) / 71층 홀 = 둥근 탁자 · 기둥 · 붉은 카펫(058) /
## 회장실 앞 = 푸른 조명 복도(fight:kimshin_shingen place_text) / 회장실 = 비어 있음 · 도시를 내려다봄(062/099-106).
## 폰 성능: 점광 3개 이하 · 그림자는 위에서 오는 빛 하나 · 도시는 상자 몇십 개(같은 재질).

## 이 그림이 그리는 무대 이름(시험 test_campaign 이 장 표의 theme 이 여기 있는지 본다)
const THEMES := ["hall", "vip_hall", "corridor", "blue_corridor", "office", "parking", "stairs"]


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
		"parking":                                       # 지하주차장(043 — 셔터 · 장갑차 행렬 · 기둥 · 왼쪽 비상구)
			_env(Color(0.22, 0.27, 0.24), 0.6, Color(0.01, 0.015, 0.01))
			_top(Color(0.75, 1.0, 0.8), 0.55)
			_floor(b, Color(0.28, 0.28, 0.28), 0.65, false)
			_back_wall(b, Color(0.34, 0.36, 0.34), 3.0)
			for x in range(int(b.position.x) + 2, int(b.end.x), 4):
				_pillar(Vector3(x, 0, b.position.y - 0.3), Color(0.5, 0.52, 0.5))
			for x in [-1.0, 2.6, 5.6]:
				_car(Vector3(x, 0, b.position.y - 1.1), 0.0, Color(0.08, 0.08, 0.1), false)
			for x in range(int(b.position.x) + 1, int(b.end.x), 3):
				_rug(Rect2(x, b.end.y - 1.8, 0.1, 1.6), Color(0.85, 0.85, 0.8))   # 주차선
			var exit := _glow(Color(0.3, 1.0, 0.45), 2.6)                       # 비상구 표시(빠져나갈 곳)
			_mesh(self, _box(Vector3(0.9, 0.3, 0.05)), exit, Vector3(b.position.x + 0.6, 2.4, b.position.y - 0.45))
			_omni(Vector3(-3.0, 2.6, 0.4), Color(0.6, 1.0, 0.7), 1.4, 7.0)
			_omni(Vector3(3.0, 2.6, 0.4), Color(0.6, 1.0, 0.7), 1.4, 7.0)
		"stairs":                                        # 69층 비상구 계단(058/000-024) — 긴 맵: 뒷벽을 따라 오른쪽으로 오르는 계단 · 난간
			_env(Color(0.2, 0.22, 0.26), 0.6, Color(0.01, 0.015, 0.02))
			_top(Color(0.85, 0.9, 1.0), 0.55)
			_floor(b, Color(0.32, 0.32, 0.34), 0.7, false)
			_back_wall(b, Color(0.38, 0.4, 0.42), 4.0)
			var step := _shared(Color(0.46, 0.46, 0.48), 0.75)
			var rail := _shared(Color(0.75, 0.2, 0.15), 0.4, 0.0, 0.6)
			var x := b.position.x + 1.0
			var k := 0
			while x < b.end.x:
				_mesh(self, _box(Vector3(0.5, 0.18 + (k % 12) * 0.18, 0.9)), step, Vector3(x, (0.18 + (k % 12) * 0.18) * 0.5, b.position.y - 0.5))
				x += 0.5
				k += 1
			_mesh(self, _box(Vector3(b.size.x, 0.05, 0.05)), rail, Vector3(b.get_center().x, 1.0, b.position.y + 0.05))
			for xx in range(int(b.position.x) + 2, int(b.end.x), 6):
				var l := Label3D.new()
				l.text = "%dF" % (69 + int((xx - b.position.x) / 12.0))
				l.font_size = 48
				l.pixel_size = 0.006
				l.modulate = Color(0.4, 1.0, 0.5)
				l.position = Vector3(xx, 2.6, b.position.y - 0.4)
				add_child(l)
			_omni(Vector3(b.position.x + 4.0, 2.8, 0.0), Color(0.9, 0.95, 1.0), 1.4, 9.0)
			_omni(Vector3(b.get_center().x, 2.8, 0.0), Color(0.9, 0.95, 1.0), 1.4, 9.0)
			_omni(Vector3(b.end.x - 4.0, 2.8, 0.0), Color(0.9, 0.95, 1.0), 1.4, 9.0)
