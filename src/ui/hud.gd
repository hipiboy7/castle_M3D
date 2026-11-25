extends CanvasLayer
## 느와르 그래픽 노블 HUD v2 (2026-11-23 전면 개편):
##  - 보스 체력/체간(상단 중앙, 지연 데미지 트레일 + 크림슨 악센트) · 조작 인물 패널(좌상단, 10칸 게이지 + 스킬 필)
##  - 상단 느와르 리본 알림(전투/장면 중 msg/sub 를 중앙이 아닌 상단 띠로 배치해 말풍선과 겹침 완전 제거!)
##  - 제목/결과/일시정지/페이드 시에는 center_msg=true 로 중앙 대형 타이틀 유지(TitleMenu.hint_y_of 계약 보존)
##  - 미니 HP 바(다크 먹선 테두리 + 하이라이트) · 저채도 컴팩트 FPS 표시

const Common = preload("res://src/data/common.gd")
const SafeArea = preload("res://src/ui/safe_area.gd")
const Portraits = preload("res://src/view/portraits.gd")
const FONT_HEAD = preload("res://assets/fonts/BlackHanSans-Regular.ttf")
const FONT_BODY = preload("res://assets/fonts/Pretendard-Bold.otf")

const HERO_W_PLAIN := 286.0
const HERO_W_PORT := 228.0
const HERO_PORT_SHIFT := 80.0
const HERO_PORT_SIZE := Vector2(74, 94)
const BOSS_PORT_SIZE := Vector2(66, 66)

const COL_BG := Color(0.03, 0.035, 0.055, 0.84)
const COL_PANEL := Color(0.025, 0.03, 0.048, 0.62)
const COL_RIM := Color(1.0, 1.0, 1.0, 0.16)
const COL_HP_BOSS := Color(0.88, 0.16, 0.18)
const COL_HP_HERO := Color(0.22, 0.78, 0.96)
const COL_TRAIL := Color(0.98, 0.88, 0.78, 0.92)
const COL_POSTURE := Color(0.98, 0.76, 0.18)
const COL_POSTURE_HOT := Color(1.0, 0.36, 0.14)
const COL_TEXT := Color(0.96, 0.96, 0.98)
const COL_DIM := Color(0.74, 0.78, 0.85, 0.84)
const COL_FPS := Color(0.76, 0.80, 0.88, 0.56)
const COL_GAUGE := Color(0.32, 0.84, 1.0)
const COL_GAUGE_PART := Color(0.24, 0.44, 0.60)
const COL_CRIMSON := Color(0.84, 0.14, 0.16, 0.95)
const COL_BANNER := Color(0.035, 0.035, 0.05, 0.82)

var root: Control
var boss_hp: ColorRect
var boss_post: ColorRect
var boss_name: Label
var hero_name: Label
var _segs := 10                  # 게이지 칸 수 = common max_bars (김신 10칸)
var hero_hp: ColorRect
var hero_post: ColorRect
var fps: Label
var msg: Label
var sub: Label
var hint: Label
var hint_y_fn = null              # 안내 글 높이를 정하는 함수(-1 = 기본 맨 아래) — 처음 화면은 장 카드 위로(main.gd)
var center_msg := false           # true = 제목/결과/일시정지/페이드 중앙 표시 · false = 상단 느와르 리본(말풍선과 분리)
var _msg_t := 0.0
var _boss_w := 520.0
var _hero_w := 286.0
var _boss_bg: Array = []
var _boss_trail: ColorRect
var _hero_trail: ColorRect
var _boss_hp_t := 1.0
var _hero_hp_t := 1.0
var _last_boss_id := -1
var _last_hero_id := -1
var _gauge: Array = []
var _seg_w := 26.0
var skill_name: Label
var _skill_bg: ColorRect
var _hero_panel: ColorRect
var _hero_stripe: ColorRect
var _banner: ColorRect
var _banner_line: ColorRect
var dim: ColorRect
var partner_name: Label
var partner_hp: ColorRect
var _partner_bg: ColorRect
var minis: Control
var _portraits: PortraitBoxes
var _hero_panel_nodes: Array = []  # [노드, 안전 영역 왼쪽 위 자리] — 초상화 유무와 무관한 고정 자리
var _hero_bar_nodes: Array = []    # [노드, 기본 자리] — 초상화가 있으면 오른쪽으로 HERO_PORT_SHIFT 이동
var _hero_hp_bg: ColorRect
var _hero_post_bg: ColorRect
var _has_hero_port := false
var _combat_visible := true
var _headless := false
var _pulse_t := 0.0


