extends Control
## 싸움 중 메뉴 — 스테이지 고르기(느와르 그래픽 노블 v2).
## layout() 순수 함수 계약은 tests/unit/test_ui_logic.gd 와 100% 동일하게 보존.

const SafeArea = preload("res://src/ui/safe_area.gd")
const FONT_HEAD = preload("res://assets/fonts/BlackHanSans-Regular.ttf")
const FONT_BODY = preload("res://assets/fonts/Pretendard-Bold.otf")

const CARD_H := 110.0
const W_MAX := 280.0
const GAP := 18.0
const BTN := Vector2(240, 72)
const COL_BG := Color(0.015, 0.018, 0.03, 0.78)
const COL_CARD := Color(0.055, 0.06, 0.088, 0.90)
const COL_PICK := Color(0.58, 0.11, 0.12, 0.94)
const COL_ACCENT := Color(0.88, 0.16, 0.18, 0.95)
const COL_GOLD := Color(0.98, 0.80, 0.30, 0.95)
const COL_EDGE := Color(1, 1, 1, 0.30)
const COL_TEXT := Color(0.97, 0.97, 0.99, 0.96)
const COL_DIM := Color(0.70, 0.74, 0.80, 0.45)

var heading := ""
var chapters: Array = []         # [{"id", "title", "open", "cleared"}]
var stages: Array = []           # [{"room", "title", "now"}] — 고른 장(picked)의 스테이지
var picked := ""                 # 위 줄에서 고른 장 id
var buttons := {"resume": "", "title": "", "difficulty": "", "zoom": ""}
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


const ROW_MAX := 8
const PER_ROW := 8
const SMALL_H := 46.0
const SMALL_GAP := 8.0


static func _rows(sa: Rect2, n: int, y: float) -> Array:
	var out: Array = []
	var w := minf(W_MAX, (sa.size.x - 80.0 - GAP * (PER_ROW - 1)) / PER_ROW)
	for i in n:
		var row := i / PER_ROW
		var in_row := mini(PER_ROW, n - row * PER_ROW)
		var x0 := sa.get_center().x - (w * in_row + GAP * (in_row - 1)) * 0.5
		out.append(Rect2(x0 + (i % PER_ROW) * (w + GAP), y + row * (SMALL_H + SMALL_GAP), w, SMALL_H))
	return out


static func layout(sa: Rect2, n_ch: int, n_st: int) -> Dictionary:
	var c := sa.get_center()
	var chs: Array = _row(sa, n_ch, c.y - 160.0) if n_ch <= ROW_MAX else _rows(sa, n_ch, c.y - 172.0)
	var bw := minf(BTN.x, (sa.size.x - 80.0 - GAP * 3.0) / 4.0)
	var x0 := c.x - (bw * 4.0 + GAP * 3.0) * 0.5
	var by := c.y + 140.0
	return {"chapters": chs, "stages": _row(sa, n_st, c.y - 10.0),
		"resume": Rect2(x0, by, bw, BTN.y),
		"title": Rect2(x0 + (bw + GAP), by, bw, BTN.y),
		"difficulty": Rect2(x0 + (bw + GAP) * 2.0, by, bw, BTN.y),
		"zoom": Rect2(x0 + (bw + GAP) * 3.0, by, bw, BTN.y)}


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
	for k in ["resume", "title", "difficulty", "zoom"]:
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


func _card(r: Rect2, title: String, on: bool, open: bool, size := 20, highlight := false) -> void:
	draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.42))
	draw_rect(r, COL_PICK if on else (COL_CARD if open else COL_CARD.darkened(0.45)))
	if on:
		draw_rect(Rect2(r.position, Vector2(4, r.size.y)), COL_GOLD)
	elif highlight:
		draw_rect(Rect2(r.position, Vector2(4, r.size.y)), COL_ACCENT)
	elif open:
		draw_rect(Rect2(r.position, Vector2(r.size.x, 1.5)), Color(1, 1, 1, 0.16))
	draw_rect(r, Color(1, 1, 1, 0.45) if (on or highlight) else (COL_EDGE if open else Color(COL_EDGE, 0.12)), false, 1.8)
	draw_string(FONT_BODY, r.position + Vector2(8, r.size.y * 0.5 + size * 0.34), title, HORIZONTAL_ALIGNMENT_CENTER,
		r.size.x - 14, size, COL_TEXT if open else COL_DIM)


func _draw() -> void:
	var sa := SafeArea.rect(get_viewport())
	draw_rect(get_viewport_rect(), COL_BG)
	var L := layout(sa, chapters.size(), stages.size())
	var hy := sa.get_center().y - 202.0
	draw_string(FONT_HEAD, Vector2(sa.position.x, hy), heading, HORIZONTAL_ALIGNMENT_CENTER, sa.size.x, 30, COL_TEXT)
	draw_rect(Rect2(sa.get_center().x - 90.0, hy + 10.0, 180.0, 3.0), COL_ACCENT)
	for i in chapters.size():
		var c: Dictionary = chapters[i]
		var r: Rect2 = L["chapters"][i]
		var lbl := str(c["title"]) + (" ★" if bool(c.get("cleared", false)) else "")
		_card(r, lbl, c["id"] == picked, bool(c["open"]), 20 if r.size.y >= CARD_H else 16, bool(c.get("cleared", false)))
	for i in stages.size():
		var st: Dictionary = stages[i]
		var is_now: bool = bool(st.get("now", false))
		_card(L["stages"][i], str(st["title"]) + ("  ◀" if is_now else ""), is_now, true, 18, is_now)
	_card(L["resume"], str(buttons["resume"]), true, true, 22)
	_card(L["title"], str(buttons["title"]), false, true, 22, true)
	_card(L["difficulty"], str(buttons["difficulty"]), false, true, 20)
	_card(L["zoom"], str(buttons["zoom"]), false, true, 20)
