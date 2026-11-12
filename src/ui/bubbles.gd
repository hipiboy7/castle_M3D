extends Control
## 말풍선(2026-11-12 사용자 "캐릭터들의 말과 대화는 배경 및 게임과 어울리는 말풍선으로") — 화풍(먹선 · 종이 — src/view/ink.gd)에 맞춰
## 바랜 종이 바탕 + 손떨림 먹선 테두리 + 말하는 사람 머리로 꼬리. 외침(! 로 끝남)은 들쭉날쭉한 터짐 풍선, 속말(괄호)은 구름 풍선 +
## 점 꼬리, 말하는 사람이 화면에 없으면(내레이션) 왼쪽 위 먹빛 띠. 게임 판정과 상관없다(main.gd 가 화면 자리를 준다).
## 자리: 머리 위(화면 좌표) — 화면 밖이면 가장자리 안으로, 풍선끼리 겹치면 나중 것을 위로 민다.

const FONT = preload("res://assets/fonts/Galmuri11-Bold.ttf")
const PAPER := Color(0.965, 0.945, 0.9)
const PAPER_SHOUT := Color(1.0, 0.97, 0.88)
const INK := Color(0.07, 0.06, 0.06)
const INK_W := 3.2
const TEXT_COL := Color(0.08, 0.07, 0.07)
const NAME_COL := Color(0.55, 0.16, 0.12)       # 이름 글(풍선 왼쪽 위 작은 붉은 낙관 느낌)
const CAP_BG := Color(0.06, 0.055, 0.05, 0.86)
const CAP_TEXT := Color(0.95, 0.92, 0.85)
const FONT_SIZE := 22
const NAME_SIZE := 15
const MAX_W := 330.0
const PAD := Vector2(16, 12)
const TAIL := 26.0
const POP_T := 0.14
const FADE_T := 0.25
const TOP_PAD := 150.0                           # 위 가장자리(체력 막대 · 메뉴 · 멈춤 단추) 밑으로만
const HEAD_UP := 0.45                            # 머리 위(m) — 자리 함수가 주는 머리 높이 위로 더

var items: Array = []              # {who, text, name, left, total, style, anchor(Vector2), seed}
var anchor_fn: Callable            # (who) → [보이나, 화면 자리 Vector2] — main.gd


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


## 말 하나 — who 는 판의 사람(없으면 내레이션), name 은 풍선 위 작은 이름(빈 글이면 안 씀)
func say(who, text: String, secs: float, name := "") -> void:
	var style := "talk"
	var t := text.strip_edges()
	if t.begins_with("(") and t.ends_with(")"):
		style = "think"
		t = t.substr(1, t.length() - 2)
	elif t.ends_with("!") or t.ends_with("!!") or t.ends_with("?!"):
		style = "shout"
	if who == null:
		style = "caption"
	# 같은 사람의 앞 풍선은 지운다(말이 이어지면 새 풍선으로 바뀜)
	items = items.filter(func(it): return it["who"] != who or who == null)
	items.append({"who": who, "text": t, "name": name, "left": secs, "total": secs, "style": style, "seed": text.hash() & 0xffff})
	queue_redraw()


func clear() -> void:
	items.clear()
	_later.clear()
	queue_redraw()


var _later: Array = []             # [남은 기다림, who, 말, 초]


## 조금 뒤에(알림 글 줄 세우기와 같은 늦춤 — stage.gd 대사 SAY_SECS 차례)
func say_later(who, text: String, secs: float, delay: float) -> void:
	_later.append([delay, who, text, secs])


## 장면 넘기기: 가장 오래된(지금 읽는) 풍선을 지운다
func cut_oldest() -> void:
	if not items.is_empty():
		items.remove_at(0)
		queue_redraw()


func _process(dt: float) -> void:
	for l in _later.duplicate():
		l[0] = float(l[0]) - dt
		if float(l[0]) <= 0.0:
			_later.erase(l)
			say(l[1], str(l[2]), float(l[3]))
	if items.is_empty():
		return
	for it in items:
		it["left"] = float(it["left"]) - dt
	items = items.filter(func(it): return float(it["left"]) > 0.0)
	queue_redraw()