func setup() -> void:
	_headless = DisplayServer.get_name() == "headless"
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	dim = ColorRect.new()                           # 일시정지 덮개 (set_dim)
	dim.color = Color(0.01, 0.012, 0.02, 0.52)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.visible = false
	root.add_child(dim)

	minis = MiniBars.new()
	minis.set_anchors_preset(Control.PRESET_FULL_RECT)
	minis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(minis)

	# 좌상단 조작 인물 느와르 백플레이트
	_hero_panel = ColorRect.new()
	_hero_panel.color = COL_PANEL
	_hero_panel.position = Vector2(14, 12)
	_hero_panel.size = Vector2(_hero_w + 26.0, 108.0)
	_hero_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_hero_panel)
	_hero_stripe = ColorRect.new()
	_hero_stripe.color = COL_HP_HERO
	_hero_stripe.position = Vector2(14, 12)
	_hero_stripe.size = Vector2(4.0, 108.0)
	_hero_stripe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_hero_stripe)

	# 상단 중앙 보스 바
	boss_name = _label("", 24, COL_TEXT, FONT_HEAD)
	boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var bb := _bar(Vector2.ZERO, Vector2(_boss_w, 16), true)
	boss_hp = bb[0]
	boss_hp.color = COL_HP_BOSS
	_boss_trail = bb[2]
	var bp := _bar(Vector2.ZERO, Vector2(_boss_w, 7), false)
	boss_post = bp[0]
	boss_post.color = COL_POSTURE
	_boss_bg = [bb[1], bp[1]]

	# 좌상단 조작 인물 바 · 게이지 · 기술
	hero_name = _label("", 20, COL_TEXT, FONT_HEAD)
	hero_name.position = Vector2(26, 15)
	_segs = int(Common.gauge()["max_bars"])
	var hb := _bar(Vector2(26, 44), Vector2(_hero_w, 14), true)
	hero_hp = hb[0]
	hero_hp.color = COL_HP_HERO
	_hero_hp_bg = hb[1]
	_hero_trail = hb[2]
	var hp2 := _bar(Vector2(26, 62), Vector2(_hero_w, 6), false)
	hero_post = hp2[0]
	hero_post.color = COL_POSTURE
	_hero_post_bg = hp2[1]
	var seg_w := (_hero_w - 3.0 * (_segs - 1)) / _segs
	for i in _segs:
		var g := _bar(Vector2(26 + i * (seg_w + 3.0), 73), Vector2(seg_w, 8), false)
		g[0].color = COL_GAUGE
		_gauge.append(g[0])
	_seg_w = seg_w

	_skill_bg = ColorRect.new()
	_skill_bg.color = Color(0.06, 0.10, 0.16, 0.72)
	_skill_bg.position = Vector2(26, 86)
	_skill_bg.size = Vector2(_hero_w, 26)
	_skill_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_skill_bg)
	skill_name = _label("", 16, COL_TEXT, FONT_BODY)
	skill_name.position = Vector2(34, 88)

	for n in [_hero_panel, _hero_stripe]:
		_hero_panel_nodes.append([n, n.position])
	for n in [hero_name, hb[1], hp2[1], _skill_bg, skill_name]:
		_hero_bar_nodes.append([n, n.position])

	partner_name = _label("", 14, COL_DIM, FONT_BODY)
	partner_name.position = Vector2(26, 124)
	var pb := _bar(Vector2(26, 144), Vector2(_hero_w * 0.62, 7), false)
	partner_hp = pb[0]
	partner_hp.color = COL_HP_HERO.darkened(0.22)
	_partner_bg = pb[1]
	for n in [partner_name, _partner_bg]:
		_hero_panel_nodes.append([n, n.position])

	# 2D 웹툰 HUD 초상화 프레임(조작 인물 좌측 · 보스 바 우측 — 반응형)
	_portraits = PortraitBoxes.new()
	_portraits.set_anchors_preset(Control.PRESET_FULL_RECT)
	_portraits.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(_portraits)

	# 상단 느와르 리본 배너(전투/장면 중 알림 — 말풍선 위)
	_banner = ColorRect.new()
	_banner.color = COL_BANNER
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner.visible = false
	root.add_child(_banner)
	_banner_line = ColorRect.new()
	_banner_line.color = COL_CRIMSON
	_banner_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_line.visible = false
	root.add_child(_banner_line)

	fps = _label("", 13, COL_FPS, FONT_BODY)
	fps.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	fps.size = Vector2(200, 22)

	msg = _label("", 52, COL_TEXT, FONT_HEAD)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.size = Vector2(1000, 72)
	sub = _label("", 22, COL_DIM, FONT_BODY)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size = Vector2(1000, 38)
	hint = _label("", 18, COL_DIM, FONT_BODY)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.size = Vector2(1000, 30)
	_layout()


