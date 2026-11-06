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


## 안전 영역 · 카드 수 → {"cont": 이어하기 자리, "cards": [카드 자리]} — 화면 가운데 아래쪽
static func layout(sa: Rect2, n: int) -> Dictionary:
	var c := sa.get_center()
	var cont_r := Rect2(c.x - CONT.x * 0.5, c.y - 20.0, CONT.x, CONT.y)
	var cards: Array = []
	if n > 0:
		var w := minf(CARD_W_MAX, (sa.size.x - 80.0 - GAP * (n - 1)) / n)
		var total := w * n + GAP * (n - 1)
		var x0 := c.x - total * 0.5
		for i in n:
			cards.append(Rect2(x0 + i * (w + GAP), c.y + 100.0, w, CARD_H))
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
		draw_string(font, r.position + Vector2(8, 40), str(it["title"]), HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 16, 24, tc)
		draw_string(font, r.position + Vector2(8, 72), str(it["sub"]), HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 16, 18, COL_DIM)
		if str(it.get("mark", "")) != "":
			draw_string(font, r.position + Vector2(8, 104), str(it["mark"]), HORIZONTAL_ALIGNMENT_CENTER, r.size.x - 16, 18,
				COL_MARK if open else COL_DIM)
