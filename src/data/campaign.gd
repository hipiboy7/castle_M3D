extends RefCounted
## 캠페인 장 목록 — 본편(#9 결정 2026-11-06: 3D 본편화)의 장 차례. 장 번호는 castle_common 공통 장 번호(기획서 00 3절 ·
## 02 3절 표). 장 하나 = kind 로 정한 판 하나:
##   duel  — 1:1 결투(src/combat/duel.gd — 6장 인천항 김신 대 백도찬)
##   stage — 방을 차례로 지나는 여러 사람 판(src/combat/stage.gd) + 장 표(table — 방 · 역할 · 시점, 예: src/data/hotel.gd)
##           + 무대 그림(view — hotel: src/view/hotel3d.gd 호텔 층 · town: src/view/town3d.gd 1부 거리 · 실내 · haseong: src/view/haseong3d.gd 하성 본사 ·
##             world: src/view/world3d.gd 3 ~ 13장 무대 표)
##   soon  — 아직 만들지 않은 장(처음 화면에 '준비 중'으로만)
## event: 그 장이 끝날 때의 진행 사건(castle_common progression.json) — 그 장 사람의 등급 · 기술은 이 사건 앞까지의 진행.
## song: 그 장의 음악(assets/music/<이름>.ogg) — 장의 마지막 보스 방은 boss_song(없으면 boss), 결투는 song 그대로(song_for · 2026-11-09).
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

## 장 열기: false = 본편 배포(2026-11-09 사용자 '개발 끝 묶음') — 첫 장만 열리고 장을 깨면 다음 장(save.gd unlocked_by_order).
## true = 시험판(만든 장을 차례와 상관없이 모두 — 폰에서 아무 장이나 바로 볼 때). 실행 인자 --mode · 리플레이는 이와 상관없이 그 장으로 간다
const OPEN_ALL := false

const CHAPTERS := [
	{"id": "ch0", "no": 0, "kind": "stage", "event": "", "table": "prologue", "view": "town", "song": "street"},
	{"id": "ch1", "no": 1, "kind": "stage", "event": "beat:yundeoksu", "table": "hoeam", "view": "town", "song": "street"},
	{"id": "ch2", "no": 2, "kind": "stage", "event": "", "table": "haseong", "view": "haseong", "song": "battle"},
	{"id": "ch3", "no": 3, "kind": "stage", "event": "", "table": "ch3", "view": "world", "song": "dungeon"},
	{"id": "ch4", "no": 4, "kind": "stage", "event": "", "table": "ch4", "view": "world", "song": "tension"},
	{"id": "ch5", "no": 5, "kind": "stage", "event": "", "table": "ch5", "view": "world", "song": "sad"},
	{"id": "ch6a", "no": 6, "kind": "stage", "event": "", "table": "ch6a", "view": "world", "song": "port"},
	{"id": "ch6", "no": 6, "kind": "duel", "event": "duel_offbeat:baekdochan", "song": "boss"},
	{"id": "ch7", "no": 7, "kind": "stage", "event": "", "table": "ch7", "view": "world", "song": "resolve"},
	{"id": "ch8", "no": 8, "kind": "stage", "event": "", "table": "ch8", "view": "world", "song": "port"},
	{"id": "ch9", "no": 9, "kind": "stage", "event": "", "table": "ch9", "view": "world", "song": "battle"},
	{"id": "ch10", "no": 10, "kind": "stage", "event": "", "table": "ch10", "view": "world", "song": "tension"},
	{"id": "ch11", "no": 11, "kind": "stage", "event": "raid:castle_hotel", "table": "hotel", "view": "hotel", "song": "battle"},
	{"id": "ch12", "no": 12, "kind": "stage", "event": "", "table": "ch12", "view": "world", "song": "dungeon", "boss_song": "final"},
	{"id": "ch13", "no": 13, "kind": "stage", "event": "", "table": "ch13", "view": "world", "song": "battle"},
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


## 음악 이름: 결투 · 대화 장은 그 장 song, 여러 사람 판은 장의 마지막 보스 방(boss 가 있는 마지막 방)이면 boss_song(기본 boss),
## 나머지 방은 song. 모르는 장은 battle. 처음 화면 TITLE_SONG · 마지막 장을 깼을 때 ENDING_SONG(main.gd)
const TITLE_SONG := "title"
const ENDING_SONG := "ending"


static func song_for(id: String, room_i: int) -> String:
	var c := chapter(id)
	var song := str(c.get("song", "battle"))
	if kind(id) != "stage":
		return song
	var rooms: Array = table(id).ROOMS
	var last := -1
	for i in rooms.size():
		if str(rooms[i].get("boss", "")) != "" and not rooms[i].has("talk"):
			last = i
	return str(c.get("boss_song", "boss")) if last >= 0 and room_i == last else song


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