## 화면 크기(접는 폰 포함)와 안전 영역에 맞춰 자리를 다시 잡는다
func _layout() -> void:
	var sa := SafeArea.rect(root.get_viewport())
	var cx := sa.position.x + sa.size.x * 0.5
	var top := sa.position.y
	var bw := clampf(sa.size.x * 0.42, 400.0, 560.0)
	if absf(bw - _boss_w) > 1.0:
		_boss_w = bw
		_boss_bg[0].size.x = _boss_w
		_boss_bg[1].size.x = _boss_w
	boss_name.position = Vector2(cx - _boss_w * 0.5, top + 10)
	boss_name.size = Vector2(_boss_w, 34)
	_boss_bg[0].position = Vector2(cx - _boss_w * 0.5, top + 44)
	_boss_bg[1].position = Vector2(cx - _boss_w * 0.5, top + 64)
	fps.position = Vector2(sa.end.x - 212, top + 10)

	var has_text := msg.text != "" or sub.text != ""
	if center_msg:
		_banner.visible = false
		_banner_line.visible = false
		msg.add_theme_font_size_override("font_size", 54)
		sub.add_theme_font_size_override("font_size", 24)
		msg.position = Vector2(cx - 500, sa.position.y + sa.size.y * 0.5 - 150)
		sub.position = Vector2(cx - 500, sa.position.y + sa.size.y * 0.5 - 70)
	else:
		# 전투 · 장면 연출 중 알림은 상단 느와르 리본으로 — 중앙 말풍선 · 액션 영역과 절대 겹치지 않는다
		var has_boss: bool = _boss_bg[0].visible
		var by := top + (84.0 if has_boss else 14.0)
		var bh := 62.0 if sub.text != "" else 42.0
		var b_width := minf(sa.size.x - 64.0, 620.0)
		_banner.visible = has_text
		_banner_line.visible = has_text
		_banner.position = Vector2(cx - b_width * 0.5, by)
		_banner.size = Vector2(b_width, bh)
		_banner_line.position = Vector2(cx - b_width * 0.5, by + bh - 3.0)
		_banner_line.size = Vector2(b_width, 3.0)
		msg.add_theme_font_size_override("font_size", 28)
		sub.add_theme_font_size_override("font_size", 17)
		msg.position = Vector2(cx - 500, by + (4.0 if sub.text != "" else 7.0))
		sub.position = Vector2(cx - 500, by + 35.0)

	hint.position = Vector2(cx - 500, sa.end.y - 44)
	if hint_y_fn != null:                              # 처음 화면 장 카드가 세 줄이면 맨 아래 글이 카드에 겹쳤다(2026-11-09)
		var y: float = hint_y_fn.call()
		if y >= 0.0:
			hint.position.y = y
	var want_hw := HERO_W_PORT if _has_hero_port else HERO_W_PLAIN
	if absf(_hero_w - want_hw) > 0.5:
		_hero_w = want_hw
		_hero_hp_bg.size.x = _hero_w
		_hero_post_bg.size.x = _hero_w
		_skill_bg.size.x = _hero_w
		_seg_w = (_hero_w - 3.0 * (_segs - 1)) / _segs
		for g in _gauge:
			(g.get_parent() as ColorRect).size.x = _seg_w
	_hero_panel.size.x = (_hero_w + HERO_PORT_SHIFT + 26.0) if _has_hero_port else (_hero_w + 26.0)
	var sx := HERO_PORT_SHIFT if _has_hero_port else 0.0
	for hn in _hero_panel_nodes:
		hn[0].position = sa.position + hn[1]
	for hn in _hero_bar_nodes:
		hn[0].position = sa.position + hn[1] + Vector2(sx, 0.0)
	for i in _gauge.size():
		(_gauge[i].get_parent() as ColorRect).position = sa.position + Vector2(26.0 + sx + i * (_seg_w + 3.0), 73.0)
	if _portraits != null:
		_portraits.hero_rect = Rect2(sa.position + Vector2(22.0, 19.0), HERO_PORT_SIZE)
		_portraits.boss_rect = Rect2(Vector2(cx + _boss_w * 0.5 + 10.0, top + 8.0), BOSS_PORT_SIZE)
		_portraits.queue_redraw()


