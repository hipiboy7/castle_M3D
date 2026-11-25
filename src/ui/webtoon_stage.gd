extends Control
## 2D 원작 웹툰(정연 「캐슬」) 스탠딩 대사창 & 대형 사선 만화 컷인 오버레이.
##  - 장면/스토리 대사(in_scene=true): 좌·우 원작 웹툰 스탠딩 패널 카드 + 하단 느와르 대사창 + 이름표 리본 + 줄바꿈 대사.
##  - 전투 중 대사(in_scene=false): 조이스틱·버튼·보스바를 가리지 않는 상단 중앙 컴팩트 웹툰 초상화 + 이름표 리본 + 대사 토스트.
##  - 기술/카운터/첫 쳐내기/보스 등장/2차 페이즈: 원작 눈매 파노라마 사선 컷인 + 초대형 붓글씨(54~60pt) 기술·카운터 콜아웃.
##  - 순수 레이아웃/판정 함수(stand_rect · dialogue_rect · combat_dialogue_rect · cutin_rect · style_of · should_cutin_parry)는
##    tests/unit/test_portraits.gd 로 검증.

const SafeArea = preload("res://src/ui/safe_area.gd")
const Portraits = preload("res://src/view/portraits.gd")
const FONT_HEAD = preload("res://assets/fonts/BlackHanSans-Regular.ttf")
const FONT_BODY = preload("res://assets/fonts/Pretendard-Bold.otf")

const ASPECT := 340.0 / 400.0
const SLIDE_IN_T := 0.16
const FADE_OUT_T := 0.24
const CUTIN_IN_T := 0.09
const CUTIN_OUT_T := 0.16
const CUTIN_COOLDOWN := 6.5
const STAND_HOLD_EXTRA := 0.45

var in_scene := false:
	set(v):
		if in_scene != v:
			in_scene = v
			queue_redraw()

var _slots := {}                # side(-1 | 1) -> {key, name, style, left, total, age, pulse}
var _dialogue := {}             # {key, name, text, style, side, accent, left, total, age}
var _later_speakers: Array = [] # [delay, id, name, team, text, secs]
var _cutin := {}                # {key, title, sub, side, accent, t, total}
var _cooldowns := {}            # key -> remaining seconds
var _active_side := 0
var _headless := false


func _ready() -> void:
	_headless = DisplayServer.get_name() == "headless"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## 대사 텍스트 → 말투 스타일("shout" | "think" | "talk") 순수 함수
static func style_of(text: String) -> String:
	var t := text.strip_edges()
	if t.begins_with("(") and t.ends_with(")"):
		return "think"
	if t.ends_with("!") or t.ends_with("!!") or t.ends_with("?!"):
		return "shout"
	return "talk"


## 쳐내기(패리) 사선 컷인 발동 여부(순수 함수 — 첫 성공 1회만 발동해 도배 방지, 2026-11-25 사용자 피드백)
static func should_cutin_parry(parry_count: int) -> bool:
	return parry_count == 1


## 장면 대사창 하단 느와르 박스 사각형 계산(Z Fold 4 커버 · 펼침 안전 영역 대응 — 순수 함수)
static func dialogue_rect(sa: Rect2) -> Rect2:
	var w := clampf(sa.size.x - 44.0, 560.0, 1140.0)
	var h := clampf(sa.size.y * 0.215, 134.0, 174.0)
	var x := sa.get_center().x - w * 0.5
	var y := sa.end.y - h - 18.0
	return Rect2(x, y, w, h)


## 전투 중 컴팩트 대사 토스트 사각형 계산(보스 바 아래 · 조이스틱/버튼 위 안전 지대 — 순수 함수)
static func combat_dialogue_rect(sa: Rect2) -> Rect2:
	var w := clampf(sa.size.x * 0.48, 420.0, 620.0)
	var h := 92.0
	var x := sa.get_center().x - w * 0.5
	var y := sa.position.y + 150.0
	return Rect2(x, y, w, h)


