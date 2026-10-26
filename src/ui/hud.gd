extends CanvasLayer
## 화면 표시 — 백도찬 체력 · 체간(위 가운데), 김신 체력 · 체간(왼쪽 위), FPS · 프레임 시간(오른쪽 위, 보류 결정 #7 · #9 판단용),
## 가운데 알림(시작 · 2차 · 승패), 아래 도움말. 색은 이 파일 머리 상수 한 곳.

const COL_BG := Color(0.0, 0.0, 0.0, 0.55)
const COL_HP_BOSS := Color(0.86, 0.22, 0.2)
const COL_HP_HERO := Color(0.3, 0.75, 0.95)
const COL_POSTURE := Color(0.98, 0.78, 0.25)
const COL_TEXT := Color(0.95, 0.95, 0.97)
const COL_DIM := Color(0.75, 0.78, 0.85, 0.85)

var root: Control
var boss_hp: ColorRect
var boss_post: ColorRect
var boss_name: Label
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


func setup() -> void:
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	boss_name = _label("백도찬", 26, COL_TEXT)
	var bb := _bar(Vector2.ZERO, Vector2(_boss_w, 16))
	boss_hp = bb[0]
	boss_hp.color = COL_HP_BOSS
	var bp := _bar(Vector2.ZERO, Vector2(_boss_w, 7))
	boss_post = bp[0]
	boss_post.color = COL_POSTURE
	_boss_bg = [bb[1], bp[1]]
	var hn := _label("김신", 22, COL_TEXT)
	hn.position = Vector2(24, 16)
	var hb := _bar(Vector2(24, 46), Vector2(_hero_w, 14))
	hero_hp = hb[0]
	hero_hp.color = COL_HP_HERO
	var hp2 := _bar(Vector2(24, 64), Vector2(_hero_w, 6))
	hero_post = hp2[0]
	hero_post.color = COL_POSTURE
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


## 화면 크기(폰은 가로로 더 넓다)에 맞춰 자리를 다시 잡는다
func _layout() -> void:
	var v := root.get_viewport_rect().size
	var cx := v.x * 0.5
	boss_name.position = Vector2(cx - _boss_w * 0.5, 14)
	_boss_bg[0].position = Vector2(cx - _boss_w * 0.5, 48)
	_boss_bg[1].position = Vector2(cx - _boss_w * 0.5, 68)
	fps.position = Vector2(v.x - 240, 16)
	msg.position = Vector2(cx - 500, v.y * 0.5 - 150)
	sub.position = Vector2(cx - 500, v.y * 0.5 - 70)
	hint.position = Vector2(cx - 500, v.y - 46)


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
	boss_name.text = "백도찬" + ("   2차 · 전력" if phase == 2 else "")
	fps.text = "FPS %d · %.1fms" % [Engine.get_frames_per_second(), Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0]
	if _msg_t > 0.0:
		_msg_t -= dt
		if _msg_t <= 0.0:
			msg.text = ""
			sub.text = ""


func _fill(r: ColorRect, k: float, w: float) -> void:
	r.size.x = maxf(0.0, (w - 4.0) * clampf(k, 0.0, 1.0))


func message(text: String, small := "", secs := 2.0) -> void:
	msg.text = text
	sub.text = small
	_msg_t = secs


func set_hint(text: String) -> void:
	hint.text = text
