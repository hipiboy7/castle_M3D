extends RefCounted
## **3D 덧붙임 1층** — castle_common data/characters.json · skills.json 에 아직 없는 인물 · 기술(11장 호텔 캐슬).
## 근거: 사용자 답 2026-11-06 —
##   하야부사: 준10강 · 긴칼 · 신겐 기술을 하향해서 · 능력치는 신겐을 준10강 수준으로 하향
##   경호대 최후의 4인: 전국구 · 총/칼 · 마준영 기술의 전국구 레벨 하향 · 능력치도 전국구 레벨
##   구일화: (화진 전) 전국구 · (교회 전) 이스크라 평 킬러급 · 주먹/칼 · 기술은 알아서 · 능력치도 시기별로
## 기술의 정체(이름 · 원본)는 원작 판독(castle_common canon/episodes moves — 화/컷)에서 골랐다. 숫자 능력치 · 기술 고르기는
## 이 판의 후보(provisional) — castle_common 에 올릴 것은 docs/castle_common_요청.md. castle_common 에 그 인물이 생기면
## character() 가 castle_common 값을 먼저 쓴다(여기는 빈 칸만 채운다).
## 기술의 동작 · 프레임 · 피해(3층)는 src/data/moves.gd, 능력치 → 3층 배율은 derive().
## castle_common 70차(5b145d8)가 인물 3 · 신겐 능력치 · 기술 11 을 받아 갔다(요청 16 ~ 18행) — 지금은 공통 값이 먼저이고
## 여기 표는 공통에 없는 칸(엑스트라 castle_guard · 구일화 시기별 rank_by · stats_by · 기술 move)과 받기 전 판의 대비로 남는다.

const Common = preload("res://src/data/common.gd")

## 시기 키 — 11장(호텔 캐슬) = hwajin(화진 전 무렵), 12장 교회전 = church
const PERIOD_CH11 := "hwajin"