## 좌/우 원작 웹툰 스탠딩 패널 사각형 계산(하단 대사창 바로 위 안착 — 순수 함수)
static func stand_rect(sa: Rect2, side: int) -> Rect2:
	var dlg := dialogue_rect(sa)
	var h := clampf(sa.size.y * 0.44, 230.0, 360.0)
	var w := h * ASPECT
	var max_w := sa.size.x * 0.25
	if w > max_w:
		w = max_w
		h = w / ASPECT
	var y := maxf(sa.position.y + 18.0, dlg.position.y - h + 16.0)
	var x := (dlg.position.x + 8.0) if side < 0 else (dlg.end.x - w - 8.0)
	x = clampf(x, sa.position.x + 8.0, sa.end.x - w - 8.0)
	return Rect2(x, y, w, h)


## 사선 만화 컷인 스트립 사각형 계산(보스 바 아래 · 하단 조작 버튼 위 — 순수 함수)
static func cutin_rect(sa: Rect2) -> Rect2:
	var sh := clampf(sa.size.y * 0.255, 152.0, 224.0)
	var y := sa.position.y + clampf(sa.size.y * 0.24, 92.0, 220.0)
	return Rect2(sa.position.x - 40.0, y, sa.size.x + 80.0, sh)


## 대화 발화자 스탠딩 + 이름표 리본 + 대사창 표시(원작 포트레이트 없어도 이름표 + 대사창 안전 표시)
func show_speaker(id_or_look: String, display_name: String, team: int, text: String, secs: float) -> void:
	var clean_txt := text.strip_edges()
	if clean_txt == "":
		return
	var key := Portraits.key_of(id_or_look)
	if key == "" and display_name != "":
		key = Portraits.key_by_name(display_name)
	var st := style_of(clean_txt)
	var shown_txt := clean_txt.substr(1, clean_txt.length() - 2) if st == "think" else clean_txt
	var is_narr := (display_name == "" and key == "")
	var side := 0 if is_narr else _pick_slot_side(key, display_name, team)
	var dur := maxf(secs + (STAND_HOLD_EXTRA if in_scene else 0.25), 1.6)
	var acc := Portraits.accent_color(key) if key != "" else (Color(0.86, 0.20, 0.22) if team != 0 else Color(0.36, 0.78, 0.96))

	if not is_narr and key != "" and Portraits.has_stand(key):
		var existing: Dictionary = _slots.get(side, {})
		var same_person := str(existing.get("key", "")) == key
		_slots[side] = {
			"key": key,
			"name": display_name,
			"style": st,
			"left": dur + 0.6,
			"total": dur + 0.6,
			"age": float(existing.get("age", 0.0)) if same_person else 0.0,
			"pulse": 1.0,
		}
		var opp := -side
		if _slots.has(opp):
			if str(_slots[opp]["key"]) == key:
				_slots.erase(opp)
			else:
				_slots[opp]["left"] = maxf(float(_slots[opp]["left"]), minf(dur + 0.6, 4.5))
		_active_side = side
	elif is_narr:
		_active_side = 0

	_dialogue = {
		"key": key,
		"name": display_name,
		"text": shown_txt,
		"style": "narr" if is_narr else st,
		"side": side,
		"accent": acc,
		"left": dur,
		"total": dur,
		"age": 0.0,
	}
	queue_redraw()


func show_speaker_later(id_or_look: String, display_name: String, team: int, text: String, secs: float, delay: float) -> void:
	if text.strip_edges() == "":
		return
	_later_speakers.append([delay, id_or_look, display_name, team, text, secs])


## 장면 넘기기(탭) 시 현재 대사를 즉시 닫아 다음 대사와 겹치지 않게
func cut_dialogue() -> void:
	_dialogue.clear()
	queue_redraw()


