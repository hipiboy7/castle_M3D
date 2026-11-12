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

## 이름 없는 엑스트라(인물 표 · canon 에 없다 — 장 데이터 검사가 canon 인물 id 를 보지 않는 것)
const EXTRAS := ["castle_guard", "gunter_guard", "ds_member", "ds_raider", "haseong_suit", "haseong_guard", "namgu_youth",
	"street_thug", "gang_blade", "gang_brute", "pro_fighter", "elite_guard", "hahoe_mask", "redspot_mask"]

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
	# 이스크라 '자유로운 영혼' 팀(10장 산 기슭 — 사용자 2026-11-11 "아킬라, 프리깃, 샤모를 대체할 새로운 자유로운 영혼 팀. 콘도르, 헤론, 오울"
	#  · 원작 053 ~ 055 fight:akila_suv). castle_common canon 에 인물(condor · heron · owl)은 있으나 data/characters.json 에 없다.
	#  콘도르 등급은 강함표(외성 중위), 헤론 · 오울 등급 · 셋의 능력치 · 기술 고르기는 이 판의 후보(요청 35행)
	"condor": {"id": "condor", "name": "콘도르", "rank": "외성 중위", "weapons": ["쌍권총"],
		"stats": {"힘": 66, "속도": 74, "기술": 78, "맷집": 64},
		"skills": ["condor_volley", "condor_ambush"],
		"src": "등급 ranks.json 강함표 외성 중위. 쌍권총 — 사용자 2026-11-11 · canon look '소음기 단 대형 자동권총 두 자루'(054/043-052)",
		"provisional": ["stats", "skills"]},
	"heron": {"id": "heron", "name": "헤론", "rank": "외성 하위", "weapons": ["저격 소총", "권총"],
		"stats": {"힘": 58, "속도": 66, "기술": 80, "맷집": 56},
		"skills": ["heron_snipe", "heron_triple"],
		"src": "저격 소총 — 사용자 2026-11-11 · canon look '스코프 달린 저격소총과 권총 · 드론'(054/011-042). 등급은 이 판 후보(콘도르 밑)",
		"provisional": ["rank", "stats", "skills"]},
	"owl": {"id": "owl", "name": "오울", "rank": "외성 하위", "weapons": ["돌격소총", "연막탄", "수류탄"],
		"stats": {"힘": 62, "속도": 70, "기술": 72, "맷집": 62},
		"skills": ["owl_smoke", "owl_grenade"],
		"src": "돌격소총 — 사용자 2026-11-11 · canon look '도트사이트 · 소음기 단 사막색 카빈과 연막탄'(054/012-013). 등급은 이 판 후보(콘도르 밑)",
		"provisional": ["rank", "stats", "skills"]},
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
	# ---- 2장 하성 본사(S5 묶음 4) — 등급 · 무기는 사용자 답 2026-11-06("신태진은 준10강 양손 칼. 황보민철은 전국구, 양손 칼. 이슬은
	# 전국구 맨손. 오지인 전국구 아래급에 긴 칼. 김재훈은 최하위, 맨손." — 전국구 아래급 = 경호대급, 최하위 = 건달급(ranks.json 사다리)).
	# 능력치 · 기술 고르기는 이 판 후보(같은 등급 인물 — 하야부사 · 경호대 최후의 4인 · 구일화 — 에 맞춤). castle_common 요청 24행
	# 남궁혁: castle_common characters.json 에 기술 책(너클 낀 주먹 카운터)만 있고 등급 칸이 없다 — 등급은 castle_common ranks.json
	# 강함표(strength '외성 하위': 남궁혁) 그대로. 능력치는 이 판 후보(외성 하위 · 너클 카운터 — 기술 쪽)
	"namgunghyuk": {"id": "namgunghyuk", "name": "남궁혁", "rank": "외성 하위", "weapons": ["너클"],
		"stats": {"힘": 76, "속도": 72, "기술": 78, "맷집": 76}, "skills": ["namgung_knuckle_counter", "namgung_knuckle_hook"],
		"src": "등급 = castle_common ranks.json strength(외성 하위) · 무기 = characters.json main(너클) · 능력치는 이 판 후보",
		"provisional": ["stats", "skills"]},
	"sintaejin": {"id": "sintaejin", "name": "신태진", "rank": "준10강", "weapons": ["양손 칼"],
		"stats": {"힘": 70, "속도": 76, "기술": 72, "맷집": 68}, "skills": ["sintaejin_sweep", "sintaejin_second_blade", "sintaejin_pistol"],
		"src": "사용자 2026-11-06 '신태진은 준10강 양손 칼' · 능력치는 이 판 후보(하야부사 준10강 곁 — 쌍칼이라 속도 쪽)",
		"provisional": ["stats", "skills"]},
	"hwangbomincheol": {"id": "hwangbomincheol", "name": "황보민철", "rank": "전국구", "weapons": ["양손 칼"],
		"stats": {"힘": 60, "속도": 62, "기술": 56, "맷집": 62}, "skills": ["hwangbo_face_counter", "hwangbo_bait"],
		"src": "사용자 2026-11-06 '황보민철은 전국구, 양손 칼' · 능력치는 이 판 후보(경호대 최후의 4인 전국구 곁)",
		"provisional": ["stats", "skills"]},
	"iseul": {"id": "iseul", "name": "이슬", "rank": "전국구", "weapons": ["맨손"],
		"stats": {"힘": 70, "속도": 48, "기술": 44, "맷집": 76}, "skills": ["iseul_throw", "iseul_double_slam"],
		"src": "사용자 2026-11-06 '이슬은 전국구 맨손' · 능력치는 이 판 후보(180cm 100kg 거구 — castle_common looks.json build · 구일화 전국구 곁)",
		"provisional": ["stats", "skills"]},
	"ojiin": {"id": "ojiin", "name": "오지인", "rank": "경호대급", "weapons": ["긴 칼"],
		"stats": {"힘": 54, "속도": 56, "기술": 52, "맷집": 52}, "skills": ["ojiin_skirt_dagger"],
		"src": "사용자 2026-11-06 '오지인 전국구 아래급에 긴 칼' · 능력치는 이 판 후보",
		"provisional": ["stats", "skills"]},
	"kimjaehoon": {"id": "kimjaehoon", "name": "김재훈", "rank": "건달급", "weapons": ["맨손"],
		"stats": {"힘": 36, "속도": 40, "기술": 28, "맷집": 38}, "skills": [],
		"src": "사용자 2026-11-06 '김재훈은 최하위, 맨손' · 능력치는 이 판 후보",
		"provisional": ["stats"]},
	# 2장 엑스트라(원작 fight:haseong_lobby '하성 조직원(검은 정장)' · fight:gyeonghotim '대표실 앞 특별 경호팀' · '남구청년회 사람들')
	"haseong_suit": {"id": "haseong_suit", "name": "하성 조직원", "rank": "건달급", "weapons": ["맨손", "칼"],
		"stats": {"힘": 44, "속도": 44, "기술": 34, "맷집": 44}, "skills": [],
		"src": "3D 덧붙임 엑스트라(원작 fight:haseong_lobby 하성 로비 부하 · 검은 정장 p1:024-028)",
		"provisional": ["rank", "stats"]},
	"haseong_guard": {"id": "haseong_guard", "name": "특별 경호팀", "rank": "경호대급", "weapons": ["맨손", "칼"],
		"stats": {"힘": 50, "속도": 50, "기술": 42, "맷집": 50}, "skills": [],
		"src": "3D 덧붙임 엑스트라(원작 fight:gyeonghotim 대표실 앞 특별 경호팀 p1:025-026)",
		"provisional": ["rank", "stats"]},
	# 3 ~ 13장 엑스트라(2026-11-08) — 이름 없는 무리 다섯 갈래. 방 표 덧붙임(look · name · ai)으로 장마다 옷 · 이름을 바꾼다
	# (교도소 재소자 · 부산 조직원 · 화진 습격조 · 야쿠자 · 교회 경호대 …). 등급은 무리의 대표값(장 표 NPCS 로 덮을 수 있다)
	"street_thug": {"id": "street_thug", "name": "건달", "rank": "건달급", "weapons": ["맨손", "몽둥이"],
		"stats": {"힘": 44, "속도": 44, "기술": 34, "맷집": 44}, "skills": [], "src": "3D 덧붙임 엑스트라(3 ~ 13장 무리)", "provisional": ["rank", "stats"]},
	"gang_blade": {"id": "gang_blade", "name": "칼잡이", "rank": "조장급", "weapons": ["칼"],
		"stats": {"힘": 50, "속도": 52, "기술": 44, "맷집": 48}, "skills": [], "src": "3D 덧붙임 엑스트라(3 ~ 13장 무리)", "provisional": ["rank", "stats"]},
	"gang_brute": {"id": "gang_brute", "name": "거구", "rank": "조장급", "weapons": ["맨손"],
		"stats": {"힘": 60, "속도": 40, "기술": 36, "맷집": 60}, "skills": [], "src": "3D 덧붙임 엑스트라(3 ~ 13장 무리)", "provisional": ["rank", "stats"]},
	# 불휘 가면 둘(fight:bulhwi p1:044 others '하회탈 가면(흰 셔츠)' · '붉은 점 가면(민소매)' — 이름 없는 불휘 단원, 2026-11-12 사용자 "전국구급")
	"hahoe_mask": {"id": "hahoe_mask", "name": "하회탈 가면", "rank": "전국구", "weapons": ["맨손"],
		"stats": {"힘": 62, "속도": 64, "기술": 60, "맷집": 60}, "skills": [], "src": "3D 덧붙임(원작 fight:bulhwi others)", "provisional": ["rank", "stats"]},
	"redspot_mask": {"id": "redspot_mask", "name": "붉은 점 가면", "rank": "전국구", "weapons": ["맨손"],
		"stats": {"힘": 60, "속도": 68, "기술": 58, "맷집": 58}, "skills": [], "src": "3D 덧붙임(원작 fight:bulhwi others)", "provisional": ["rank", "stats"]},
	"pro_fighter": {"id": "pro_fighter", "name": "격투가", "rank": "네임드", "weapons": ["맨손"],
		"stats": {"힘": 58, "속도": 60, "기술": 56, "맷집": 58}, "skills": [], "src": "3D 덧붙임 엑스트라(3 ~ 13장 — 케이지 · 이스크라 · 사천왕 부하)", "provisional": ["rank", "stats"]},
	"elite_guard": {"id": "elite_guard", "name": "경호대", "rank": "경호대급", "weapons": ["맨손", "칼", "총"],
		"stats": {"힘": 64, "속도": 62, "기술": 60, "맷집": 62}, "skills": [], "src": "3D 덧붙임 엑스트라(3 ~ 13장 — 캐슬 경호대 · 교회전)", "provisional": ["rank", "stats"]},
	"namgu_youth": {"id": "namgu_youth", "name": "남구청년회", "rank": "건달급", "weapons": ["맨손"],
		"stats": {"힘": 42, "속도": 44, "기술": 32, "맷집": 44}, "skills": [],
		"src": "3D 덧붙임 엑스트라(원작 fight:haseong_lobby 남구청년회 사람들 — 서진태 쪽 p1:024-028)",
		"provisional": ["rank", "stats"]},
}

