extends RefCounted
## 세이브 — 순수 로직(읽기 · 쓰기 파일은 main.gd 가 한다: user://save.json, 창 없는 실행은 파일을 안 쓴다).
## 형식(VERSION 1): {"v": 1, "cleared": {장 id: {"count": 깬 횟수, "best": 가장 짧은 판(로직 프레임)}}, "last": 마지막으로 한 장,
##   "art": 고른 그림(puppet · a — B(도트)는 2026-11-11 처음 화면에서 뺐다, 옛 세이브의 b 는 A 로), "speed": 게임 속도(1 · 1.5 · 2 — 로직 프레임을 1초에 60 · 90 · 120 번, 판정은 그대로),
##   "difficulty": 난이도(easy · normal · hard · hell — src/data/difficulty.gd, 2026-11-09 칸을 더함 · 옛 세이브는 normal)}
## 형식 규칙(CLAUDE.md 2-1절 도메인 품질 '세이브는 형식 버전 · 옛 세이브 시험'):
##   - 칸을 더할 때는 VERSION 을 그대로 두고 _fill 에 기본값을 둔다(옛 세이브는 빠진 칸만 채워 읽는다)
##   - 칸 뜻을 바꿀 때만 VERSION 을 올리고 _migrate 에 옛 → 새를 적는다(시험 tests/unit/test_campaign.gd)
##   - 더 새 형식(다음 판이 쓴 것)은 읽기만 한다 — 덮어쓰면 그 판의 기록이 사라진다(state "newer")
##   - 깨진 파일은 새 세이브로 시작한다(state "broken" — main.gd 가 원래 파일을 .bak 으로 남긴다)
## 시간(현재 시각)은 넣지 않는다 — 같은 입력이면 같은 세이브(시험 · 리플레이).

const Campaign = preload("res://src/data/campaign.gd")
const Difficulty = preload("res://src/data/difficulty.gd")

const VERSION := 1
const ARTS := ["puppet", "a"]    # 2026-11-11 사용자 "3. (가)" — 붓칠 · 먹선 화풍 하나로, 그림 B(도트)는 고르지 않는다(--art b 개발 인자만)
const DEFAULT_ART := "a"         # #9 결정(2026-11-06) — 본편 그림은 A(GLB 툰 모델)
const SPEEDS := [1.0, 1.5, 2.0]  # 게임 속도 고르기(사용자 2026-11-06 "싸움이 너무 느린데 게임 속도를 더 빨리 할 수 있는 버튼")
const ZOOM_MIN := 0.55           # 카메라 줌 최소(가장 넓게 — 1/0.55 ≈ 1.82배 거리)
const ZOOM_MAX := 1.45           # 카메라 줌 최대(가장 가깝게)
const DEFAULT_ZOOM := 1.0
const ZOOMS := [1.0, 0.8, 0.65, 1.25]   # 원탭 줌 순환: 기본 → 넓게 → 아주 넓게 → 가깝게


static func fresh() -> Dictionary:
	return {"v": VERSION, "cleared": {}, "last": "", "art": DEFAULT_ART, "speed": SPEEDS[0], "difficulty": Difficulty.DEFAULT, "zoom": DEFAULT_ZOOM}


## 파일 글 → {"save": 세이브, "state": "new" | "ok" | "broken" | "newer"}
static func parse(text: String) -> Dictionary:
	if text.strip_edges() == "":
		return {"save": fresh(), "state": "new"}
	var js := JSON.new()                     # JSON.parse_string 은 깨진 글에 ERROR 줄을 찍는다(verify 가 실패로 본다)
	var j = js.data if js.parse(text) == OK else null
	if not (j is Dictionary):
		return {"save": fresh(), "state": "broken"}
	var v := int(j.get("v", 0))
	if v > VERSION:
		return {"save": _fill(j), "state": "newer"}
	return {"save": _fill(_migrate(j, v)), "state": "ok"}


## 옛 형식 → 지금 형식(VERSION 1 이 첫 형식이라 아직 할 일이 없다)
static func _migrate(j: Dictionary, _v: int) -> Dictionary:
	return j


## 빠진 칸 · 모양이 틀린 칸은 기본값으로(모르는 장 id 는 남긴다 — 다음 판이 만들 장일 수 있다)
static func _fill(j: Dictionary) -> Dictionary:
	var s := fresh()
	var cl = j.get("cleared", {})
	if cl is Dictionary:
		for id in cl:
			var e = cl[id]
			if e is Dictionary and e.has("count"):
				s["cleared"][str(id)] = {"count": int(e["count"]), "best": int(e.get("best", 0))}
	s["last"] = str(j.get("last", ""))
	var art := str(j.get("art", DEFAULT_ART))
	s["art"] = art if art in ARTS else DEFAULT_ART
	var sp := float(j.get("speed", SPEEDS[0]))
	s["speed"] = sp if sp in SPEEDS else SPEEDS[0]
	s["difficulty"] = Difficulty.valid(j.get("difficulty", Difficulty.DEFAULT))
	var zm = j.get("zoom", DEFAULT_ZOOM)
	if (zm is float or zm is int) and float(zm) >= ZOOM_MIN and float(zm) <= ZOOM_MAX:
		s["zoom"] = clamp_zoom(float(zm))
	else:
		s["zoom"] = DEFAULT_ZOOM
	return s


