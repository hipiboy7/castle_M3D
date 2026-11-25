extends Control
## 2D 웹툰 스탠딩 포트레이트 & 사선 만화 컷인 오버레이(Hades · Persona 5 · 나혼렙 스타일).
##  - 대화/장면 연출 시 좌·우 하단에 느와르 웹툰 반신 스탠딩 등장(발화자 강조 · 청자 어둡게 · 외침/속말 연출 · 이름 리본).
##  - 스킬 발동 · 보스 2차 페이즈 · 엇박 치명타 · 쳐내기 시 사선 만화 눈매 컷인 패널 + 붓글씨 기술명.
##  - 순수 레이아웃/상태 계산 함수(stand_rect · cutin_rect · style_of)는 tests/unit/test_portraits.gd 로 검증.

const SafeArea = preload("res://src/ui/safe_area.gd")
const Portraits = preload("res://src/view/portraits.gd")
const FONT_HEAD = preload("res://assets/fonts/BlackHanSans-Regular.ttf")
const FONT_BODY = preload("res://assets/fonts/Pretendard-Bold.otf")

const ASPECT := 512.0 / 680.0
const SLIDE_IN_T := 0.18
const FADE_OUT_T := 0.28
const CUTIN_IN_T := 0.08
const CUTIN_OUT_T := 0.13
const CUTIN_COOLDOWN := 4.5
const STAND_HOLD_EXTRA := 0.6

var _slots := {}               # side(-1 | 1) -> {key, name, style, left, total, age, active}
var _later_speakers: Array = [] # [delay, id, name, team, text, secs]
var _cutin := {}               # {key, title, sub, side, accent, t, total}
var _cooldowns := {}           # key -> remaining seconds
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


## 좌/우 스탠딩 포트레이트 사각형 계산(Z Fold 4 커버 · 펼침 안전 영역 대응 — 순수 함수)
static func stand_rect(sa: Rect2, side: int) -> Rect2:
	var h := clampf(sa.size.y * 0.56, 280.0, 460.0)
	var w := h * ASPECT
	var max_w := sa.size.x * 0.30
	if w > max_w:
		w = max_w
		h = w / ASPECT
	var y := sa.end.y - h + 8.0
	var x := (sa.position.x + 10.0) if side < 0 else (sa.end.x - w - 10.0)
	return Rect2(x, y, w, h)


## 사선 만화 컷인 스트립 사각형 계산(보스 바 아래 · 하단 조작 버튼 위 — 순수 함수)
static func cutin_rect(sa: Rect2) -> Rect2:
	var sh := clampf(sa.size.y * 0.23, 136.0, 210.0)
	var y := sa.position.y + clampf(sa.size.y * 0.27, 96.0, 240.0)
	return Rect2(sa.position.x - 40.0, y, sa.size.x + 80.0, sh)


## 대화 발화자 스탠딩 표시(이미 떠 있는 상대방은 반대편에서 어둡게 유지 — 2인 대담 구도)
func show_speaker(id_or_look: String, display_name: String, team: int, text: String, secs: float) -> void:
	var key := Portraits.key_of(id_or_look)
	if key == "" or not Portraits.has_stand(key):
		return
	var side := _pick_slot_side(key, team)
	var st := style_of(text)
	var dur := maxf(secs + STAND_HOLD_EXTRA, 1.4)
	var existing: Dictionary = _slots.get(side, {})
	var same_person := str(existing.get("key", "")) == key
	_slots[side] = {
		"key": key,
		"name": display_name,
		"style": st,
		"left": dur,
		"total": dur,
		"age": float(existing.get("age", 0.0)) if same_person else 0.0,
		"pulse": 1.0,
	}
	# 반대편 슬롯이 살아있으면 청자로 유지(대화 중 갑자기 꺼지지 않게 최소 시간 연장)
	var opp := -side
	if _slots.has(opp):
		if str(_slots[opp]["key"]) == key:
			_slots.erase(opp)
		else:
			_slots[opp]["left"] = maxf(float(_slots[opp]["left"]), minf(dur, 2.2))
	_active_side = side
	queue_redraw()


func show_speaker_later(id_or_look: String, display_name: String, team: int, text: String, secs: float, delay: float) -> void:
	if Portraits.key_of(id_or_look) == "":
		return
	_later_speakers.append([delay, id_or_look, display_name, team, text, secs])


