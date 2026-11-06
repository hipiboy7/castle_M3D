extends Control
## 싸움 중 메뉴 — 스테이지 고르기(사용자 2026-11-06 "메뉴 · 선택 같은 거 좌/우 측 상단에 만들어서 스테이지 넘어갈 수 있게").
## 위 줄 = 장 카드(누르면 그 장의 스테이지가 아래 줄에), 아래 줄 = 고른 장의 스테이지(방) 카드(누르면 거기서 시작),
## 맨 아래 = 계속 · 처음 화면. main.gd 가 chapters · stages · picked 를 채우고 hit() 로 누른 곳을 묻는다.
## 자리는 안전 영역 기준 · 매 프레임 다시 읽는다(접는 폰 — layout() 은 순수 함수, 시험 tests/unit/test_ui_logic.gd).

const SafeArea = preload("res://src/ui/safe_area.gd")

const CARD_H := 110.0
const W_MAX := 280.0
const GAP := 18.0
const BTN := Vector2(240, 72)
const COL_BG := Color(0, 0, 0, 0.6)
const COL_CARD := Color(0.06, 0.07, 0.1, 0.85)
const COL_PICK := Color(0.55, 0.12, 0.1, 0.9)
const COL_EDGE := Color(1, 1, 1, 0.35)
const COL_TEXT := Color(1, 1, 1, 0.95)
const COL_DIM := Color(1, 1, 1, 0.45)

var heading := ""
var chapters: Array = []         # [{"id", "title", "open"}]
var stages: Array = []           # [{"room", "title", "now"}] — 고른 장(picked)의 스테이지
var picked := ""                 # 위 줄에서 고른 장 id
var buttons := {"resume": "", "title": ""}   # 글 — main.gd 가 lines.json 에서
var _last_safe := Rect2()


static func _row(sa: Rect2, n: int, y: float) -> Array:
	var out: Array = []
	if n <= 0:
		return out
	var w := minf(W_MAX, (sa.size.x - 80.0 - GAP * (n - 1)) / n)
	var x0 := sa.get_center().x - (w * n + GAP * (n - 1)) * 0.5
	for i in n:
		out.append(Rect2(x0 + i * (w + GAP), y, w, CARD_H))
	return out


## 안전 영역 · 장 수 · 스테이지 수 → {"chapters": [자리], "stages": [자리], "resume": 자리, "title": 자리}
static func layout(sa: Rect2, n_ch: int, n_st: int) -> Dictionary:
	var c := sa.get_center()
	return {"chapters": _row(sa, n_ch, c.y - 160.0), "stages": _row(sa, n_st, c.y - 10.0),
		"resume": Rect2(c.x - BTN.x - GAP * 0.5, c.y + 140.0, BTN.x, BTN.y),
		"title": Rect2(c.x + GAP * 0.5, c.y + 140.0, BTN.x, BTN.y)}


## 누른 자리 → "ch:<장 id>" · "room:<방 번호>" · "resume" · "title" · ""
func hit(p: Vector2) -> String:
	if not visible:
		return ""
	var L := layout(SafeArea.rect(get_viewport()), chapters.size(), stages.size())
	for i in chapters.size():
		if L["chapters"][i].has_point(p):
			return "ch:" + str(chapters[i]["id"])
	for i in stages.size():
		if L["stages"][i].has_point(p):
			return "room:%d" % int(stages[i]["room"])
	for k in ["resume", "title"]:
		if L[k].has_point(p):
			return k
	return ""


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_dt: float) -> void:
	var sa := SafeArea.rect(get_viewport())
	if sa != _last_safe:
		_last_safe = sa
		queue_redraw()


func refresh() -> void:
	queue_redraw()


func _card(font: Font, r: Rect2, title: String, on: bool, open: bool, size := 22) -> void:
	draw_rect(r, COL_PICK if on else (COL_CARD if open else COL_CARD.darkened(0.4)))
	draw_rect(r, COL_EDGE if open else Color(COL_EDGE, 0.12), false, 2.0)
	draw_string(font, r.position + Vector2(6, r.size.y * 0.5 + size * 0.35), title, HORIZONTAL_ALIGNMENT_CENTER,
		r.size.x - 12, size, COL_TEXT if open else COL_DIM)


func _draw() -> void:
	var sa := SafeArea.rect(get_viewport())
	var font := get_theme_default_font()
	draw_rect(get_viewport_rect(), COL_BG)
	var L := layout(sa, chapters.size(), stages.size())
	draw_string(font, Vector2(sa.position.x, sa.get_center().y - 200.0), heading, HORIZONTAL_ALIGNMENT_CENTER, sa.size.x, 30, COL_TEXT)
	for i in chapters.size():
		var c: Dictionary = chapters[i]
		_card(font, L["chapters"][i], str(c["title"]), c["id"] == picked, bool(c["open"]))
	for i in stages.size():
		var st: Dictionary = stages[i]
		_card(font, L["stages"][i], str(st["title"]) + (" ◀" if st.get("now", false) else ""), false, true, 20)
	_card(font, L["resume"], str(buttons["resume"]), false, true, 26)
	_card(font, L["title"], str(buttons["title"]), false, true, 26)
