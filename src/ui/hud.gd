extends CanvasLayer
## 화면 표시 — 백도찬 체력 · 체간(위 가운데), 김신 체력 · 체간(왼쪽 위), FPS · 프레임 시간(오른쪽 위, 보류 결정 #7 · #9 판단용),
## 김신 기술 게이지(칸) · 고른 기술(이름 · 비용, 게이지가 모자라면 흐리게),
## 가운데 알림(시작 · 2차 · 승패), 아래 도움말. 색은 이 파일 머리 상수 한 곳.

const Common = preload("res://src/data/common.gd")
const SafeArea = preload("res://src/ui/safe_area.gd")

const COL_BG := Color(0.0, 0.0, 0.0, 0.55)
const COL_HP_BOSS := Color(0.86, 0.22, 0.2)
const COL_HP_HERO := Color(0.3, 0.75, 0.95)
const COL_POSTURE := Color(0.98, 0.78, 0.25)
const COL_TEXT := Color(0.95, 0.95, 0.97)
const COL_DIM := Color(0.75, 0.78, 0.85, 0.85)
const COL_GAUGE := Color(0.45, 0.8, 1.0)
const COL_GAUGE_PART := Color(0.3, 0.5, 0.65)

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
var _msg_t := 0.0
var _boss_w := 560.0
var _hero_w := 300.0
var _boss_bg: Array = []
var _gauge: Array = []
var _seg_w := 28.0
var skill_name: Label
var dim: ColorRect
var _hero_nodes: Array = []      # [노드, 안전 영역 왼쪽 위에서의 자리] — 김신 쪽 묶음(이름 · 막대 · 게이지 · 기술)


