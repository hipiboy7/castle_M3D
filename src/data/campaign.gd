extends RefCounted
## 캠페인 장 목록 — 본편(#9 결정 2026-11-06: 3D 본편화)의 장 차례. 장 번호는 castle_common 공통 장 번호(기획서 00 3절 ·
## 02 3절 표). 장 하나 = kind 로 정한 판 하나:
##   duel  — 1:1 결투(src/combat/duel.gd — 6장 인천항 김신 대 백도찬)
##   stage — 방을 차례로 지나는 여러 사람 판(src/combat/stage.gd) + 장 표(table — 방 · 역할 · 시점, 예: src/data/hotel.gd)
##           + 무대 그림(view — hotel: src/view/hotel3d.gd 호텔 층 · town: src/view/town3d.gd 1부 거리 · 실내)
##   soon  — 아직 만들지 않은 장(처음 화면에 '준비 중'으로만)
## event: 그 장이 끝날 때의 진행 사건(castle_common progression.json) — 그 장 사람의 등급 · 기술은 이 사건 앞까지의 진행.
## 장 이름 · 한 줄은 data/story/lines.json chapters.<id>(글은 코드에 적지 않는다). 장을 더할 때는 여기 한 줄 + 장 표 + 글.

const Hotel = preload("res://src/data/hotel.gd")
const Prologue = preload("res://src/data/prologue.gd")
const Hoeam = preload("res://src/data/hoeam.gd")
const Lines = preload("res://src/data/lines.gd")

## 시험판: 만든 장은 차례와 상관없이 모두 열어 둔다(폰 확인에서 아무 장이나 바로 — 본편 배포 때 false 로)
const OPEN_ALL := true

const CHAPTERS := [
	{"id": "ch0", "no": 0, "kind": "stage", "event": "", "table": "prologue", "view": "town"},
	{"id": "ch1", "no": 1, "kind": "stage", "event": "beat:yundeoksu", "table": "hoeam", "view": "town"},
	{"id": "ch6", "no": 6, "kind": "duel", "event": "duel_offbeat:baekdochan"},
	{"id": "ch11", "no": 11, "kind": "stage", "event": "raid:castle_hotel", "table": "hotel", "view": "hotel"},
]

## 장 표 이름 → 표(스크립트의 const 를 읽는다 — ROOMS · ROLES · HEROES · EVENT · PERIOD · LINES · CROWD_ID · 시간 값)
const TABLES := {"prologue": Prologue, "hoeam": Hoeam, "hotel": Hotel}

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