func _label(text: String, size: int, col: Color, fnt: Font = FONT_BODY) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", fnt)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0.02, 0.02, 0.03, 0.92))
	l.add_theme_constant_override("outline_size", 5)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(l)
	return l


func _bar(pos: Vector2, size: Vector2, with_trail := false) -> Array:
	var bg := ColorRect.new()
	bg.color = COL_BG
	bg.position = pos
	bg.size = size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)
	# 상단 미세 테두리 하이라이트
	var rim := ColorRect.new()
	rim.color = COL_RIM
	rim.position = Vector2.ZERO
	rim.size = Vector2(size.x, 1.0)
	rim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(rim)
	var trail: ColorRect = null
	if with_trail:
		trail = ColorRect.new()
		trail.color = COL_TRAIL
		trail.position = Vector2(2, 2)
		trail.size = size - Vector2(4, 4)
		trail.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bg.add_child(trail)
	var fill := ColorRect.new()
	fill.position = Vector2(2, 2)
	fill.size = size - Vector2(4, 4)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(fill)
	return [fill, bg, trail]


func set_combat_visible(on: bool) -> void:
	_combat_visible = on
	for hn in _hero_panel_nodes:
		hn[0].visible = on
	for hn in _hero_bar_nodes:
		hn[0].visible = on
	for g in _gauge:
		(g.get_parent() as Control).visible = on
	if not on:
		for n in [boss_name, _boss_bg[0], _boss_bg[1], partner_name, _partner_bg]:
			n.visible = false
	if _portraits != null:
		_portraits.visible = on