func _pick_slot_side(key: String, display_name: String, team: int) -> int:
	var tag := key if key != "" else display_name
	for s in [-1, 1]:
		if _slots.has(s) and (str(_slots[s]["key"]) == tag or str(_slots[s]["name"]) == display_name):
			return s
	var pref := Portraits.side_of(key, team) if key != "" else (1 if team != 0 else -1)
	if _slots.has(pref) and not _slots.has(-pref):
		return -pref
	return pref


## 사선 만화 컷인 발동(force=false 일 때는 인물별 쿨다운 적용해 과도한 도배 방지)
func trigger_cutin(id_or_look: String, title: String, subtitle := "", team := 0, secs := 0.92, force := false) -> void:
	var key := Portraits.key_of(id_or_look)
	if key == "" or not Portraits.has_cutin(key):
		return
	if not force and float(_cooldowns.get(key, 0.0)) > 0.0:
		return
	_cooldowns[key] = CUTIN_COOLDOWN
	_cutin = {
		"key": key,
		"title": title,
		"sub": subtitle,
		"side": Portraits.side_of(key, team),
		"accent": Portraits.accent_color(key),
		"t": 0.0,
		"total": maxf(secs, 0.55),
	}
	queue_redraw()


func clear_speakers() -> void:
	_slots.clear()
	_dialogue.clear()
	_later_speakers.clear()
	_active_side = 0
	queue_redraw()


func clear_all() -> void:
	_slots.clear()
	_dialogue.clear()
	_later_speakers.clear()
	_cutin.clear()
	_cooldowns.clear()
	_active_side = 0
	queue_redraw()


func _process(dt: float) -> void:
	var dirty := false
	for k in _cooldowns.keys():
		_cooldowns[k] = maxf(0.0, float(_cooldowns[k]) - dt)
		if float(_cooldowns[k]) <= 0.0:
			_cooldowns.erase(k)
	for item in _later_speakers.duplicate():
		item[0] = float(item[0]) - dt
		if float(item[0]) <= 0.0:
			_later_speakers.erase(item)
			show_speaker(str(item[1]), str(item[2]), int(item[3]), str(item[4]), float(item[5]))
			dirty = true
	for s in _slots.keys():
		var sl: Dictionary = _slots[s]
		sl["age"] = float(sl["age"]) + dt
		sl["left"] = float(sl["left"]) - dt
		sl["pulse"] = maxf(0.0, float(sl["pulse"]) - dt * 4.0)
		dirty = true
		if float(sl["left"]) <= 0.0:
			_slots.erase(s)
	if not _dialogue.is_empty():
		_dialogue["age"] = float(_dialogue["age"]) + dt
		_dialogue["left"] = float(_dialogue["left"]) - dt
		dirty = true
		if float(_dialogue["left"]) <= 0.0:
			_dialogue.clear()
	elif _later_speakers.is_empty() and not _slots.is_empty():
		# 대사가 끝나면 스탠딩 카드가 뒤따르는 3D 이동/연출 화면을 오래 가리지 않도록 0.35초 내 자연 퇴장
		for s in _slots.keys():
			_slots[s]["left"] = minf(float(_slots[s]["left"]), FADE_OUT_T + 0.08)
	if not _cutin.is_empty():
		_cutin["t"] = float(_cutin["t"]) + dt
		dirty = true
		if float(_cutin["t"]) >= float(_cutin["total"]):
			_cutin.clear()
	if dirty:
		queue_redraw()


func _ease_out(x: float) -> float:
	var u := clampf(x, 0.0, 1.0)
	return 1.0 - pow(1.0 - u, 3.0)