const CHARACTERS := {
	"shingen": {"id": "shingen", "name": "사사키 신겐", "rank": "내성 상위", "weapons": ["맨손", "칼", "대도"],
		"stats": {"힘": 88, "속도": 80, "기술": 85, "맷집": 90},
		"skills": ["shingen_daegeuk", "shingen_dive", "shingen_frontkick", "shingen_leap"],
		"src": "기술 85 · 등급 · 무기는 castle_common. 나머지 능력치 · 기술 고르기는 3D 덧붙임(원작 058 · 059 · 062 · 097 ~ 102 판독)",
		"provisional": ["stats", "skills"]},
	"hayabusa": {"id": "hayabusa", "name": "하야부사", "rank": "준10강", "weapons": ["긴칼"],
		"stats": {"힘": 70, "속도": 74, "기술": 72, "맷집": 66},
		"skills": ["hayabusa_arc", "hayabusa_low"],
		"src": "사용자 2026-11-06 '준 10강, 긴칼 사용, 신겐 기술 하향해서 사용. 능력치 신겐 능력치를 준10강 수준으로 하향'",
		"provisional": ["stats"]},
	"gyeonghodaechoehuui4in": {"id": "gyeonghodaechoehuui4in", "name": "경호대 최후의 4인", "rank": "전국구",
		"weapons": ["총/칼"], "stats": {"힘": 64, "속도": 52, "기술": 50, "맷집": 68},
		"skills": ["g4_heelkick", "g4_chop", "g4_shot"],
		"src": "사용자 2026-11-06 '전국구, 총/칼 사용, 기술은 마준영 기술의 전국구 레벨로 하향. 능력치도 전국구 레벨로 하향'",
		"provisional": ["stats"]},
	"guilhwa": {"id": "guilhwa", "name": "구일화", "weapons": ["맨손", "칼"],
		"rank_by": {"hwajin": "전국구", "church": "이스크라 평 킬러급"},
		"stats_by": {"hwajin": {"힘": 68, "속도": 54, "기술": 46, "맷집": 76},
			"church": {"힘": 72, "속도": 56, "기술": 50, "맷집": 80}},
		"skills": ["guilhwa_headbutt", "guilhwa_forearm"],
		"src": "사용자 2026-11-06 '(화진 전) 전국구, (교회 전) 평이스크라킬러급, 주먹/칼 사용, 기술은 알아서 생성. 능력치도 화진전/교회전 나눠서'",
		"provisional": ["stats", "skills"]},
	# 이름 없는 경호원(원작 057 '경호대 정장 8인' · '톤파 경호원') — 인물 표에 없는 엑스트라. 등급은 사다리의 '경호대급'
	"castle_guard": {"id": "castle_guard", "name": "캐슬 경호원", "rank": "경호대급", "weapons": ["맨손", "곤봉"],
		"stats": {"힘": 50, "속도": 50, "기술": 40, "맷집": 50}, "skills": [],
		"src": "3D 덧붙임 엑스트라(원작 057/042-079 중앙홀 난전의 경호대 정장 8인) — 등급 · 능력치는 이 판 후보",
		"provisional": ["rank", "stats"]},
	# ---- 0 · 1장 엑스트라(S5 묶음 2 · 3) — 이름 있는 인물(군터 · 김대건 · 윤덕수 · 강만재 · 김성준 · 김혁주)은 castle_common 72차에 있다.
	# 이름 없는 사람들은 공통에 두지 않는다(3D 요청 19 와 같음 — 원작 근거는 canon fights.json mobs). 등급 · 능력치는 이 판 후보
	"gunter_guard": {"id": "gunter_guard", "name": "군터 경호원", "rank": "건달급", "weapons": ["맨손", "총"],
		"stats": {"힘": 44, "속도": 44, "기술": 34, "맷집": 42}, "skills": [],
		"src": "3D 덧붙임 엑스트라(원작 fight:gunter mobs — 대머리 경호원 · 우지 든 장발 남자 · 포니테일 거구, p1:002/013-020)",
		"provisional": ["rank", "stats"]},
	"ds_member": {"id": "ds_member", "name": "DS 조직원", "rank": "건달급", "weapons": ["맨손", "칼"],
		"stats": {"힘": 44, "속도": 44, "기술": 34, "맷집": 44}, "skills": [],
		"src": "3D 덧붙임 엑스트라(원작 fight:kimhyeokju '정장 남자들' p1:003 · fight:jintae_ds 'DS 정장 무리' p1:019-020)",
		"provisional": ["rank", "stats"]},
	"ds_raider": {"id": "ds_raider", "name": "DS 습격조", "rank": "건달급", "weapons": ["맨손", "곤봉"],
		"stats": {"힘": 46, "속도": 42, "기술": 32, "맷집": 46}, "skills": [],
		"src": "3D 덧붙임 엑스트라(원작 fight:pyechajang 'DS 습격조(방망이 · 쇠파이프 · 복면)' p1:008-010)",
		"provisional": ["rank", "stats"]},
}

