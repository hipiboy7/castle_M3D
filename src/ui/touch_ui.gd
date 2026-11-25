extends Control
## 터치 조작 v2 — 4+2 엄지 호(Thumb Arc) + Galaxy Z Fold 4 반응형 스케일 + 실시간 스킬 게이지 링 + 벡터 아이콘.
##  - 주 4버튼(베기 · 쳐내기 · 구르기 · 기술)을 오른쪽 엄지 자연 호에 배치하고, 보조 버튼(대시 · 점프 · 앉기 · 교대 · 기술 바꾸기)은
##    바깥 호에 저투명도/컴팩트로 정돈해 화면 가림 최소화 + 오터치 방지.
##  - 기술 버튼을 위로 스와이프해도 skill_next(기술 바꾸기)가 동작한다(기존 skill_next 버튼도 유지).
##  - 모든 기존 버튼 ID · API(stick · take_edges · held · set_label · set_lit) 100% 호환.

const SafeArea = preload("res://src/ui/safe_area.gd")
const FONT_BODY = preload("res://assets/fonts/Pretendard-Bold.otf")

const COL_RING := Color(1, 1, 1, 0.30)
const COL_KNOB := Color(0.95, 0.96, 1.0, 0.55)
const COL_BTN := Color(0.04, 0.045, 0.068, 0.64)
const COL_BTN_SEC := Color(0.04, 0.045, 0.068, 0.42)
const COL_BTN_ON := Color(0.88, 0.20, 0.20, 0.78)
const COL_BTN_LIT := Color(0.95, 0.76, 0.26, 0.72)
const COL_LABEL := Color(0.96, 0.97, 0.99, 0.94)
const STICK_R := 106.0

var stick := Vector2.ZERO
var _stick_idx := -1
var _center := Vector2.ZERO
var _knob := Vector2.ZERO
var _pressed := {}
var _edges := {}
var _skill_drag_idx := -1
var _skill_drag_y0 := 0.0
var _skill_swiped := false
var _skill_ratio := 0.0
var _skill_ready := false
var _free_touches := {}          # 버튼 밖 터치(index → pos) — 두 손가락 핀치 줌 감지
var _pinching := false
var _pinch_d := 0.0
var _pinch_ratio := 1.0
var _pinch_ended := false
var show_pause := false:
	set(v):
		show_pause = v
		queue_redraw()
var show_ff := false:            # 장면 빨리 감기 버튼(장면 연출 중만 — main._set_scene)
	set(v):
		show_ff = v
		queue_redraw()
var show_swap := false:
	set(v):
		show_swap = v
		queue_redraw()
var show_fight := true:         # 싸움 버튼 — 처음 화면에서는 숨긴다
	set(v):
		show_fight = v
		queue_redraw()
var show_art := false:
	set(v):
		show_art = v
		queue_redraw()
var last_tap := Vector2(-1, -1)  # 마지막으로 누른 자리(처음 화면에서 왼쪽 · 오른쪽 고르기)
var _last_safe := Rect2()

# tier 1 = 주 4버튼(크고 선명), tier 2 = 보조 아크(작고 저투명), at = "br" | "tr" | "tl"
var buttons := [
	{"id": "attack", "label": "베기", "r": 74.0, "off": Vector2(-128, -124), "tier": 1, "accent": Color(0.92, 0.24, 0.24)},
	{"id": "parry", "label": "쳐내기", "r": 56.0, "off": Vector2(-264, -92), "tier": 1, "accent": Color(0.36, 0.78, 1.0)},
	{"id": "roll", "label": "구르기", "r": 54.0, "off": Vector2(-104, -268), "tier": 1, "accent": Color(0.98, 0.78, 0.28)},
	{"id": "skill", "label": "기술", "r": 58.0, "off": Vector2(-252, -234), "tier": 1, "accent": Color(0.45, 0.85, 1.0)},
	{"id": "skill_next", "label": "교체", "r": 34.0, "off": Vector2(-354, -280), "tier": 2, "accent": Color(0.65, 0.82, 0.98)},
	{"id": "dash", "label": "대시", "r": 42.0, "off": Vector2(-384, -74), "tier": 2, "accent": Color(0.92, 0.85, 0.65)},
	{"id": "jump", "label": "점프", "r": 42.0, "off": Vector2(-478, -142), "tier": 2, "accent": Color(0.75, 0.90, 0.78)},
	{"id": "crouch", "label": "앉기", "r": 38.0, "off": Vector2(-482, -234), "tier": 2, "accent": Color(0.75, 0.78, 0.88)},
	{"id": "swap", "label": "교대", "r": 44.0, "off": Vector2(-372, -172), "tier": 2, "accent": Color(0.38, 0.86, 1.0)},
	{"id": "pause", "label": "멈춤", "r": 32.0, "off": Vector2(-50, 82), "at": "tr", "tier": 2},
	{"id": "speed", "label": "×1", "r": 32.0, "off": Vector2(-50, 158), "at": "tr", "tier": 2},
	{"id": "zoom", "label": "×1", "sub": "줌", "r": 32.0, "off": Vector2(-50, 234), "at": "tr", "tier": 2},
	{"id": "menu", "label": "메뉴", "r": 32.0, "off": Vector2(-128, 82), "at": "tr", "tier": 2},
	{"id": "ff", "label": "×1", "sub": "빨리", "r": 38.0, "off": Vector2(-134, 162), "at": "tr", "tier": 1, "accent": Color(0.98, 0.78, 0.28)},
	{"id": "art", "label": "그림", "r": 40.0, "off": Vector2(64, 188), "at": "tl", "tier": 2},
	{"id": "bench", "label": "성능", "r": 40.0, "off": Vector2(64, 286), "at": "tl", "tier": 2},
	{"id": "difficulty", "label": "보통", "sub": "난이도", "r": 42.0, "off": Vector2(72, 74), "at": "tl", "tier": 2},
]


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_dt: float) -> void:
	var sa := SafeArea.rect(get_viewport())
	if sa != _last_safe:
		_last_safe = sa
		queue_redraw()