## 기술(1층 정체) — from: 하향의 원본 기술 · refs: 원작 화/컷
const SKILLS := {
	# 자유로운 영혼 팀(10장 산 기슭 — 원작 054 ~ 055)
	"condor_volley": {"id": "condor_volley", "name": "소음 쌍권총 연사", "owner": "condor", "move": "cd_twin",
		"desc": "소음기 쌍권총을 앞으로 내밀어 번갈아 연사한다(두두두)", "refs": ["054/061-062"]},
	"condor_ambush": {"id": "condor_ambush", "name": "벽 뒤 쌍권총 매복", "owner": "condor", "move": "cd_ambush",
		"desc": "벽 뒤에 숨었다가 '가라' — 뛰어나오며 쌍권총을 퍼붓는다", "refs": ["055/028-032"]},
	"heron_snipe": {"id": "heron_snipe", "name": "스코프 저격", "owner": "heron", "move": "hr_snipe",
		"desc": "멀리서 조준선을 긋고 한 발 — 옆구리를 관통해 넘어뜨린다", "refs": ["054/032"]},
	"heron_triple": {"id": "heron_triple", "name": "저격 3연사", "owner": "heron", "move": "hr_triple",
		"desc": "저격 소총 세 발을 이어 몸통에 박는다", "refs": ["055/014-016"]},
	"owl_smoke": {"id": "owl_smoke", "name": "연막 표식", "owner": "owl", "move": "ow_smoke",
		"desc": "핀을 뽑아 보라 연막을 던져 좌표를 찍는다 — 맞으면 체간이 크게 흔들린다", "refs": ["054/024-025"]},
	"owl_grenade": {"id": "owl_grenade", "name": "수류탄", "owner": "owl", "move": "ow_grenade",
		"desc": "수류탄을 굴려 넣어 터뜨린다 — 넓게 넘어뜨린다", "refs": ["055/011-014"]},
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
	# ---- 2장 하성 본사(S5 묶음 4) — 원작 판독(castle_common canon fights · episodes moves, conf ai)에서 고른 1층 후보.
	# 이름 · 고르기는 이 판 후보(castle_common 에 올릴지는 사용자 — 요청 24행 곁). 동작(3층)은 moves.gd
	"namgung_knuckle_counter": {"id": "namgung_knuckle_counter", "name": "너클 낀 주먹 카운터", "owner": "namgunghyuk", "move": "ng_counter",
		"desc": "낮춰 파고들거나 몸을 젖혀 주먹을 흘린 뒤 너클 낀 주먹으로 맞받는다(castle_common characters.json book 의 이름)",
		"refs": ["024", "025", "028/088-089"]},
	"namgung_knuckle_hook": {"id": "namgung_knuckle_hook", "name": "너클 훅", "owner": "namgunghyuk", "move": "ng_hook",
		"desc": "오른 주먹을 크게 젖혔다가 둥근 궤적으로 휩쓰는 너클 훅", "refs": ["029/117-118", "030/010"]},
	"sintaejin_sweep": {"id": "sintaejin_sweep", "name": "장도 수평 베기", "owner": "sintaejin", "move": "st_sweep",
		"desc": "두 손으로 쥔 장도를 어깨 높이에서 수평으로 크게 휘두른다", "refs": ["031/112-114"]},
	"sintaejin_second_blade": {"id": "sintaejin_second_blade", "name": "숨긴 두 번째 칼", "owner": "sintaejin", "move": "st_second",
		"desc": "얼굴 찌르기 · 수평 베기로 시선을 끈 뒤 허리 뒤 가로 칼집의 칼을 왼손으로 뽑아 찌른다 — 못 막는다", "refs": ["032/032-038"]},
	"sintaejin_pistol": {"id": "sintaejin_pistol", "name": "코앞 권총", "owner": "sintaejin", "move": "st_pistol",
		"desc": "칼과 다른 손의 권총을 코앞에서 겨눠 쏜다 — 못 막는다(구른다)", "refs": ["031/106-119", "032/054-057"]},
	"hwangbo_face_counter": {"id": "hwangbo_face_counter", "name": "얼굴 스치기 베기", "owner": "hwangbomincheol", "move": "hb_face",
		"desc": "돌진해 오는 상대에게 맞받아 오른손 칼로 얼굴 높이를 가로로 벤다", "refs": ["026/004-005"]},
	"hwangbo_bait": {"id": "hwangbo_bait", "name": "왼다리 미끼 찌르기", "owner": "hwangbomincheol", "move": "hb_bait",
		"desc": "다친 왼다리로 중심이 무너지는 척 끌어들이고 파고드는 순간 찌른다('그대로 시마이!') — 읽히면 크게 빈다", "refs": ["027/172-178"]},
	"iseul_throw": {"id": "iseul_throw", "name": "붙잡아 후려 날리기", "owner": "iseul", "move": "s_is_throw",
		"desc": "상대를 마주 붙잡고 오른팔을 크게 휘둘러 후려쳐 날려 보낸다('으라아앗!')", "refs": ["026/000-001"]},
	"iseul_double_slam": {"id": "iseul_double_slam", "name": "양팔 머리 낚아채 메다꽂기", "owner": "iseul", "move": "s_is_slam",
		"desc": "좌우에서 들어오는 둘의 머리를 양팔로 동시에 감아 쥐고 바닥에 내리꽂는다", "refs": ["028/065-069"]},
	"ojiin_skirt_dagger": {"id": "ojiin_skirt_dagger", "name": "치마 뒤 단검", "owner": "ojiin", "move": "oj_dagger",
		"desc": "치마 뒤에 숨긴 단검으로 등 뒤를 기습한다 — 원작은 떠올리기만 하고 김신의 눈길에 멈춘다(상상 컷)", "refs": ["026/053-056"]},
}


