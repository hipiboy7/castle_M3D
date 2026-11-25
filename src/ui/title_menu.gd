extends Control
## 처음 화면 메뉴 — 느와르 그래픽 노블 4버튼 메뉴(이어서 하기 · 스테이지 선택 · 처음부터 · 끝내기).
## layout() · hint_y_of() 구 계약과 새 menu_layout() 순수 함수 계약을 모두 tests/unit/test_ui_logic.gd 로 검증.

const SafeArea = preload("res://src/ui/safe_area.gd")
const FONT_HEAD = preload("res://assets/fonts/BlackHanSans-Regular.ttf")
const FONT_BODY = preload("res://assets/fonts/Pretendard-Bold.otf")

const CARD_H := 120.0
const CARD_W_MAX := 300.0
const GAP := 20.0
const CONT := Vector2(540, 96)

# 4버튼 수직 타이틀 메뉴 규격(Z Fold 4 커버 23:9 · 펼침 6:5 모두 안전 영역 안)
const MENU_W_MAX := 460.0
const MENU_PRIMARY_H := 82.0
const MENU_ITEM_H := 58.0
const MENU_GAP := 12.0

const COL_CARD := Color(0.05, 0.055, 0.082, 0.88)
const COL_CARD_LOCK := Color(0.04, 0.045, 0.065, 0.56)
const COL_CONT := Color(0.56, 0.10, 0.11, 0.94)
const COL_QUIT := Color(0.10, 0.05, 0.065, 0.86)
const COL_CRIMSON := Color(0.88, 0.16, 0.18, 0.96)
const COL_EDGE := Color(1, 1, 1, 0.28)
const COL_TEXT := Color(0.97, 0.97, 0.99, 0.96)
const COL_DIM := Color(0.76, 0.80, 0.86, 0.72)
const COL_MARK := Color(0.98, 0.80, 0.30, 0.98)

var cont := {}                  # {"id": "continue", "title", "sub"} (레거시 카드 모드 호환)
var items: Array = []           # [{"id", "title", "sub", "state", "mark"}] (레거시 카드 모드 호환)
var actions: Array = []         # [{"id": "continue"|"stages"|"new_game"|"quit", "title", "sub", "style": "primary"|"normal"|"quit"}]
var _last_safe := Rect2()

const ROW_MAX := 6
const PER_ROW := 5
const ROWS_H := 64.0
const ROWS_GAP := 10.0


## 4버튼 수직 타이틀 메뉴 자리 계산(순수 함수 — test_ui_logic.gd)
static func menu_layout(sa: Rect2, n: int) -> Array:
	var out: Array = []
	if n <= 0:
		return out
	var c := sa.get_center()
	var w := minf(MENU_W_MAX, sa.size.x - 120.0)
	var total_h := MENU_PRIMARY_H + maxf(0.0, float(n - 1)) * (MENU_ITEM_H + MENU_GAP)
	var y0 := clampf(c.y - 34.0, c.y - 52.0, sa.end.y - 18.0 - total_h)
	var x := c.x - w * 0.5
	var y := y0
	for i in n:
		var h := MENU_PRIMARY_H if i == 0 else MENU_ITEM_H
		out.append(Rect2(x, y, w, h))
		y += h + MENU_GAP
	return out


## 4버튼 모드 안내 글 높이(제목 아래 · 첫 버튼 위)
static func menu_hint_y(sa: Rect2, n: int) -> float:
	var rects := menu_layout(sa, n)
	if rects.is_empty():
		return sa.get_center().y - 56.0
	return float((rects[0] as Rect2).position.y) - 34.0


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
	var sa := SafeArea.rect(get_viewport())
	if not actions.is_empty():
		return menu_hint_y(sa, actions.size())
	return hint_y_of(sa, items.size())


static func hint_y_of(sa: Rect2, n: int) -> float:
	return float(layout(sa, n)["cont"].position.y) - 36.0


func hit(p: Vector2) -> String:
	if not visible:
		return ""
	var sa := SafeArea.rect(get_viewport())
	if not actions.is_empty():
		var rects := menu_layout(sa, actions.size())
		for i in actions.size():
			if (rects[i] as Rect2).has_point(p):
				return str(actions[i]["id"])
		return ""
	var L := layout(sa, items.size())
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
	var sa := SafeArea.rect(get_viewport())
	if not actions.is_empty():
		_draw_actions(sa)
		return
	var L := layout(sa, items.size())
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


func _draw_actions(sa: Rect2) -> void:
	var rects := menu_layout(sa, actions.size())
	for i in actions.size():
		var act: Dictionary = actions[i]
		var r: Rect2 = rects[i]
		var st := str(act.get("style", "normal"))
		var is_primary := st == "primary"
		var is_quit := st == "quit"
		var sub_txt := str(act.get("sub", ""))
		# 드롭 섀도 + 느와르 바탕
		draw_rect(Rect2(r.position + Vector2(4, 5), r.size), Color(0, 0, 0, 0.50))
		draw_rect(r, COL_CONT if is_primary else (COL_QUIT if is_quit else COL_CARD))
		# 좌측 악센트 바(주 버튼은 골드, 일반은 크림슨, 끝내기는 저채도)
		var bar_col := COL_MARK if is_primary else (Color(0.65, 0.25, 0.28, 0.72) if is_quit else COL_CRIMSON)
		draw_rect(Rect2(r.position, Vector2(6 if is_primary else 4, r.size.y)), bar_col)
		draw_rect(Rect2(r.position, Vector2(r.size.x, 1.5)), Color(1, 1, 1, 0.26 if is_primary else 0.16))
		draw_rect(r, Color(1, 1, 1, 0.46) if is_primary else COL_EDGE, false, 2.0 if is_primary else 1.5)
		var title_txt := str(act["title"]) + ("  ▶" if is_primary else "")
		if is_primary:
			draw_string(FONT_HEAD, r.position + Vector2(0, 42), title_txt, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 30, COL_TEXT)
			if sub_txt != "":
				draw_string(FONT_BODY, r.position + Vector2(0, 69), sub_txt, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 16, Color(0.98, 0.92, 0.85, 0.90))
		elif sub_txt != "":
			draw_string(FONT_HEAD, r.position + Vector2(0, 31), title_txt, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 22, COL_TEXT)
			draw_string(FONT_BODY, r.position + Vector2(0, 50), sub_txt, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 13, COL_DIM)
		else:
			draw_string(FONT_HEAD, r.position + Vector2(0, 39), title_txt, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 22,
				Color(0.90, 0.82, 0.84, 0.92) if is_quit else COL_TEXT)