## Galaxy Z Fold 4(커버 23:9 · 펼침 6:5) 반응형 스케일
func _ui_scale(sa: Rect2) -> float:
	return clampf(minf(sa.size.x / 1280.0, sa.size.y / 720.0), 0.78, 1.12)


func _btn_r(b: Dictionary, sc: float) -> float:
	return float(b["r"]) * sc


func _btn_pos(b: Dictionary) -> Vector2:
	var sa := SafeArea.rect(get_viewport())
	var sc := _ui_scale(sa)
	var off: Vector2 = (b["off"] as Vector2) * sc
	if b.get("at", "br") == "tr":
		return Vector2(sa.end.x, sa.position.y) + off
	if b.get("at", "br") == "tl":
		return sa.position + off
	return sa.end + off


func _active(b: Dictionary) -> bool:
	match str(b["id"]):
		"pause", "speed", "menu", "zoom":
			return show_pause
		"swap":
			return show_swap
		"ff":
			return show_ff
		"difficulty":
			return show_art
		"art", "bench":
			return false
	return show_fight


## 두 손가락 핀치 거리 변화 → 한 틱 확대/축소 배율(벌리면 > 1, 오므리면 < 1 — 순수 함수, test_ui_logic)
static func pinch_scale(d0: float, d1: float) -> float:
	if d0 < 24.0 or d1 < 24.0:
		return 1.0
	return clampf(d1 / d0, 0.85, 1.18)


func _pinch_dist() -> float:
	var ks := _free_touches.keys()
	if ks.size() < 2:
		return 0.0
	return (_free_touches[ks[0]] as Vector2).distance_to(_free_touches[ks[1]] as Vector2)


func set_skill_state(ratio: float, ready: bool) -> void:
	var r := clampf(ratio, 0.0, 1.0)
	if absf(r - _skill_ratio) > 0.02 or ready != _skill_ready:
		_skill_ratio = r
		_skill_ready = ready
		queue_redraw()