func setup() -> void:
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	dim = ColorRect.new()                           # 일시정지 덮개 (set_dim)
	dim.color = Color(0, 0, 0, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.visible = false
	root.add_child(dim)
	boss_name = _label("", 26, COL_TEXT)            # 이름은 update_bars 가 characters.json name 으로
	var bb := _bar(Vector2.ZERO, Vector2(_boss_w, 16))
	boss_hp = bb[0]
	boss_hp.color = COL_HP_BOSS
	var bp := _bar(Vector2.ZERO, Vector2(_boss_w, 7))
	boss_post = bp[0]
	boss_post.color = COL_POSTURE
	_boss_bg = [bb[1], bp[1]]
	hero_name = _label("", 22, COL_TEXT)            # 이름은 update_bars 가 characters.json name 으로
	hero_name.position = Vector2(24, 16)
	_segs = int(Common.gauge()["max_bars"])
	var hb := _bar(Vector2(24, 46), Vector2(_hero_w, 14))
	hero_hp = hb[0]
	hero_hp.color = COL_HP_HERO
	var hp2 := _bar(Vector2(24, 64), Vector2(_hero_w, 6))
	hero_post = hp2[0]
	hero_post.color = COL_POSTURE
	# 기술 게이지: 칸마다 하나 (김신 10칸), 아래에 고른 기술 · 비용
	var seg_w := (_hero_w - 2.0 * (_segs - 1)) / _segs
	for i in _segs:
		var g := _bar(Vector2(24 + i * (seg_w + 2.0), 76), Vector2(seg_w, 9))
		g[0].color = COL_GAUGE
		_gauge.append(g[0])
	_seg_w = seg_w
	skill_name = _label("", 20, COL_TEXT)
	skill_name.position = Vector2(24, 88)
	for n in [hero_name, hb[1], hp2[1], skill_name]:
		_hero_nodes.append([n, n.position])
	for g in _gauge:
		_hero_nodes.append([g.get_parent(), g.get_parent().position])
	fps = _label("", 18, COL_DIM)
	msg = _label("", 54, COL_TEXT)
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg.size = Vector2(1000, 70)
	sub = _label("", 26, COL_DIM)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.size = Vector2(1000, 40)
	hint = _label("", 20, COL_DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.size = Vector2(1000, 30)
	_layout()


## 화면 크기(폰은 가로로 더 넓다 · 접는 폰은 실행 중 바뀐다)와 안전 영역(노치 · 제스처 바)에 맞춰 자리를 다시 잡는다
func _layout() -> void:
	var sa := SafeArea.rect(root.get_viewport())
	var cx := sa.position.x + sa.size.x * 0.5
	var top := sa.position.y
	boss_name.position = Vector2(cx - _boss_w * 0.5, top + 14)
	_boss_bg[0].position = Vector2(cx - _boss_w * 0.5, top + 48)
	_boss_bg[1].position = Vector2(cx - _boss_w * 0.5, top + 68)
	fps.position = Vector2(sa.end.x - 240, top + 16)
	msg.position = Vector2(cx - 500, sa.position.y + sa.size.y * 0.5 - 150)
	sub.position = Vector2(cx - 500, sa.position.y + sa.size.y * 0.5 - 70)
	hint.position = Vector2(cx - 500, sa.end.y - 46)
	for hn in _hero_nodes:
		hn[0].position = sa.position + hn[1]


func _label(text: String, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(l)
	return l


func _bar(pos: Vector2, size: Vector2) -> Array:
	var bg := ColorRect.new()
	bg.color = COL_BG
	bg.position = pos
	bg.size = size
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)
	var fill := ColorRect.new()
	fill.position = Vector2(2, 2)
	fill.size = size - Vector2(4, 4)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.add_child(fill)
	return [fill, bg]


func update_bars(hero, boss, phase: int, dt: float) -> void:
	_layout()
	_fill(boss_hp, boss.hp / boss.hp_max, _boss_w)
	_fill(boss_post, boss.posture / boss.posture_max, _boss_w)
	_fill(hero_hp, hero.hp / hero.hp_max, _hero_w)
	_fill(hero_post, hero.posture / hero.posture_max, _hero_w)
	var bars: float = hero.gauge / Common.bar_points()
	for i in _gauge.size():
		var k := clampf(bars - i, 0.0, 1.0)
		_gauge[i].size.x = maxf(0.0, (_seg_w - 4.0) * k)
		_gauge[i].color = COL_GAUGE if k >= 1.0 else COL_GAUGE_PART
	var sk: Dictionary = hero.current_skill()
	if not sk.is_empty():
		var ok: bool = hero.can_pay(sk)
		var cost := float(sk["cost"])
		var cost_txt := "%d칸+ 전부" % Common.all_min_bars() if cost < 0.0 else "%d칸" % roundi(cost)
		skill_name.text = "기술: %s (%s)" % [sk["name"], cost_txt]
		skill_name.add_theme_color_override("font_color", COL_TEXT if ok else COL_DIM)
	boss_name.text = str(boss.name) + ("   2차 · 전력" if phase == 2 else "")
	hero_name.text = str(hero.name)
	fps.text = "FPS %d · %.1fms" % [Engine.get_frames_per_second(), Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0]
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


func _fill(r: ColorRect, k: float, w: float) -> void:
	r.size.x = maxf(0.0, (w - 4.0) * clampf(k, 0.0, 1.0))


## delay > 0 이면 줄을 세워 그만큼 뒤에, 앞 알림이 끝난 다음 차례로 띄운다 — 같은 순간 머리 위 글자(엇박 % · 기절)와
## 겹치지 않게(rc.2 폰 리뷰 5 "거슬려"). delay 0 은 전처럼 바로(시작 · 2차 · 승패)
var _queue: Array = []                    # [남은 기다림, 글, 작은 글, 보일 초]


func message(text: String, small := "", secs := 2.0, delay := 0.0) -> void:
	if delay > 0.0:
		_queue.append([delay, text, small, secs])
		return
	msg.text = text
	sub.text = small
	_msg_t = secs


func set_dim(on: bool) -> void:
	dim.visible = on


func set_hint(text: String) -> void:
	hint.text = text