func _draw() -> void:
	if _headless:
		return
	var sa := SafeArea.rect(get_viewport())
	if in_scene:
		# 1. 장면 연출: 좌·우 원작 웹툰 스탠딩 패널 카드(청자 어둡게 → 발화자 밝게) + 하단 대사창 + 이름표 리본
		for pass_active in [false, true]:
			for s in [-1, 1]:
				if not _slots.has(s):
					continue
				var is_act: bool = (s == _active_side)
				if is_act != pass_active:
					continue
				_draw_stand_card(sa, s, _slots[s], is_act)
		if not _dialogue.is_empty():
			_draw_scene_dialogue(sa, _dialogue)
	else:
		# 2. 전투 중 대사: 조이스틱/버튼/보스바와 절대 안 겹치는 상단 중앙 컴팩트 웹툰 초상화 + 이름표 리본 + 대사 토스트
		if not _dialogue.is_empty():
			_draw_combat_dialogue(sa, _dialogue)
	if not _cutin.is_empty():
		_draw_cutin(sa, _cutin)


func _draw_stand_card(sa: Rect2, side: int, sl: Dictionary, is_active: bool) -> void:
	var key := str(sl["key"])
	var tex := Portraits.stand_tex(key)
	if tex == null:
		return
	var base_r := stand_rect(sa, side)
	var enter := _ease_out(float(sl["age"]) / SLIDE_IN_T)
	var fade := clampf(float(sl["left"]) / FADE_OUT_T, 0.0, 1.0)
	var alpha := enter * fade
	if alpha <= 0.01:
		return
	var style := str(sl["style"])
	var pulse := float(sl["pulse"])
	var slide_x := (1.0 - enter) * 90.0 * float(side)
	var dim_shift := 0.0 if is_active else (14.0 * float(side))
	var scale_k := 1.0 if is_active else 0.91
	if is_active and style == "shout":
		scale_k += 0.03 * (0.4 + 0.6 * pulse)
	var shake := Vector2.ZERO
	if is_active and style == "shout" and pulse > 0.05:
		var ang := float(sl["age"]) * 62.0
		shake = Vector2(sin(ang), cos(ang * 1.3)) * 3.0 * pulse

	var w := base_r.size.x * scale_k
	var h := base_r.size.y * scale_k
	var cx := base_r.get_center().x + slide_x + dim_shift + shake.x
	var by := base_r.end.y + shake.y
	var r := Rect2(cx - w * 0.5, by - h, w, h)
	var acc := Portraits.accent_color(key)

	# 그래픽 노블 먹선 카드 프레임(드롭 섀도 + 먹 테두리 + 상단 악센트 바)
	var frame := r.grow(4.0)
	draw_rect(Rect2(frame.position + Vector2(6.0 * float(-side), 7.0), frame.size), Color(0.01, 0.01, 0.02, 0.66 * alpha))
	if is_active and style == "shout":
		draw_rect(frame.grow(3.0), Color(0.95, 0.16, 0.18, 0.52 * alpha))
	draw_rect(frame, Color(0.03, 0.03, 0.045, 0.96 * alpha))

	# 원작 웹툰 포트레이트 이미지(중앙을 바라보도록 안전한 좌우 반전)
	var flip := Portraits.should_flip(key, side)
	var mod := Color(1.0, 1.0, 1.0, alpha)
	if not is_active:
		mod = Color(0.45, 0.47, 0.54, alpha * 0.90)
	elif style == "think":
		mod = Color(0.84, 0.90, 1.0, alpha)
	if flip:
		var rc := r.get_center()
		draw_set_transform(rc, 0.0, Vector2(-1.0, 1.0))
		draw_texture_rect(tex, Rect2(-r.size * 0.5, r.size), false, mod)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		draw_texture_rect(tex, r, false, mod)

	# 카드 외곽 먹선 + 활성 화자 악센트 테두리 + 하단 자연스러운 암부 페이드
	draw_rect(Rect2(r.position.x, r.end.y - 34.0, r.size.x, 34.0), Color(0.02, 0.02, 0.035, 0.55 * alpha))
	var edge_col := Color(acc, 0.95 * alpha) if is_active else Color(1.0, 1.0, 1.0, 0.18 * alpha)
	draw_rect(frame, edge_col, false, 3.0 if is_active else 1.5)
	if is_active:
		draw_rect(Rect2(frame.position.x, frame.position.y, frame.size.x, 4.5), Color(acc, alpha))