func _pick_slot_side(key: String, team: int) -> int:
	# 이미 어느 쪽에 서 있으면 그 자리 유지
	for s in [-1, 1]:
		if _slots.has(s) and str(_slots[s]["key"]) == key:
			return s
	var pref := Portraits.side_of(key, team)
	# 선호 자리가 다른 인물로 차 있고 반대편이 비어 있으면 반대편에 세워 2인 대담 구성
	if _slots.has(pref) and not _slots.has(-pref):
		return -pref
	return pref


## 사선 만화 컷인 발동(force=false 일 때는 인물별 쿨다운 적용해 과도한 도배 방지)
func trigger_cutin(id_or_look: String, title: String, subtitle := "", team := 0, secs := 0.58, force := false) -> void:
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
		"total": maxf(secs, 0.35),
	}
	queue_redraw()


func clear_speakers() -> void:
	_slots.clear()
	_later_speakers.clear()
	_active_side = 0
	queue_redraw()


func clear_all() -> void:
	_slots.clear()
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
	# 비활성 청자를 먼저 그리고, 활성 발화자를 위에 그려 시선 집중
	for pass_active in [false, true]:
		for s in [-1, 1]:
			if not _slots.has(s):
				continue
			var is_act: bool = (s == _active_side)
			if is_act != pass_active:
				continue
			_draw_stand(sa, s, _slots[s], is_act)
	if not _cutin.is_empty():
		_draw_cutin(sa, _cutin)


