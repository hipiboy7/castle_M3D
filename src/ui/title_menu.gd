extends Control
## 처음 화면 장 고르기 — 위에 큰 '이어하기'(세이브의 다음 장), 아래 줄에 장 카드(할 수 있는 장 · 준비 중 · 잠김 · 깬 횟수).
## main.gd 가 items · cont 를 채우고, 누른 자리를 hit() 로 묻는다. 자리는 안전 영역 기준 · 매 프레임 다시 읽는다(접는 폰 —
## layout() 은 순수 함수라 시험 tests/unit/test_ui_logic.gd). 글은 main.gd 가 lines.json 에서 넣는다.

const SafeArea = preload("res://src/ui/safe_area.gd")

const CARD_H := 120.0
const CARD_W_MAX := 300.0
const GAP := 20.0
const CONT := Vector2(540, 96)
const COL_CARD := Color(0.06, 0.07, 0.1, 0.78)
const COL_CONT := Color(0.55, 0.12, 0.1, 0.85)
const COL_EDGE := Color(1, 1, 1, 0.35)
const COL_TEXT := Color(1, 1, 1, 0.95)
const COL_DIM := Color(1, 1, 1, 0.45)
const COL_MARK := Color(0.95, 0.8, 0.35, 0.95)

var cont := {}                  # {"id": "continue", "title": 이어하기, "sub": 다음 장 이름}
var items: Array = []           # [{"id": 장 id, "title", "sub", "state": open | soon | locked, "mark": 깬 횟수 글}]
var _last_safe := Rect2()


## 안전 영역 · 카드 수 → {"cont": 이어하기 자리, "cards": [카드 자리]} — 화면 가운데 아래쪽.
## 카드가 ROW_MAX 보다 많으면(3 ~ 13장 — 2026-11-08 장 15개) 여러 줄로 낮게(ROWS_H): 카드 덩어리는 안전 영역 아래 끝에 붙이고
## 이어하기는 그 위에
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


## 누른 자리 → "continue" · 장 id · ""(빈 곳)
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
	var font := get_theme_default_font()
	var L := layout(SafeArea.rect(get_viewport()), items.size())
	if not cont.is_empty():
		var r: Rect2 = L["cont"]
		draw_rect(r, COL_CONT)
		draw_rect(r, COL_EDGE, false, 3.0)
		draw_string(font, r.position + Vector2(0, 44), str(cont["title"]) + " ▶", HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 36, COL_TEXT)
		draw_string(font, r.position + Vector2(0, 80), str(cont["sub"]), HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 22, COL_DIM)
	for i in items.size():
		var it: Dictionary = items[i]
		var r: Rect2 = L["cards"][i]
		var open: bool = it["state"] == "open"
		draw_rect(r, COL_CARD if open else Color(COL_CARD, 0.45))
		draw_rect(r, COL_EDGE if open else Color(COL_EDGE, 0.15), false, 2.0)
		var tc := COL_TEXT if open else COL_DIM
		if r.size.y < CARD_H:                          # 여러 줄(낮은 카드): 이름 한 줄 + 깬 횟수(작은 글)
			draw_string(font, r.position + Vector2(8, 30), str(it["title"]), HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 16, 20, tc)
			var small := str(it.get("mark", "")) if str(it.get("mark", "")) != "" else str(it["sub"])
			draw_string(font, r.position + Vector2(8, 54), small, HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 16, 15,
				COL_MARK if open and str(it.get("mark", "")) != "" else COL_DIM)
			continue
		draw_string(font, r.position + Vector2(8, 40), str(it["title"]), HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 16, 24, tc)
		draw_string(font, r.position + Vector2(8, 72), str(it["sub"]), HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 16, 18, COL_DIM)
		if str(it.get("mark", "")) != "":
			draw_string(font, r.position + Vector2(8, 104), str(it["mark"]), HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 16, 18,
				COL_MARK if open else COL_DIM)