func _draw_scene_dialogue(sa: Rect2, dl: Dictionary) -> void:
	var age := float(dl["age"])
	var alpha := minf(_ease_out(age / 0.12), clampf(float(dl["left"]) / 0.20, 0.0, 1.0))
	if alpha <= 0.01:
		return
	var r := dialogue_rect(sa)
	var acc: Color = dl["accent"]
	var style := str(dl["style"])
	var nm := str(dl["name"])
	var side := int(dl["side"])

	# 하단 느와르 대사 박스(깊은 먹빛 패널 + 상단 악센트 핀스트라이프 + 흰 헤어라인)
	draw_rect(Rect2(r.position + Vector2(5.0, 6.0), r.size), Color(0.0, 0.0, 0.0, 0.58 * alpha))
	draw_rect(r, Color(0.024, 0.027, 0.044, 0.94 * alpha))
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 3.5), Color(acc, 0.96 * alpha))
	draw_rect(r, Color(1.0, 1.0, 1.0, 0.18 * alpha), false, 1.5)
	# 좌우 대각선 악센트 장식 틱
	draw_rect(Rect2(r.position.x, r.position.y, 5.0, r.size.y), Color(acc, 0.85 * alpha))

	# 발화자 이름표 리본(대사창 상단 걸침 — 왼쪽/오른쪽 발화자 쪽에 배치)
	if nm != "":
		var nw := clampf(FONT_HEAD.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 24).x + 56.0, 168.0, 320.0)
		var nh := 40.0
		var nx := (r.position.x + 24.0) if side <= 0 else (r.end.x - nw - 24.0)
		var ny := r.position.y - nh + 4.0
		var poly := PackedVector2Array([
			Vector2(nx + 10.0, ny),
			Vector2(nx + nw, ny),
			Vector2(nx + nw - 10.0, ny + nh),
			Vector2(nx, ny + nh),
		])
		draw_colored_polygon(poly, Color(0.032, 0.035, 0.055, 0.98 * alpha))
		var bar := PackedVector2Array([
			Vector2(nx + 10.0, ny),
			Vector2(nx + 18.0, ny),
			Vector2(nx + 8.0, ny + nh),
			Vector2(nx, ny + nh),
		])
		draw_colored_polygon(bar, Color(acc, alpha))
		var rim := poly.duplicate()
		rim.append(poly[0])
		draw_polyline(rim, Color(acc, 0.78 * alpha), 1.8, true)
		draw_string(FONT_HEAD, Vector2(nx + 24.0, ny + 29.0), nm, HORIZONTAL_ALIGNMENT_LEFT, nw - 34.0, 24, Color(0.99, 0.99, 1.0, alpha))

	# 대사 본문(크고 또렷한 25pt Pretendard Bold + 타자기 전개 0.25초)
	var fsize := 25
	var max_tw := r.size.x - 60.0
	var full_txt := str(dl["text"])
	var lines := _wrap(full_txt, max_tw, FONT_BODY, fsize)
	var lh := FONT_BODY.get_height(fsize) + 6.0
	var total_h := lh * lines.size()
	var y := r.position.y + maxf(24.0, (r.size.y - total_h) * 0.5) + FONT_BODY.get_ascent(fsize) - 2.0
	var tcol := Color(0.97, 0.97, 0.98, alpha)
	if style == "think":
		tcol = Color(0.76, 0.88, 1.0, alpha)
	elif style == "shout":
		tcol = Color(1.0, 0.94, 0.80, alpha)
	elif style == "narr":
		tcol = Color(0.92, 0.90, 0.86, alpha)
	var tx := r.position.x + 30.0
	var align := HORIZONTAL_ALIGNMENT_CENTER if style == "narr" else HORIZONTAL_ALIGNMENT_LEFT
	for ln in lines:
		_draw_outlined_text(FONT_BODY, Vector2(tx, y), ln, align, max_tw, fsize, tcol, Color(0.01, 0.01, 0.02, 0.90 * alpha), 2.0)
		y += lh

	# 우측 하단 "터치하여 다음 ▶" 은은한 펄스 안내
	var blink := 0.55 + 0.45 * sin(age * 5.0)
	draw_string(FONT_BODY, Vector2(r.end.x - 166.0, r.end.y - 12.0), "터치하여 다음 ▶", HORIZONTAL_ALIGNMENT_RIGHT, 150.0, 14, Color(acc.lightened(0.35), 0.82 * blink * alpha))