func update_bars(hero, boss, phase: int, dt: float, partner = null) -> void:
	_pulse_t += dt
	var has_boss: bool = _combat_visible and boss != null
	for n in [boss_name, _boss_bg[0], _boss_bg[1]]:
		n.visible = has_boss
	if has_boss:
		var br := clampf(float(boss.hp) / maxf(1.0, float(boss.hp_max)), 0.0, 1.0)
		var bid: int = boss.get_instance_id()
		if bid != _last_boss_id or br > _boss_hp_t:
			_last_boss_id = bid
			_boss_hp_t = br
		else:
			_boss_hp_t = move_toward(_boss_hp_t, br, dt * 0.45)
		_fill(_boss_trail, _boss_hp_t, _boss_w)
		_fill(boss_hp, br, _boss_w)
		var bp_r := clampf(float(boss.posture) / maxf(1.0, float(boss.posture_max)), 0.0, 1.0)
		_fill(boss_post, bp_r, _boss_w)
		boss_post.color = COL_POSTURE.lerp(COL_POSTURE_HOT, 0.5 + 0.5 * sin(_pulse_t * 14.0)) if bp_r > 0.72 else COL_POSTURE
	partner_name.visible = _combat_visible and partner != null
	_partner_bg.visible = _combat_visible and partner != null
	if partner != null:
		partner_name.text = "%s%s" % [partner.name, "" if partner.alive() else " — 쓰러짐"]
		_fill(partner_hp, float(partner.hp) / maxf(1.0, float(partner.hp_max)), _hero_w * 0.62)

	var hr := clampf(float(hero.hp) / maxf(1.0, float(hero.hp_max)), 0.0, 1.0)
	var hid: int = hero.get_instance_id()
	if hid != _last_hero_id or hr > _hero_hp_t:
		_last_hero_id = hid
		_hero_hp_t = hr
	else:
		_hero_hp_t = move_toward(_hero_hp_t, hr, dt * 0.48)
	_fill(_hero_trail, _hero_hp_t, _hero_w)
	_fill(hero_hp, hr, _hero_w)
	var hp_r := clampf(float(hero.posture) / maxf(1.0, float(hero.posture_max)), 0.0, 1.0)
	_fill(hero_post, hp_r, _hero_w)
	hero_post.color = COL_POSTURE.lerp(COL_POSTURE_HOT, 0.5 + 0.5 * sin(_pulse_t * 14.0)) if hp_r > 0.72 else COL_POSTURE

	var bars: float = hero.gauge / Common.bar_points()
	for i in _gauge.size():
		var k := clampf(bars - i, 0.0, 1.0)
		_gauge[i].size.x = maxf(0.0, (_seg_w - 4.0) * k)
		_gauge[i].color = COL_GAUGE if k >= 1.0 else COL_GAUGE_PART
	var sk: Dictionary = hero.current_skill()
	skill_name.text = ""
	_skill_bg.visible = _combat_visible and not sk.is_empty()
	if not sk.is_empty():
		var ok: bool = hero.can_pay(sk)
		var cost := float(sk["cost"])
		var cost_txt := "%d칸+ 전부" % Common.all_min_bars() if cost < 0.0 else "%d칸" % roundi(cost)
		skill_name.text = "%s  ·  %s" % [sk["name"], cost_txt]
		skill_name.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0) if ok else COL_DIM)
		_skill_bg.color = Color(0.10, 0.24, 0.34, 0.82) if ok else Color(0.04, 0.05, 0.08, 0.65)
	if has_boss:
		boss_name.text = str(boss.name) + ("   [ 2차 · 전력 ]" if phase == 2 else "")
	hero_name.text = str(hero.name)
	# 2D 웹툰 HUD 초상화 상태 갱신(헤드리스에서는 텍스처 그리기 생략)
	var hk := Portraits.key_of(str(hero.char_id)) if not _headless else ""
	var bk := Portraits.key_of(str(boss.char_id)) if (has_boss and not _headless) else ""
	_has_hero_port = hk != "" and Portraits.has_hud(hk)
	if _portraits != null:
		_portraits.hero_key = hk if _has_hero_port else ""
		_portraits.hero_hurt = int(hero.flash) > 0
		_portraits.hero_dead = not hero.alive()
		_portraits.boss_key = bk if (bk != "" and Portraits.has_hud(bk)) else ""
		_portraits.boss_hurt = has_boss and int(boss.flash) > 0
		_portraits.boss_dead = has_boss and not boss.alive()
		_portraits.boss_phase2 = has_boss and phase == 2
	fps.text = "%d FPS · %.1fms" % [Engine.get_frames_per_second(), Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0]

	for q in _queue:
		q[0] -= dt
	if not _queue.is_empty() and _queue[0][0] <= 0.0 and _msg_t <= 0.0:
		var q: Array = _queue.pop_front()
		message(q[1], q[2], q[3])
	if _msg_t > 0.0:
		_msg_t -= dt
		if _msg_t <= 0.0:
			msg.text = ""
			sub.text = ""
	_layout()


func _fill(r: ColorRect, k: float, w: float) -> void:
	if r == null:
		return
	r.size.x = maxf(0.0, (w - 4.0) * clampf(k, 0.0, 1.0))


## delay > 0 이면 줄을 세워 그만큼 뒤에, 앞 알림이 끝난 다음 차례로 띄운다
var _queue: Array = []                    # [남은 기다림, 글, 작은 글, 보일 초]


func message(text: String, small := "", secs := 2.0, delay := 0.0) -> void:
	if delay > 0.0:
		_queue.append([delay, text, small, secs])
		return
	msg.text = text
	sub.text = small
	_msg_t = secs
	_layout()


## 판을 새로 만들 때(장 · 방 바꿈): 앞 판의 알림 · 기다리는 알림을 지운다
func clear_messages() -> void:
	_queue.clear()
	msg.text = ""
	sub.text = ""
	_msg_t = 0.0
	_layout()


## 적 머리 위 작은 체력 막대: [[화면 자리, 체력 비율, 색], ...]
func set_minibars(items: Array) -> void:
	minis.items = items
	minis.queue_redraw()


class MiniBars extends Control:
	var items: Array = []

	func _draw() -> void:
		for it in items:
			var p: Vector2 = it[0]
			var w := 56.0
			var h := 6.0
			var k := clampf(float(it[1]), 0.0, 1.0)
			var col: Color = it[2]
			draw_rect(Rect2(p.x - w * 0.5 - 2.0, p.y - 2.0, w + 4.0, h + 4.0), Color(0.02, 0.02, 0.03, 0.82))
			draw_rect(Rect2(p.x - w * 0.5 - 2.0, p.y - 2.0, w + 4.0, h + 4.0), Color(1.0, 1.0, 1.0, 0.22), false, 1.0)
			draw_rect(Rect2(p.x - w * 0.5, p.y, w * k, h), col)
			if k > 0.02:
				draw_rect(Rect2(p.x - w * 0.5, p.y, w * k, 1.5), col.lightened(0.35))


