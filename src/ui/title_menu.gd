extends Control
## 처음 화면 장 고르기 — 느와르 그래픽 노블 카드 v2.
## layout() · hint_y_of() 순수 함수 계약은 tests/unit/test_ui_logic.gd 와 100% 동일하게 보존.

const SafeArea = preload("res://src/ui/safe_area.gd")
const FONT_HEAD = preload("res://assets/fonts/BlackHanSans-Regular.ttf")
const FONT_BODY = preload("res://assets/fonts/Pretendard-Bold.otf")

const CARD_H := 120.0
const CARD_W_MAX := 300.0
const GAP := 20.0
const CONT := Vector2(540, 96)
const COL_CARD := Color(0.05, 0.055, 0.082, 0.86)
const COL_CARD_LOCK := Color(0.04, 0.045, 0.065, 0.56)
const COL_CONT := Color(0.56, 0.10, 0.11, 0.92)
const COL_CRIMSON := Color(0.88, 0.16, 0.18, 0.96)
const COL_EDGE := Color(1, 1, 1, 0.28)
const COL_TEXT := Color(0.97, 0.97, 0.99, 0.96)
const COL_DIM := Color(0.74, 0.78, 0.84, 0.62)
const COL_MARK := Color(0.98, 0.80, 0.30, 0.98)

var cont := {}                  # {"id": "continue", "title": 이어하기, "sub": 다음 장 이름}
var items: Array = []           # [{"id": 장 id, "title", "sub", "state": open | soon | locked, "mark": 깬 횟수 글}]
var _last_safe := Rect2()

const ROW_MAX := 6
const PER_ROW := 5
const ROWS_H := 64.0
const ROWS_GAP := 10.0


static func layout(sa: Rect2, n: int) -> Dictionary:
	var c := sa.get_center()
	var cont_r := Rect2(c.x - CONT.x * 0.5, c.y - 20.0, CONT.x, CONT.y)
	var cards: Array = []
	if n <= 0:
		return {"cont": cont_r, "cards": cards}
	if n <= ROW_MAX:
		var w := minf(CARD_W_MAX, (sa.size.x - 80.0 - GAP * (n - 1)) / n)
		var total := w * n + GAP * (n - 1)
		var x0 := c.x - total * 0.5
		for i in n:
			cards.append(Rect2(x0 + i * (w + GAP), c.y + 100.0, w, CARD_H))
		return {"cont": cont_r, "cards": cards}
	var rows := ceili(float(n) / PER_ROW)
	var w2 := minf(CARD_W_MAX, (sa.size.x - 80.0 - GAP * (PER_ROW - 1)) / PER_ROW)
	var block := rows * ROWS_H + (rows - 1) * ROWS_GAP
	var y0 := sa.end.y - 16.0 - block
	cont_r.position.y = minf(cont_r.position.y, y0 - 14.0 - CONT.y)
	for i in n:
		var row := i / PER_ROW
		var in_row := mini(PER_ROW, n - row * PER_ROW)
		var total2 := w2 * in_row + GAP * (in_row - 1)
		var x1 := c.x - total2 * 0.5
		cards.append(Rect2(x1 + (i % PER_ROW) * (w2 + GAP), y0 + row * (ROWS_H + ROWS_GAP), w2, ROWS_H))
	return {"cont": cont_r, "cards": cards}


func hint_y() -> float:
	if not visible:
		return -1.0
	return hint_y_of(SafeArea.rect(get_viewport()), items.size())


static func hint_y_of(sa: Rect2, n: int) -> float:
	return float(layout(sa, n)["cont"].position.y) - 36.0


func hit(p: Vector2) -> String:
	if not visible:
		return ""
	var L := layout(SafeArea.rect(get_viewport()), items.size())
	if not cont.is_empty() and L["cont"].has_point(p):
		return "continue"
	for i in items.size():
		if L["cards"][i].has_point(p):
			return str(items[i]["id"])
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


func _draw() -> void:
	var L := layout(SafeArea.rect(get_viewport()), items.size())
	if not cont.is_empty():
		var r: Rect2 = L["cont"]
		draw_rect(Rect2(r.position + Vector2(4, 6), r.size), Color(0, 0, 0, 0.48))
		draw_rect(r, COL_CONT)
		draw_rect(Rect2(r.position, Vector2(6, r.size.y)), Color(1.0, 0.85, 0.35, 0.95))
		draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), Color(1, 1, 1, 0.25))
		draw_rect(r, Color(1, 1, 1, 0.45), false, 2.0)
		draw_string(FONT_HEAD, r.position + Vector2(0, 48), str(cont["title"]) + "  ▶", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 34, COL_TEXT)
		draw_string(FONT_BODY, r.position + Vector2(0, 80), str(cont["sub"]), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 18, Color(0.98, 0.92, 0.85, 0.88))

	for i in items.size():
		var it: Dictionary = items[i]
		var r: Rect2 = L["cards"][i]
		var open: bool = it["state"] == "open"
		var has_mark := str(it.get("mark", "")) != ""
		draw_rect(Rect2(r.position + Vector2(3, 4), r.size), Color(0, 0, 0, 0.40 if open else 0.20))
		draw_rect(r, COL_CARD if open else COL_CARD_LOCK)
		if open:
			draw_rect(Rect2(r.position, Vector2(4, r.size.y)), COL_MARK if has_mark else COL_CRIMSON)
			draw_rect(Rect2(r.position, Vector2(r.size.x, 1.5)), Color(1, 1, 1, 0.18))
		draw_rect(r, COL_EDGE if open else Color(COL_EDGE, 0.14), false, 1.5)
		var tc := COL_TEXT if open else COL_DIM
		if r.size.y < CARD_H:
			draw_string(FONT_BODY, r.position + Vector2(10, 29), str(it["title"]), HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 16, 18, tc)
			var small := ("★ " + str(it["mark"])) if (open and has_mark) else (str(it["mark"]) if has_mark else str(it["sub"]))
			draw_string(FONT_BODY, r.position + Vector2(10, 52), small, HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 16, 13,
				COL_MARK if open and has_mark else COL_DIM)
			continue
		draw_string(FONT_HEAD, r.position + Vector2(10, 42), str(it["title"]), HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 16, 22, tc)
		draw_string(FONT_BODY, r.position + Vector2(10, 72), str(it["sub"]), HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 16, 16, COL_DIM)
		if has_mark:
			draw_string(FONT_BODY, r.position + Vector2(10, 102), ("★ " + str(it["mark"])) if open else str(it["mark"]),
				HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 16, 15, COL_MARK if open else COL_DIM)