func _input(e: InputEvent) -> void:
	if not visible:
		return
	var sa := SafeArea.rect(get_viewport())
	var sc := _ui_scale(sa)
	if e is InputEventScreenTouch:
		if e.pressed:
			last_tap = e.position
			_edges["tap"] = true
			var hit := false
			for b in buttons:
				if _active(b) and e.position.distance_to(_btn_pos(b)) <= _btn_r(b, sc) * 1.25:
					_pressed[b["id"]] = e.index
					_edges[b["id"]] = true
					_edges["btn_tap"] = true
					hit = true
					if b["id"] == "skill":
						_skill_drag_idx = e.index
						_skill_drag_y0 = e.position.y
						_skill_swiped = false
			if not hit:
				if show_pause:
					_free_touches[e.index] = e.position
				if show_pause and _free_touches.size() >= 2:
					_pinching = true
					_pinch_d = _pinch_dist()
					_stick_idx = -1
					stick = Vector2.ZERO
					_edges.erase("tap")                   # 핀치 시작 시 장면 대사 오넘김 방지
				elif show_fight and e.position.x < sa.position.x + sa.size.x * 0.5 and _stick_idx == -1:
					_stick_idx = e.index
					_edges["stick"] = true
					_center = e.position
					_knob = e.position
					stick = Vector2.ZERO
		else:
			if _free_touches.has(e.index):
				_free_touches.erase(e.index)
				if _pinching and _free_touches.size() < 2:
					_pinching = false
					_pinch_d = 0.0
					_pinch_ended = true
			if e.index == _stick_idx:
				_stick_idx = -1
				stick = Vector2.ZERO
			if e.index == _skill_drag_idx:
				_skill_drag_idx = -1
			for id in _pressed.keys():
				if _pressed[id] == e.index:
					_pressed.erase(id)
		queue_redraw()
	elif e is InputEventScreenDrag:
		if _free_touches.has(e.index):
			_free_touches[e.index] = e.position
			if _pinching and _free_touches.size() >= 2:
				var d_now := _pinch_dist()
				if _pinch_d > 0.0:
					_pinch_ratio *= pinch_scale(_pinch_d, d_now)
				_pinch_d = d_now
				return
		if e.index == _stick_idx:
			var sr := STICK_R * sc
			var d: Vector2 = e.position - _center
			if d.length() > sr:
				_center += d.normalized() * (d.length() - sr)
				d = e.position - _center
			_knob = e.position
			stick = d / maxf(sr, 1.0)
			queue_redraw()
		elif e.index == _skill_drag_idx and not _skill_swiped:
			if _skill_drag_y0 - e.position.y > 38.0 * sc:
				_skill_swiped = true
				_edges["skill_next"] = true
				queue_redraw()


func take_edges() -> Dictionary:
	var e := _edges
	_edges = {}
	return e


func peek_edge(id: String) -> bool:
	return _edges.has(id)


func take_edge(id: String) -> bool:
	return _edges.erase(id)


func set_speed_label(t: String) -> void:
	set_label("speed", t)


func set_zoom_label(t: String) -> void:
	set_label("zoom", t)


func take_pinch() -> float:
	var r := _pinch_ratio
	_pinch_ratio = 1.0
	return r


func take_pinch_ended() -> bool:
	var f := _pinch_ended
	_pinch_ended = false
	return f


func set_lit(id: String, on: bool) -> void:
	for b in buttons:
		if b["id"] == id and b.get("lit", false) != on:
			b["lit"] = on
			queue_redraw()


func set_label(id: String, t: String) -> void:
	for b in buttons:
		if b["id"] == id and b["label"] != t:
			b["label"] = t
			queue_redraw()


func held(id: String) -> bool:
	return _pressed.has(id)


func any_touch() -> bool:
	return not _pressed.is_empty() or _stick_idx != -1