func set_dim(on: bool) -> void:
	dim.visible = on


func set_hint(text: String) -> void:
	hint.text = text


## HUD 초상화 자리 계산(순수 함수 — test_portraits.gd 에서 Z Fold 4 전 비율 겹침 검사)
static func portrait_boxes(sa: Rect2) -> Dictionary:
	var cx := sa.position.x + sa.size.x * 0.5
	var bw := clampf(sa.size.x * 0.42, 400.0, 560.0)
	var hero_panel := Rect2(sa.position + Vector2(14.0, 12.0), Vector2(HERO_W_PORT + HERO_PORT_SHIFT + 26.0, 108.0))
	var boss_bar := Rect2(cx - bw * 0.5, sa.position.y + 10.0, bw, 62.0)
	var boss_port := Rect2(cx + bw * 0.5 + 10.0, sa.position.y + 8.0, BOSS_PORT_SIZE.x, BOSS_PORT_SIZE.y)
	return {"hero_panel": hero_panel, "boss_bar": boss_bar, "boss_port": boss_port}


class PortraitBoxes extends Control:
	var hero_key := ""
	var hero_rect := Rect2()
	var hero_hurt := false
	var hero_dead := false
	var boss_key := ""
	var boss_rect := Rect2()
	var boss_hurt := false
	var boss_dead := false
	var boss_phase2 := false

	func _draw() -> void:
		if hero_key != "":
			_draw_box(hero_rect, hero_key, -1, hero_hurt, hero_dead, false)
		if boss_key != "":
			_draw_box(boss_rect, boss_key, 1, boss_hurt, boss_dead, boss_phase2)

	func _draw_box(r: Rect2, key: String, side: int, hurt: bool, dead: bool, phase2: bool) -> void:
		var tex := Portraits.hud_tex(key)
		if tex == null:
			return
		var acc := Portraits.accent_color(key)
		var bg_col := Color(0.24, 0.04, 0.05, 0.94) if hurt else (Color(0.16, 0.06, 0.04, 0.92) if phase2 else Color(0.04, 0.045, 0.075, 0.92))
		draw_rect(Rect2(r.position + Vector2(2, 3), r.size), Color(0, 0, 0, 0.50))
		draw_rect(r, bg_col)
		# 대각선 느와르 백 스트라이프
		var tri := PackedVector2Array([
			r.position + Vector2(0, r.size.y * 0.65),
			r.position + Vector2(r.size.x, r.size.y * 0.30),
			r.end,
			Vector2(r.position.x, r.end.y),
		])
		draw_colored_polygon(tri, Color(acc, 0.24 if not phase2 else 0.42))
		# 얼굴 초상화(화면 중앙을 보게 안전하게 좌우 반전 — draw_set_transform 사용)
		var inner := r.grow(-2.0)
		var flip := Portraits.should_flip(key, side)
		var mod := Color(0.42, 0.42, 0.46, 0.85) if dead else (Color(1.25, 0.72, 0.70, 1.0) if hurt else Color.WHITE)
		# 종횡비(1:1) 유지해 세로 직사각 박스 안에서 찌그러지지 않게 중앙 크롭(cover)
		var tw := float(tex.get_width())
		var th := float(tex.get_height())
		var box_ar := inner.size.x / maxf(inner.size.y, 1.0)
		var src_w := minf(tw, th * box_ar)
		var src_h := minf(th, tw / maxf(box_ar, 0.01))
		var src_r := Rect2((tw - src_w) * 0.5, (th - src_h) * 0.5, src_w, src_h)
		if flip:
			var ic := inner.get_center()
			draw_set_transform(ic, 0.0, Vector2(-1.0, 1.0))
			draw_texture_rect_region(tex, Rect2(-inner.size * 0.5, inner.size), src_r, mod)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			draw_texture_rect_region(tex, inner, src_r, mod)
		# 외곽 먹선 + 악센트 테두리(2차 페이즈는 금빛 강조)
		var edge := Color(1.0, 0.80, 0.24, 0.98) if phase2 else (Color(1.0, 0.28, 0.24, 0.98) if hurt else Color(acc, 0.88))
		draw_rect(r, edge, false, 2.5 if phase2 else 2.0)
		draw_rect(Rect2(r.position, Vector2(r.size.x, 3.0)), edge)