static func dump(s: Dictionary) -> String:
	return JSON.stringify(s, "\t")


## 깬 장 기록 — frames: 판 길이(로직 프레임). 0 = 중간 스테이지부터 한 판(가장 짧은 판은 안 바꾸고 깬 횟수만 — 2026-11-09 rc.4 폰)
static func record_clear(s: Dictionary, id: String, frames: int) -> void:
	var e: Dictionary = s["cleared"].get(id, {"count": 0, "best": 0})
	e["count"] = int(e["count"]) + 1
	if frames > 0:
		e["best"] = frames if int(e["best"]) <= 0 else mini(int(e["best"]), frames)
	s["cleared"][id] = e
	s["last"] = id


static func cleared(s: Dictionary, id: String) -> bool:
	return s["cleared"].has(id)


## 이어하기: 마지막으로 깬 장(last)의 다음 장 → 그게 끝 장이면 그 장 → 깬 장이 없거나 못 하는 장이면 첫 장.
## (옛 규칙 '안 깬 첫 장'은 카드로 1장부터 깨면 프롤로그로 돌아갔다 — rc.2 폰 2026-11-07)
static func next_chapter(s: Dictionary) -> String:
	var ids := Campaign.playable_ids()
	var i := ids.find(str(s["last"]))
	if i < 0:
		return ids[0]
	return ids[mini(i + 1, ids.size() - 1)]


## 장이 열렸나 — 할 수 있는 장이고(준비 중이 아니고), 시험판(OPEN_ALL)이거나 차례 규칙이 맞으면
static func unlocked(s: Dictionary, id: String) -> bool:
	return Campaign.playable(id) and (Campaign.OPEN_ALL or unlocked_by_order(s, id))


## 차례 규칙: 할 수 있는 장 중 첫 장은 열림, 그 뒤 장은 바로 앞 장을 깨야 — 또는 그 장이나 더 뒤 장을 깬 기록이 있으면(그 앞은 모두 열림.
## 모든 장 열림(OPEN_ALL) 때 뒤 장만 깬 세이브에서 사이 장이 잠겼다 — rc.4 폰 2026-11-10 "5 · 6 · 13장을 못 함")
static func unlocked_by_order(s: Dictionary, id: String) -> bool:
	var ids := Campaign.playable_ids()
	var i := ids.find(id)
	if i < 0:
		return false
	if i == 0 or cleared(s, ids[i - 1]):
		return true
	for j in range(i, ids.size()):
		if cleared(s, ids[j]):
			return true
	return false


## 속도 버튼: ×1 → ×1.5 → ×2 → ×1
static func next_speed(v: float) -> float:
	var i := SPEEDS.find(v)
	return SPEEDS[(i + 1) % SPEEDS.size()] if i >= 0 else SPEEDS[0]


static func speed_label(v: float) -> String:
	var t := str(v)
	return "×" + (t.left(-2) if t.ends_with(".0") else t)


## 카메라 줌: 핀치 · 버튼 공용 경계(소수 둘째 자리 반올림)
static func clamp_zoom(v: float) -> float:
	return snappedf(clampf(v, ZOOM_MIN, ZOOM_MAX), 0.01)


## 줌 버튼 순환: ×1 → ×0.8(넓게) → ×0.65(최대) → ×1.25(가깝게) → ×1
static func next_zoom(v: float) -> float:
	for i in ZOOMS.size():
		if absf(v - float(ZOOMS[i])) < 0.03:
			return float(ZOOMS[(i + 1) % ZOOMS.size()])
	if v > 0.8:
		return 0.8
	if v > 0.65:
		return 0.65
	return 1.0


static func zoom_label(v: float) -> String:
	var s := "%.2f" % clamp_zoom(v)
	while s.contains(".") and (s.ends_with("0") or s.ends_with(".")):
		s = s.left(-1)
	return "×" + s


## 지금 깬 장(id)의 바로 다음 장 id(마지막 장 · 없는 장이면 "") — 깨면 바로 다음 스테이지로 순차 진행
static func next_after(id: String) -> String:
	var ids := Campaign.playable_ids()
	var i := ids.find(id)
	return ids[i + 1] if i >= 0 and i + 1 < ids.size() else ""


## 할 수 있는 장 중 깬 장 수(처음 화면 진행도 표시)
static func clear_count(s: Dictionary) -> int:
	var n := 0
	for id in Campaign.playable_ids():
		if cleared(s, id):
			n += 1
	return n