func _draw() -> void:
	var sa := SafeArea.rect(get_viewport())
	var sc := _ui_scale(sa)
	var sr := STICK_R * sc
	if not show_fight:
		pass
	elif _stick_idx != -1:
		draw_circle(_center, sr, Color(0.03, 0.04, 0.06, 0.25))
		draw_arc(_center, sr, 0, TAU, 48, COL_RING, 3.0 * sc, true)
		draw_circle(_knob, 38.0 * sc, COL_KNOB)
		draw_arc(_knob, 38.0 * sc, 0, TAU, 32, Color(1, 1, 1, 0.72), 2.2 * sc, true)
	else:
		var c := Vector2(sa.position.x + 172.0 * sc, sa.end.y - 168.0 * sc)
		draw_arc(c, sr * 0.88, 0, TAU, 48, Color(1, 1, 1, 0.14), 2.5 * sc, true)
		draw_circle(c, 22.0 * sc, Color(1, 1, 1, 0.08))
		draw_string(FONT_BODY, c + Vector2(-46.0 * sc, 7.0 * sc), "이동", HORIZONTAL_ALIGNMENT_CENTER, 92.0 * sc, roundi(18 * sc), Color(1, 1, 1, 0.34))

	for b in buttons:
		if not _active(b):
			continue
		var p := _btn_pos(b)
		var r := _btn_r(b, sc)
		var id := str(b["id"])
		var tier: int = int(b.get("tier", 2))
		var pressed: bool = _pressed.has(id)
		var lit: bool = b.get("lit", false)
		var accent: Color = b.get("accent", Color(0.85, 0.88, 0.95))

		# 바깥 먹선 섀도
		draw_circle(p + Vector2(0, 3.0 * sc), r + 1.5 * sc, Color(0.0, 0.0, 0.0, 0.36 if tier == 1 else 0.22))
		# 바탕 원
		var fill := COL_BTN_ON if pressed else (COL_BTN_LIT if lit else (COL_BTN if tier == 1 else COL_BTN_SEC))
		if id == "skill" and _skill_ready and not pressed:
			fill = Color(0.10, 0.22, 0.32, 0.76)
		draw_circle(p, r, fill)

		# 테두리 링
		var rim_col := Color(accent, 0.92) if (pressed or lit or (id == "skill" and _skill_ready)) else Color(accent, 0.48 if tier == 1 else 0.28)
		draw_arc(p, r, 0, TAU, 48, rim_col, (3.2 if tier == 1 else 2.2) * sc, true)

		# 스킬 버튼 실시간 게이지 진행 호
		if id == "skill":
			var a0 := -PI * 0.5
			var a1 := a0 + TAU * _skill_ratio
			if _skill_ratio > 0.01:
				var gcol := Color(0.36, 0.90, 1.0, 0.96) if _skill_ready else Color(0.35, 0.62, 0.80, 0.68)
				draw_arc(p, r + 3.5 * sc, a0, a1, 40, gcol, 4.2 * sc, true)

		# 버튼 안 벡터 아이콘(주/보조 전투 버튼)
		var icon_a := 0.85 if tier == 1 else 0.62
		var icon_col := Color(1, 1, 1, 0.95) if (pressed or lit) else Color(accent.lightened(0.35), icon_a)
		_draw_icon(id, p, r, sc, icon_col)

		# 텍스트 라벨
		var w := r * 2.0
		var lbl_a := 0.96 if tier == 1 or pressed or lit else 0.78
		if b.has("sub"):
			var sub_sz := roundi((11 if r < 36.0 * sc else 12) * sc)
			var main_sz := roundi((14 if r < 36.0 * sc else 18) * sc)
			draw_string(FONT_BODY, p + Vector2(-r, -5.0 * sc), str(b["sub"]), HORIZONTAL_ALIGNMENT_CENTER, w, sub_sz, Color(COL_LABEL, 0.68))
			draw_string(FONT_BODY, p + Vector2(-r, 14.0 * sc), str(b["label"]), HORIZONTAL_ALIGNMENT_CENTER, w, main_sz, Color(COL_LABEL, lbl_a))
		elif id in ["attack", "parry", "roll", "skill"]:
			draw_string(FONT_BODY, p + Vector2(-r, r * 0.52), str(b["label"]), HORIZONTAL_ALIGNMENT_CENTER, w, roundi((20 if id == "attack" else 16) * sc), Color(COL_LABEL, lbl_a))
		else:
			var fsz := roundi((15 if r < 38.0 * sc else 17) * sc)
			draw_string(FONT_BODY, p + Vector2(-r, 6.0 * sc), str(b["label"]), HORIZONTAL_ALIGNMENT_CENTER, w, fsz, Color(COL_LABEL, lbl_a))


func _draw_icon(id: String, p: Vector2, r: float, sc: float, col: Color) -> void:
	var c := p + Vector2(0, -r * 0.14)
	var lw := 2.8 * sc
	match id:
		"attack":
			# 대각선 칼날/타격 슬래시
			draw_line(c + Vector2(-18, 14) * sc, c + Vector2(18, -18) * sc, col, lw * 1.25, true)
			draw_line(c + Vector2(-8, 12) * sc, c + Vector2(2, 2) * sc, col, lw * 1.5, true)
			draw_arc(c, 22.0 * sc, -PI * 0.85, -PI * 0.15, 16, Color(col, col.a * 0.55), lw * 0.8, true)
		"parry":
			# 날카로운 방패/쳐내기 스파크
			var pts := PackedVector2Array([
				c + Vector2(0, -16) * sc, c + Vector2(14, -9) * sc, c + Vector2(11, 7) * sc,
				c + Vector2(0, 16) * sc, c + Vector2(-11, 7) * sc, c + Vector2(-14, -9) * sc, c + Vector2(0, -16) * sc
			])
			draw_polyline(pts, col, lw, true)
		"roll":
			# 회전 회피 호 + 화살촉
			draw_arc(c, 13.0 * sc, -PI * 0.75, PI * 0.6, 18, col, lw, true)
			draw_line(c + Vector2(-4, 12) * sc, c + Vector2(-12, 10) * sc, col, lw, true)
			draw_line(c + Vector2(-4, 12) * sc, c + Vector2(-7, 4) * sc, col, lw, true)
		"skill":
			# 4각 별 버스트(필살기)
			var s := 16.0 * sc
			var m := 5.5 * sc
			var star := PackedVector2Array([
				c + Vector2(0, -s), c + Vector2(m, -m), c + Vector2(s, 0), c + Vector2(m, m),
				c + Vector2(0, s), c + Vector2(-m, m), c + Vector2(-s, 0), c + Vector2(-m, -m), c + Vector2(0, -s)
			])
			draw_polyline(star, col, lw * 0.9, true)