func _draw_combat_dialogue(sa: Rect2, dl: Dictionary) -> void:
	var age := float(dl["age"])
	var alpha := minf(_ease_out(age / 0.12), clampf(float(dl["left"]) / 0.22, 0.0, 1.0))
	if alpha <= 0.01:
		return
	var r := combat_dialogue_rect(sa)
	var key := str(dl["key"])
	var acc: Color = dl["accent"]
	var nm := str(dl["name"])
	var style := str(dl["style"])
	var tex := Portraits.hud_tex(key) if key != "" else null

	# 상단 중앙 컴팩트 느와르 대사 토스트(조이스틱 · 버튼 · 보스바와 완전히 분리)
	draw_rect(Rect2(r.position + Vector2(3.0, 4.0), r.size), Color(0.0, 0.0, 0.0, 0.50 * alpha))
	draw_rect(r, Color(0.026, 0.030, 0.048, 0.90 * alpha))
	draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 3.0), Color(acc, 0.96 * alpha))
	draw_rect(r, Color(1.0, 1.0, 1.0, 0.16 * alpha), false, 1.2)

	var text_x := r.position.x + 16.0
	var text_w := r.size.x - 32.0
	if tex != null:
		var pr := Rect2(r.position.x + 8.0, r.position.y + 8.0, 76.0, 76.0)
		draw_rect(pr.grow(2.0), Color(acc, 0.88 * alpha))
		draw_texture_rect(tex, pr, false, Color(1.0, 1.0, 1.0, alpha))
		text_x = pr.end.x + 16.0
		text_w = r.end.x - text_x - 14.0

	if nm != "":
		var nw := clampf(FONT_HEAD.get_string_size(nm, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x + 28.0, 96.0, 210.0)
		var nh := 26.0
		var ny := r.position.y - nh + 4.0
		var poly := PackedVector2Array([
			Vector2(text_x, ny),
			Vector2(text_x + nw, ny),
			Vector2(text_x + nw - 8.0, ny + nh),
			Vector2(text_x - 8.0, ny + nh),
		])
		draw_colored_polygon(poly, Color(0.035, 0.038, 0.058, 0.96 * alpha))
		draw_colored_polygon(PackedVector2Array([
			Vector2(text_x, ny), Vector2(text_x + 5.0, ny),
			Vector2(text_x - 3.0, ny + nh), Vector2(text_x - 8.0, ny + nh),
		]), Color(acc, alpha))
		draw_string(FONT_HEAD, Vector2(text_x + 10.0, ny + 20.0), nm, HORIZONTAL_ALIGNMENT_LEFT, nw - 16.0, 18, Color(0.98, 0.98, 1.0, alpha))

	var fsize := 20
	var lines := _wrap(str(dl["text"]), text_w, FONT_BODY, fsize)
	if lines.size() > 2:
		lines = [lines[0], lines[1]]
	var lh := FONT_BODY.get_height(fsize) + 4.0
	var y := r.position.y + maxf(14.0, (r.size.y - lh * lines.size()) * 0.5) + FONT_BODY.get_ascent(fsize) - 2.0
	var tcol := Color(0.76, 0.88, 1.0, alpha) if style == "think" else (Color(1.0, 0.94, 0.80, alpha) if style == "shout" else Color(0.97, 0.97, 0.98, alpha))
	for ln in lines:
		_draw_outlined_text(FONT_BODY, Vector2(text_x, y), ln, HORIZONTAL_ALIGNMENT_LEFT, text_w, fsize, tcol, Color(0.01, 0.01, 0.02, 0.88 * alpha), 1.6)
		y += lh


func _draw_cutin(sa: Rect2, ci: Dictionary) -> void:
	var tex := Portraits.cutin_tex(str(ci["key"]))
	if tex == null:
		return
	var t := float(ci["t"])
	var total := float(ci["total"])
	var in_k := _ease_out(t / CUTIN_IN_T)
	var out_k := clampf((total - t) / CUTIN_OUT_T, 0.0, 1.0)
	var alpha := minf(in_k, out_k)
	if alpha <= 0.01:
		return
	var r := cutin_rect(sa)
	var c := r.get_center()
	var side := int(ci["side"])
	var acc: Color = ci["accent"]
	var slide := (1.0 - in_k) * sa.size.x * 0.60 * float(side) - (1.0 - out_k) * sa.size.x * 0.42 * float(side)
	var drift := (t / maxf(total, 0.01) - 0.5) * -26.0 * float(side)

	draw_set_transform(c + Vector2(slide, 0.0), deg_to_rad(-2.4 if side < 0 else 2.4), Vector2.ONE)
	var local := Rect2(-r.size * 0.5, r.size)
	# 외곽 굵은 먹선 띠 + 상하 악센트 핀스트라이프
	var outer := local.grow_individual(0.0, 11.0, 0.0, 11.0)
	draw_rect(outer, Color(0.015, 0.015, 0.025, 0.96 * alpha))
	draw_rect(Rect2(local.position.x, local.position.y - 5.0, local.size.x, 4.0), Color(acc, 0.98 * alpha))
	draw_rect(Rect2(local.position.x, local.end.y + 1.0, local.size.x, 4.0), Color(acc, 0.98 * alpha))

	# 원작 웹툰 파노라마 눈매 컷인(화면 가로 폭을 꽉 채우되 눈매 중심 유지)
	var tw := float(tex.get_width())
	var th := float(tex.get_height())
	var dst_w := local.size.x + 52.0
	var dst_ar := dst_w / maxf(local.size.y, 1.0)
	var src_h := clampf(tw / maxf(dst_ar, 1.0), th * 0.56, th)
	var src_r := Rect2(0.0, (th - src_h) * 0.5, tw, src_h)
	var ir := Rect2(-dst_w * 0.5 + drift, local.position.y, dst_w, local.size.y)
	draw_rect(local, Color(0.03, 0.025, 0.04, 0.96 * alpha))
	draw_texture_rect_region(tex, ir, src_r, Color(1.0, 1.0, 1.0, alpha))

	# 진입 순간 임팩트 화이트 플래시(0.08초)
	if t < 0.08:
		var fk := (1.0 - t / 0.08) * 0.42
		draw_rect(local, Color(1.0, 0.98, 0.94, fk))

	# 상하 미세 비네트 바 + 텍스트 가독성을 위한 사선 다크 슬래시 리본
	draw_rect(Rect2(local.position.x, local.position.y, local.size.x, 10.0), Color(0.0, 0.0, 0.0, 0.40 * alpha))
	draw_rect(Rect2(local.position.x, local.end.y - 10.0, local.size.x, 10.0), Color(0.0, 0.0, 0.0, 0.48 * alpha))

	# 대형 기술/카운터/보스 타이포그래피(2026-11-25 사용자 피드백: 컷인과 함께 한눈에 알아볼 수 있게 크게!)
	var title := str(ci["title"])
	var sub := str(ci["sub"])
	if title != "":
		var align_left := side < 0
		var box_w := clampf(sa.size.x * 0.64, 520.0, 820.0)
		var box_h := clampf(local.size.y * 0.84, 126.0, 182.0)
		var bx := (-sa.size.x * 0.47) if align_left else (sa.size.x * 0.47 - box_w)
		var by := local.end.y - box_h - 4.0
		var skew := 22.0
		var poly := PackedVector2Array([
			Vector2(bx + (0.0 if align_left else skew), by),
			Vector2(bx + box_w - (skew if align_left else 0.0), by),
			Vector2(bx + box_w, by + box_h),
			Vector2(bx, by + box_h),
		])
		draw_colored_polygon(poly, Color(0.015, 0.016, 0.028, 0.86 * alpha))
		# 굵은 악센트 슬래시 바
		var bar_x := bx if align_left else (bx + box_w - 8.0)
		draw_rect(Rect2(bar_x, by, 8.0, box_h), Color(acc, alpha))
		draw_line(poly[0], poly[1], Color(acc, 0.92 * alpha), 3.0)
		draw_line(poly[3], poly[2], Color(1.0, 1.0, 1.0, 0.25 * alpha), 1.5)

		# 진입 시 임팩트 스케일 펀치(1.18 → 1.0)
		var punch := 1.0 + 0.18 * (1.0 - _ease_out(t / 0.12))
		var ha := HORIZONTAL_ALIGNMENT_LEFT if align_left else HORIZONTAL_ALIGNMENT_RIGHT
		var text_pad := 24.0
		var max_w := box_w - 52.0
		# 긴 기술명도 깔끔히 들어오도록 동적 폰트 크기(기본 68pt 대형 붓글씨!)
		var fsize := 68
		while fsize > 42 and FONT_HEAD.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x > max_w:
			fsize -= 4
		var tx := (bx + text_pad) if align_left else (bx + box_w - text_pad - max_w)
		var sub_y := by + 38.0
		var title_y := by + box_h - 24.0 if sub != "" else (by + box_h * 0.5 + float(fsize) * 0.34)
		if sub != "":
			_draw_outlined_text(FONT_BODY, Vector2(tx, sub_y), sub, ha, max_w, 26,
				Color(acc.lightened(0.45), 0.98 * alpha), Color(0.01, 0.01, 0.02, 0.95 * alpha), 3.0)
		# 악센트 그림자 + 두꺼운 먹선 외곽 + 선명한 순백 붓글씨
		var draw_sz := roundi(float(fsize) * punch)
		draw_string(FONT_HEAD, Vector2(tx + 4.0, title_y + 4.0), title, ha, max_w, draw_sz, Color(acc.darkened(0.25), 0.88 * alpha))
		_draw_outlined_text(FONT_HEAD, Vector2(tx, title_y), title, ha, max_w, draw_sz,
			Color(1.0, 0.99, 0.96, alpha), Color(0.01, 0.01, 0.02, 0.98 * alpha), 4.0)

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_outlined_text(font: Font, pos: Vector2, text: String, align: HorizontalAlignment, width: float,
		fsize: int, col: Color, outline: Color, thick: float) -> void:
	for off in [Vector2(-thick, 0), Vector2(thick, 0), Vector2(0, -thick), Vector2(0, thick),
			Vector2(-thick * 0.7, -thick * 0.7), Vector2(thick * 0.7, thick * 0.7),
			Vector2(-thick * 0.7, thick * 0.7), Vector2(thick * 0.7, -thick * 0.7)]:
		draw_string(font, pos + off, text, align, width, fsize, outline)
	draw_string(font, pos, text, align, width, fsize, col)


func _wrap(text: String, w: float, font: Font, fsize: int) -> Array:
	var out: Array = []
	for para in text.split("\n"):
		var cur := ""
		for word in para.split(" "):
			var trial := word if cur == "" else cur + " " + word
			if font.get_string_size(trial, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x <= w:
				cur = trial
				continue
			if cur != "":
				out.append(cur)
			cur = ""
			for ch in word:
				var t2 := cur + ch
				if font.get_string_size(t2, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x > w and cur != "":
					out.append(cur)
					cur = ch
				else:
					cur = t2
		if cur != "":
			out.append(cur)
	return out