## 기술(1층 정체) — from: 하향의 원본 기술 · refs: 원작 화/컷
const SKILLS := {
	"shingen_daegeuk": {"id": "shingen_daegeuk", "name": "대극 큰 호 베기", "owner": "shingen", "move": "s_sg_daegeuk",
		"desc": "긴 칼(대극)로 흰 호를 그리며 크게 휘두르고 아래에서 위로 쳐올린다", "refs": ["062/084-106", "098/035-047"]},
	"shingen_dive": {"id": "shingen_dive", "name": "낮은 파고들기", "owner": "shingen", "move": "s_sg_dive",
		"desc": "몸을 낮춰 휘두름 밑으로 파고들어 단도로 벤다 — 못 막는다", "refs": ["062/084-106", "098/035-047"]},
	"shingen_frontkick": {"id": "shingen_frontkick", "name": "앞차기", "owner": "shingen", "move": "s_sg_kick",
		"desc": "구두 바닥으로 몸통을 밀어 찬다 — 멀리 날아간다", "refs": ["097", "099", "101"]},
	"shingen_leap": {"id": "shingen_leap", "name": "날아차기", "owner": "shingen", "move": "s_sg_leap",
		"desc": "한 발로 뛰어올라 위에서 내리찍듯 찬다 — 못 막는다", "refs": ["101"]},
	"hayabusa_arc": {"id": "hayabusa_arc", "name": "하야부사식 큰 호 베기", "owner": "hayabusa", "from": "shingen_daegeuk",
		"move": "s_hy_arc", "desc": "대극 큰 호 베기의 하향 — 호가 좁고 느리다", "refs": ["019", "098/024-031"]},
	"hayabusa_low": {"id": "hayabusa_low", "name": "낮은 다리 베기", "owner": "hayabusa", "from": "shingen_dive",
		"move": "s_hy_low", "desc": "낮은 파고들기의 하향 — 무릎 꿇듯 낮춰 다리를 긋는다", "refs": ["095"]},
	"g4_heelkick": {"id": "g4_heelkick", "name": "내려찍기 하이킥", "owner": "gyeonghodaechoehuui4in", "from": "majunyeong:구속복 하이킥",
		"move": "s_g4_heel", "desc": "마준영 하이킥의 하향 — 다리를 높이 들어 뒤꿈치로 내려찍는다", "refs": ["002/101-103"]},
	"g4_chop": {"id": "g4_chop", "name": "칼 내리찍기", "owner": "gyeonghodaechoehuui4in", "from": "majunyeong:칼 내리찍기",
		"move": "s_g4_chop", "desc": "마준영 칼 내리찍기의 하향", "refs": ["033"]},
	"g4_shot": {"id": "g4_shot", "name": "근거리 사격", "owner": "gyeonghodaechoehuui4in", "from": "majunyeong:근거리 소음기 연사",
		"move": "t_shot", "desc": "마준영 근거리 연사의 하향 — 겨눈 뒤 한 발. 못 막는다(구른다)", "refs": ["045", "058/039-045"]},
	"guilhwa_headbutt": {"id": "guilhwa_headbutt", "name": "들이받기", "owner": "guilhwa", "move": "s_gu_headbutt",
		"desc": "뛰어들며 머리 · 어깨로 턱을 들이받는다 — 맞으면 잠깐 기절", "refs": ["057/042-079", "109"]},
	"guilhwa_forearm": {"id": "guilhwa_forearm", "name": "팔뚝 연타", "owner": "guilhwa", "move": "s_gu_forearm",
		"desc": "팔꿈치 · 팔뚝으로 얼굴을 세 번 연달아 친다", "refs": ["057/042-079"]},
}


static func _has_common(id: String) -> bool:
	for c in Common._j("characters")["characters"]:
		if c["id"] == id:
			return true
	return false


## 인물 — castle_common 에 있으면 그 값이 먼저, 빈 칸(skills [] · 모르는 능력치)만 여기서 채운다
static func character(id: String) -> Dictionary:
	var out: Dictionary = CHARACTERS.get(id, {}).duplicate(true)
	if _has_common(id):
		var c: Dictionary = Common.character(id)
		for k in c:
			var v = c[k]
			if k == "stats" and out.has("stats"):
				var st: Dictionary = out["stats"]
				st.merge(v, true)
			elif (v is Array and v.is_empty()) or v == null:
				if not out.has(k):
					out[k] = v
			else:
				out[k] = v
	return out


## 기술 — 1층(이름 · 설명 · from · refs)은 castle_common skills.json 이 먼저(70차부터 11장 기술 11개가 있다),
## 동작(move — 3층, 이 판 소유)은 여기 표에서 잇는다
static func skill(id: String) -> Dictionary:
	var out: Dictionary = SKILLS.get(id, {}).duplicate(true)
	for s in Common._j("skills")["skills"]:
		if s["id"] == id:
			out.merge(s, true)
			break
	return out


static func rank_at(id: String, period: String) -> String:
	var c := character(id)
	if c.has("rank_by"):
		return str(c["rank_by"].get(period, c["rank_by"].values()[0]))
	return str(c.get("rank", ""))


static func stats_at(id: String, period: String) -> Dictionary:
	var c := character(id)
	if c.has("stats_by"):
		return c["stats_by"].get(period, c["stats_by"].values()[0])
	return c.get("stats", {})


## 능력치(1~100, 기준 80 = 1배) → 3층 배율: hp(맷집) · dmg(힘) · speed(속도, 반만) · guard(기술 — AI 가 막는 확률)
static func derive(stats: Dictionary) -> Dictionary:
	var f := func(k: String) -> float: return float(stats.get(k, 80)) / 80.0
	return {"hp": f.call("맷집"), "dmg": f.call("힘"), "speed": 0.5 + 0.5 * f.call("속도"),
		"guard": clampf(0.55 * f.call("기술"), 0.05, 0.8)}