func _draw() -> void:
	var used: Array = []                       # 이미 그린 풍선 칸(겹치면 위로)
	var view := get_viewport_rect().size
	var cap_y := 150.0
	for it in items:
		var lines := _wrap(str(it["text"]), MAX_W)
		var tw := 0.0
		for ln in lines:
			tw = maxf(tw, FONT.get_string_size(ln, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x)
		var lh := FONT.get_height(FONT_SIZE) + 2.0
		var size := Vector2(tw, lh * lines.size()) + PAD * 2.0
		var age := float(it["total"]) - float(it["left"])
		var pop := clampf(age / POP_T, 0.0, 1.0)
		var alpha := clampf(float(it["left"]) / FADE_T, 0.0, 1.0)
		if it["style"] == "caption" or not anchor_fn.is_valid():
			_draw_caption(lines, size, Vector2(28, cap_y), alpha, lh)
			cap_y += size.y + 8.0
			continue
		var a: Array = anchor_fn.call(it["who"])
		if not a[0]:
			_draw_caption(lines, size, Vector2(28, cap_y), alpha, lh, str(it["name"]))
			cap_y += size.y + 8.0
			continue
		var head: Vector2 = a[1]
		var box := Rect2(head - Vector2(size.x * 0.35, size.y + TAIL + 6.0), size)
		box.position.x = clampf(box.position.x, 12.0, view.x - size.x - 12.0)
		box.position.y = clampf(box.position.y, TOP_PAD, view.y - size.y - 12.0)
		for r in used:
			if (r as Rect2).grow(4.0).intersects(box):
				box.position.y = (r as Rect2).position.y - size.y - 10.0
		box.position.y = maxf(TOP_PAD * 0.6, box.position.y)
		used.append(box)
		var s := lerpf(0.7, 1.0, _ease_out(pop))
		var c := box.get_center()
		draw_set_transform(c, 0.0, Vector2(s, s))
		var local := Rect2(box.position - c, box.size)
		_draw_bubble(local, head - c, str(it["style"]), int(it["seed"]), alpha)
		var y := local.position.y + PAD.y + FONT.get_ascent(FONT_SIZE)
		for ln in lines:
			draw_string(FONT, Vector2(local.position.x + PAD.x, y), ln, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE,
				Color(TEXT_COL, alpha))
			y += lh
		if str(it["name"]) != "":
			draw_string(FONT, local.position + Vector2(10, -4), str(it["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, NAME_SIZE,
				Color(NAME_COL, alpha))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


## 풍선 몸 + 꼬리 — 둘레 점을 손떨림으로 흔들어 먹선(붓)처럼, 외침은 뾰족뾰족, 속말은 구름 + 점 꼬리
func _draw_bubble(r: Rect2, tip: Vector2, style: String, seed: int, alpha: float) -> void:
	var c := r.get_center()
	var rx := r.size.x * 0.5 + 6.0
	var ry := r.size.y * 0.5 + 6.0
	var pts := PackedVector2Array()
	var n := 44
	for i in n:
		var a := TAU * float(i) / n
		var k := 1.0
		if style == "shout":
			k = 1.16 if i % 2 == 0 else 0.92
		elif style == "think":
			k = 1.0 + 0.07 * absf(sin(a * 5.0))
		var wob := 1.0 + 0.025 * sin(float(seed % 97) + a * 3.0) + 0.015 * sin(float(seed % 31) + a * 7.0)
		# 모서리를 둥근 네모에 가깝게(가로로 긴 글) — 초타원
		var ca := cos(a)
		var sa := sin(a)
		var sx := signf(ca) * pow(absf(ca), 0.6)
		var sy := signf(sa) * pow(absf(sa), 0.6)
		pts.append(c + Vector2(sx * rx, sy * ry) * k * wob)
	var paper := Color(PAPER_SHOUT if style == "shout" else PAPER, alpha * 0.97)
	var ink := Color(INK, alpha)
	# 꼬리(말) — 몸 아래 가장자리에서 머리 쪽으로
	if style != "think":
		var base := Vector2(clampf(tip.x, r.position.x + 18.0, r.end.x - 18.0), r.end.y + 2.0)
		var dir := (tip - base)
		if dir.length() > TAIL:
			dir = dir.normalized() * TAIL
		var tail_pts := PackedVector2Array([base + Vector2(-11, -4), base + dir, base + Vector2(9, -4)])
		draw_colored_polygon(tail_pts, paper)
		draw_polyline(PackedVector2Array([tail_pts[0], tail_pts[1], tail_pts[2]]), ink, INK_W, true)
	draw_colored_polygon(pts, paper)
	var loop := pts.duplicate()
	loop.append(pts[0])
	draw_polyline(loop, ink, INK_W, true)
	# 먹이 번진 듯 한 번 더 얇게(조금 어긋나게)
	var loop2 := PackedVector2Array()
	for p in loop:
		loop2.append(p + Vector2(1.2, 0.8))
	draw_polyline(loop2, Color(INK, alpha * 0.35), 1.4, true)
	if style != "think":
		# 꼬리 자리의 먹선을 종이로 덮어 몸과 이어지게
		var base2 := Vector2(clampf(tip.x, r.position.x + 18.0, r.end.x - 18.0), r.end.y + 2.0)
		draw_line(base2 + Vector2(-9, -5), base2 + Vector2(7, -5), paper, INK_W + 2.0)
	else:
		var from := Vector2(c.x, r.end.y + 8.0)
		for i in 3:
			var p := from.lerp(tip, 0.25 + 0.3 * i)
			var rad := 6.0 - i * 1.6
			draw_circle(p, rad, paper)
			draw_arc(p, rad, 0.0, TAU, 14, ink, 2.0, true)


func _draw_caption(lines: Array, size: Vector2, at: Vector2, alpha: float, lh: float, name := "") -> void:
	var r := Rect2(at, size)
	draw_rect(r, Color(CAP_BG, CAP_BG.a * alpha))
	draw_line(r.position + Vector2(0, r.size.y), r.end, Color(0.7, 0.2, 0.15, alpha), 3.0)   # 붉은 밑줄(낙관 빛)
	var y := r.position.y + PAD.y + FONT.get_ascent(FONT_SIZE)
	var pre := (name + " · ") if name != "" else ""
	var first := true
	for ln in lines:
		draw_string(FONT, Vector2(r.position.x + PAD.x, y), (pre + ln) if first else ln, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE,
			Color(CAP_TEXT, alpha))
		first = false
		y += lh


## 글을 폭에 맞춰 나눈다 — 띄어쓰기 단위, 한 낱말이 너무 길면 글자 단위
func _wrap(text: String, w: float) -> Array:
	var out: Array = []
	for para in text.split("\n"):
		var cur := ""
		for word in para.split(" "):
			var trial := word if cur == "" else cur + " " + word
			if FONT.get_string_size(trial, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x <= w:
				cur = trial
				continue
			if cur != "":
				out.append(cur)
			cur = ""
			for ch in word:
				var t2 := cur + ch
				if FONT.get_string_size(t2, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x > w and cur != "":
					out.append(cur)
					cur = ch
				else:
					cur = t2
		if cur != "":
			out.append(cur)
	return out


static func _ease_out(u: float) -> float:
	return 1.0 - (1.0 - u) * (1.0 - u)