static func _has_common(id: String) -> bool:
	for c in Common._j("characters")["characters"]:
		if c["id"] == id:
			return true
	return false


## 인물 — castle_common 에 있으면 그 값이 먼저, 빈 칸(skills [] · 모르는 능력치)만 여기서 채운다.
## 둘 다에 없는 인물(3 ~ 13장의 이름 있는 적 — 바실리 · 구스타프 …)은 castle_common 2층에서 이름(looks.json name) · 등급(ranks.json
## strength_ref — 조건 없는 줄이 먼저)만 채운다. 능력치는 빈 표(= 기준 80, 1배)라 손맛은 장 표 ROLES(hp · dmg_k)가 정한다
static func character(id: String) -> Dictionary:
	var out: Dictionary = CHARACTERS.get(id, {}).duplicate(true)
	if out.is_empty() and not _has_common(id):
		return canon_fallback(id)
	out = _with_common(id, out)
	if str(out.get("rank", "")) in ["", "<null>"] or out.get("rank") == null:   # castle_common 에 이름만 있는 인물(표영 · 리천 · 마학영 …)
		out["rank"] = str(canon_fallback(id).get("rank", "건달급"))
	if not out.get("stats") is Dictionary:
		out["stats"] = {}
	return out


## 1층 표에 없는 인물 — 이름 · 등급만(없으면 빈 표). 장 표 NPCS 가 등급 · 능력치를 덮을 수 있다(stage._npc)
static func canon_fallback(id: String) -> Dictionary:
	var name := ""
	for lk in Common._j("looks").get("looks", []):
		if str(lk.get("id", "")) == id:
			name = str(lk.get("name", ""))
			break
	var rank := ""
	var any := ""
	for r in Common._j("ranks").get("strength_ref", []):
		if str(r.get("char", "")) != id:
			continue
		if any == "":
			any = str(r["rank"])
		if not r.has("cond"):
			rank = str(r["rank"])
			break
	if rank == "":
		rank = any
	if name == "" and rank == "":
		return {}
	if rank == "":
		rank = "건달급"
	# 능력치는 기술(막는 확률 — derive guard)만 등급으로(건달급 40 → 한 등급마다 +3, 톱 79). 힘 · 맷집 · 속도는 기준 80(1배) —
	# 손맛은 장 표 ROLES(hp · dmg_k)가 정한다
	var idx: int = maxi(0, Common.ranks().find(rank))
	return {"id": id, "name": name if name != "" else id, "rank": rank, "stats": {"기술": 40 + idx * 3}, "skills": [],
		"can_parry": false, "src": "1층 없음 — castle_common looks.json 이름 · ranks.json 강함표 등급(3 ~ 13장, 3D)"}


static func _with_common(id: String, out: Dictionary) -> Dictionary:
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
