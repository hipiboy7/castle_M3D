extends RefCounted
## 캠페인 장 목록 — 본편(#9 결정 2026-11-06: 3D 본편화)의 장 차례. 장 번호는 castle_common 공통 장 번호(기획서 00 3절 ·
## 02 3절 표). 장 하나 = kind 로 정한 판 하나:
##   duel  — 1:1 결투(src/combat/duel.gd — 6장 인천항 김신 대 백도찬)
##   stage — 방을 차례로 지나는 여러 사람 판(src/combat/stage.gd) + 장 표(table — 방 · 역할 · 시점, 예: src/data/hotel.gd)
##           + 무대 그림(view — hotel: src/view/hotel3d.gd 호텔 층 · town: src/view/town3d.gd 1부 거리 · 실내 · haseong: src/view/haseong3d.gd 하성 본사 ·
##             world: src/view/world3d.gd 3 ~ 13장 무대 표)
##   soon  — 아직 만들지 않은 장(처음 화면에 '준비 중'으로만)
## event: 그 장이 끝날 때의 진행 사건(castle_common progression.json) — 그 장 사람의 등급 · 기술은 이 사건 앞까지의 진행.
## 장 이름 · 한 줄은 data/story/lines.json chapters.<id>(글은 코드에 적지 않는다). 장을 더할 때는 여기 한 줄 + 장 표 + 글.

const Hotel = preload("res://src/data/hotel.gd")
const Prologue = preload("res://src/data/prologue.gd")
const Hoeam = preload("res://src/data/hoeam.gd")
const Haseong = preload("res://src/data/haseong.gd")
const Ch3 = preload("res://src/data/ch3_busan.gd")
const Ch4 = preload("res://src/data/ch4_russia.gd")
const Ch5 = preload("res://src/data/ch5_baekui.gd")
const Ch6a = preload("res://src/data/ch6a_ship.gd")
const Ch7 = preload("res://src/data/ch7_talks.gd")
const Ch8 = preload("res://src/data/ch8_port.gd")
const Ch9 = preload("res://src/data/ch9_casino.gd")
const Ch10 = preload("res://src/data/ch10_hwajin.gd")
const Ch12 = preload("res://src/data/ch12_church.gd")
const Ch13 = preload("res://src/data/ch13_museum.gd")
const Lines = preload("res://src/data/lines.gd")

## 시험판: 만든 장은 차례와 상관없이 모두 열어 둔다(폰 확인에서 아무 장이나 바로 — 본편 배포 때 false 로)
const OPEN_ALL := true

const CHAPTERS := [
	{"id": "ch0", "no": 0, "kind": "stage", "event": "", "table": "prologue", "view": "town"},
	{"id": "ch1", "no": 1, "kind": "stage", "event": "beat:yundeoksu", "table": "hoeam", "view": "town"},
	{"id": "ch2", "no": 2, "kind": "stage", "event": "", "table": "haseong", "view": "haseong"},
	{"id": "ch3", "no": 3, "kind": "stage", "event": "", "table": "ch3", "view": "world"},
	{"id": "ch4", "no": 4, "kind": "stage", "event": "", "table": "ch4", "view": "world"},
	{"id": "ch5", "no": 5, "kind": "stage", "event": "", "table": "ch5", "view": "world"},
	{"id": "ch6a", "no": 6, "kind": "stage", "event": "", "table": "ch6a", "view": "world"},
	{"id": "ch6", "no": 6, "kind": "duel", "event": "duel_offbeat:baekdochan"},
	{"id": "ch7", "no": 7, "kind": "stage", "event": "", "table": "ch7", "view": "world"},
	{"id": "ch8", "no": 8, "kind": "stage", "event": "", "table": "ch8", "view": "world"},
	{"id": "ch9", "no": 9, "kind": "stage", "event": "", "table": "ch9", "view": "world"},
	{"id": "ch10", "no": 10, "kind": "stage", "event": "", "table": "ch10", "view": "world"},
	{"id": "ch11", "no": 11, "kind": "stage", "event": "raid:castle_hotel", "table": "hotel", "view": "hotel"},
	{"id": "ch12", "no": 12, "kind": "stage", "event": "", "table": "ch12", "view": "world"},
	{"id": "ch13", "no": 13, "kind": "stage", "event": "", "table": "ch13", "view": "world"},
]

## 장 표 이름 → 표(스크립트의 const 를 읽는다 — ROOMS · ROLES · HEROES · EVENT · PERIOD · LINES · CROWD_ID · 시간 값)
const TABLES := {"prologue": Prologue, "hoeam": Hoeam, "haseong": Haseong, "hotel": Hotel, "ch3": Ch3, "ch4": Ch4, "ch5": Ch5, "ch6a": Ch6a, "ch7": Ch7, "ch8": Ch8, "ch9": Ch9, "ch10": Ch10, "ch12": Ch12, "ch13": Ch13}

## 옛 실행 인자(--mode duel|stage) → 장 id
const MODE_ALIAS := {"duel": "ch6", "stage": "ch11"}


static func ids() -> Array:
	var out: Array = []
	for c in CHAPTERS:
		out.append(c["id"])
	return out


static func chapter(id: String) -> Dictionary:
	for c in CHAPTERS:
		if c["id"] == id:
			return c
	return {}


static func playable(id: String) -> bool:
	return str(chapter(id).get("kind", "")) in ["duel", "stage"]


static func playable_ids() -> Array:
	return ids().filter(func(i): return playable(i))


static func kind(id: String) -> String:
	return str(chapter(id).get("kind", ""))


static func table(id: String):
	return TABLES.get(str(chapter(id).get("table", "")))


## 여러 사람 판의 무대 그림 이름(main.gd VIEWS) — 없으면 hotel
static func view(id: String) -> String:
	return str(chapter(id).get("view", "hotel"))


## [이름, 한 줄] — lines.json chapters.<id>
static func title(id: String):
	return Lines.at("chapters." + id)


## 짧은 이름(싸움 중 메뉴의 작은 카드 — 장이 많을 때): 프롤로그 · N장 · 한 장을 앞 · 뒤로 나눈 앞쪽(id 끝 a)은 'N장 앞'
static func short_title(id: String) -> String:
	var c := chapter(id)
	if c.is_empty():
		return ""
	if int(c["no"]) == 0:
		return str(title(id)[0])
	return "%d장%s" % [int(c["no"]), " 앞" if id.ends_with("a") else ""]


## 실행 인자 · 옛 이름 → 할 수 있는 장 id(못 하는 장이면 "")
static func from_mode(m: String) -> String:
	var id: String = MODE_ALIAS.get(m, m)
	return id if playable(id) else ""


## 장 안의 스테이지(싸움 중 메뉴로 바로 가는 자리) — [{"room": 방 번호, "title": 이름}]. 여러 사람 판 = 장 표의 방
## (이름 = lines.json <LINES>.rooms.<방 id>.enter 의 첫 글), 결투 = 하나(장 이름), 준비 중 · 없는 장 = 없음
static func stages(id: String) -> Array:
	var out: Array = []
	match kind(id):
		"duel":
			out.append({"room": 0, "title": str(title(id)[0])})
		"stage":
			var T = table(id)
			for i in T.ROOMS.size():
				var v = Lines.at("%s.rooms.%s.enter" % [T.LINES, T.ROOMS[i]["id"]])
				out.append({"room": i, "title": str(v[0]) if v is Array else str(T.ROOMS[i]["id"])})
	return out