func _draw_stand(sa: Rect2, side: int, sl: Dictionary, is_active: bool) -> void:
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
	var slide_x := (1.0 - enter) * 110.0 * float(side)
	var dim_shift := 0.0 if is_active else (14.0 * float(side))
	var scale_k := 1.0 if is_active else 0.94
	if is_active and style == "shout":
		scale_k += 0.035 * (0.4 + 0.6 * pulse)
	var shake := Vector2.ZERO
	if is_active and style == "shout" and pulse > 0.05:
		var ang := float(sl["age"]) * 62.0
		shake = Vector2(sin(ang), cos(ang * 1.3)) * 3.0 * pulse

	var w := base_r.size.x * scale_k
	var h := base_r.size.y * scale_k
	var cx := base_r.get_center().x + slide_x + dim_shift + shake.x
	var by := base_r.end.y + shake.y
	var r := Rect2(cx - w * 0.5, by - h, w, h)
	var flip := Portraits.should_flip(key, side)
	var rc := r.get_center()
	var local_r := Rect2(-r.size * 0.5, r.size)
	var acc := Portraits.accent_color(key)

	# 1. 그래픽 노블 먹빛 드롭 실루엣 + 캐릭터 본체(안전한 draw_set_transform 좌우 반전)
	draw_set_transform(rc, 0.0, Vector2(-1.0 if flip else 1.0, 1.0))
	var fx_dir := (-float(side)) if flip else float(side)
	if is_active and style == "shout":
		draw_texture_rect(tex, Rect2(local_r.position + Vector2(-fx_dir * 6.0, -3.0), local_r.size), false, Color(0.95, 0.14, 0.16, 0.44 * alpha))
	draw_texture_rect(tex, Rect2(local_r.position + Vector2(fx_dir * 7.0, 5.0), local_r.size), false, Color(0.02, 0.02, 0.035, 0.62 * alpha))

	var mod := Color(1.0, 1.0, 1.0, alpha)
	if not is_active:
		mod = Color(0.46, 0.48, 0.55, alpha * 0.90)
	elif style == "think":
		mod = Color(0.84, 0.90, 1.0, alpha)
	draw_texture_rect(tex, local_r, false, mod)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# 3. 활성 발화자 하단 느와르 이름표 리본
	var nm := str(sl["name"])
	if is_active and nm != "":
		var nw := clampf(w * 0.78, 150.0, 240.0)
		var nh := 34.0
		var nx := (r.position.x + 12.0) if side < 0 else (r.end.x - nw - 12.0)
		var ny := sa.end.y - nh - 14.0
		var poly := PackedVector2Array([
			Vector2(nx, ny),
			Vector2(nx + nw, ny),
			Vector2(nx + nw - 10.0, ny + nh),
			Vector2(nx - 10.0, ny + nh),
		])
		draw_colored_polygon(poly, Color(0.03, 0.032, 0.05, 0.92 * alpha))
		var bar := PackedVector2Array([
			Vector2(nx, ny),
			Vector2(nx + 6.0, ny),
			Vector2(nx - 4.0, ny + nh),
			Vector2(nx - 10.0, ny + nh),
		])
		draw_colored_polygon(bar, Color(acc, 0.96 * alpha))
		var rim := poly.duplicate()
		rim.append(poly[0])
		draw_polyline(rim, Color(1.0, 1.0, 1.0, 0.26 * alpha), 1.5, true)
		draw_string(FONT_HEAD, Vector2(nx + 14.0, ny + 25.0), nm, HORIZONTAL_ALIGNMENT_LEFT, nw - 24.0, 21, Color(0.97, 0.97, 0.99, alpha))


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
	var slide := (1.0 - in_k) * sa.size.x * 0.65 * float(side) - (1.0 - out_k) * sa.size.x * 0.45 * float(side)
	var drift := (t / maxf(total, 0.01) - 0.5) * -28.0 * float(side)

	draw_set_transform(c + Vector2(slide, 0.0), deg_to_rad(-2.6 if side < 0 else 2.6), Vector2.ONE)
	var local := Rect2(-r.size * 0.5, r.size)
	# 외곽 굵은 먹선 띠 + 상하 악센트 핀스트라이프
	var outer := local.grow_individual(0.0, 10.0, 0.0, 10.0)
	draw_rect(outer, Color(0.02, 0.02, 0.03, 0.96 * alpha))
	draw_rect(Rect2(local.position.x, local.position.y - 4.0, local.size.x, 3.5), Color(acc, 0.98 * alpha))
	draw_rect(Rect2(local.position.x, local.end.y + 0.5, local.size.x, 3.5), Color(acc, 0.98 * alpha))

	# 파노라마 눈매 컷인 이미지(화면 전체 가로 폭을 꽉 채우되 세로 눈매 중심을 정확히 유지 — cover 크롭)
	var tw := float(tex.get_width())
	var th := float(tex.get_height())
	var dst_w := local.size.x + 48.0
	var dst_ar := dst_w / maxf(local.size.y, 1.0)
	var src_h := clampf(tw / maxf(dst_ar, 1.0), th * 0.52, th)
	var src_r := Rect2(0.0, (th - src_h) * 0.5, tw, src_h)
	var ir := Rect2(-dst_w * 0.5 + drift, local.position.y, dst_w, local.size.y)
	draw_rect(local, Color(0.04, 0.03, 0.05, 0.96 * alpha))
	draw_texture_rect_region(tex, ir, src_r, Color(1.0, 1.0, 1.0, alpha))
	# 상하 미세 비네트 바(만화 컷 인쇄 느낌)
	draw_rect(Rect2(local.position.x, local.position.y, local.size.x, 8.0), Color(0.0, 0.0, 0.0, 0.35 * alpha))
	draw_rect(Rect2(local.position.x, local.end.y - 8.0, local.size.x, 8.0), Color(0.0, 0.0, 0.0, 0.42 * alpha))

	# 좌/우 가장자리 느와르 비네트 그라데이션 바 + 기술명/대사 콜아웃(눈매를 가리지 않는 코너 · 부제도 검은 리본 안으로)
	var title := str(ci["title"])
	var sub := str(ci["sub"])
	if title != "":
		var align_left := side < 0
		var tag_h := 66.0 if sub != "" else 48.0
		var bx := (-sa.size.x * 0.46) if align_left else (sa.size.x * 0.46 - 376.0)
		var tag_r := Rect2(bx, local.end.y - tag_h - 6.0, 376.0, tag_h)
		draw_rect(tag_r, Color(0.02, 0.02, 0.035, 0.90 * alpha))
		draw_rect(Rect2(tag_r.position.x if align_left else tag_r.end.x - 5.0, tag_r.position.y, 5.0, tag_r.size.y), Color(acc, alpha))
		draw_rect(tag_r, Color(1.0, 1.0, 1.0, 0.16 * alpha), false, 1.0)
		var ha := HORIZONTAL_ALIGNMENT_LEFT if align_left else HORIZONTAL_ALIGNMENT_RIGHT
		var tx := tag_r.position.x + (14.0 if align_left else -14.0)
		if sub != "":
			draw_string(FONT_BODY, Vector2(tx, tag_r.position.y + 21.0), sub, ha, tag_r.size.x - 16.0, 15, Color(acc.lightened(0.42), 0.96 * alpha))
			draw_string(FONT_HEAD, Vector2(tx, tag_r.position.y + 53.0), title, ha, tag_r.size.x - 16.0, 30, Color(0.99, 0.98, 0.96, alpha))
		else:
			draw_string(FONT_HEAD, Vector2(tx, tag_r.position.y + 33.0), title, ha, tag_r.size.x - 16.0, 30, Color(0.99, 0.98, 0.96, alpha))

	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
