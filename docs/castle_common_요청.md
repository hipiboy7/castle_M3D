# castle_common 요청 — castle M 3D → castle_common (누적)

> 정정 이력: 2026-11-06 — 8 · 9 · 10 · 11 · 13 · 15행 지움(castle_common `92cdd4b` 반영 — `docs/하류요청_반영_2026-11-06.md`), 16 ~ 19행 더함(11장 1층 — 사용자 답 2026-11-06).
> 정정 이력: 2026-11-05 (2) — 5 · 6 · 7행 지움: castle_common `ab9c8551`(답45 규격 확정)이 반영 — 문서 머리 `<마일스톤 id>_요구사항정의서`(5) · 디버그 키 커밋 유지 가능(6) · 4절 엔진 칸(7). 번호는 그대로 둔다(다른 문서가 1 ~ 4 · 8 ~ 13행을 가리킨다).
> 정정 이력: 2026-11-05 — S1 공통 받기 뒤: 11행 확인 결과 · 13행 반영 현황 채움, 5행 castle_common `0ff47f5a`(규격 이름 `P{N}_요구사항정의서`) 메모.
> 정정 이력: 2026-11-04 — 첫 작성(S0 조사 · `docs/기획_차이.md`). 양식은 castle_common `docs/개발규격/캐슬_게임공통.md` 3절. castle_common 이 반영하면 그 줄을 지운다.

- 넘기는 법: 이 파일 내용을 castle_common 세션에 붙여 넣는다(같은 PC 면 경로 `../castle_M_3D/docs/castle_common_요청.md` 만 알려 줘도 된다 — 2026-11-06 폴더 이름이 `castle_M3D` → `castle_M_3D`)
- 원작 위치가 있는 줄은 없다 — 모두 데이터 칸 · 문서 · 규격 줄이라 `파일:id` 순
- 2층 수치는 '바랄 값'에 후보만 적었다 — 확정은 사용자다

| # | 위치 | 파일:id | 칸 | 지금 값 | 바랄 값 | 근거 | 급함 |
|---|---|---|---|---|---|---|---|
| 1 | - | `data/skills.json:offbeat` | `effects.stun_rel_sec` | (없음) | 후보 `[1.5, 1.0]` — **사용자가 "공통으로"라고 정할 때만** | 3D 폰 리뷰 3차(2026-10-27) 사용자 원문 "그래서 당했을 때 맞은 상대는 스턴 상태로 빠져야해" → 3D 에서 먼저 시험(`src/data/moves.gd` `s_offbeat` `stun_rel` [90, 60] 프레임) | 언젠가 |
| 2 | - | `data/skills.json:offbeat2` | `effects.stun_rel_sec` | (없음) | 후보 `[2.0, 1.5]` — 1과 같음 | 3D 폰 리뷰 3차 · `s_offbeat2` [120, 90] | 언젠가 |
| 3 | - | `data/skills.json:offbeat_rev` | `effects.stun_rel_sec` | (없음) | 후보 `[0.67, 0.4]` — 1과 같음 | 3D 폰 리뷰 3차 "상대 스턴도 적고" · `s_offbeat_rev` [40, 24] | 언젠가 |
| 4 | - | `data/skills.json:triple` | `effects` 기절(셋째 대만) | (없음) | 후보 셋째 대 `[1.5, 0.5]` — 칸 이름(예: `stun_rel_sec` + `stun_hit: 3`)은 castle_common 이 정한다. 1과 같음 | 3D 폰 리뷰 2차(2026-10-26) "삼연타 맞고도 각법보다 1/2 정도 스턴 하자" · `s_triple` [90, 30] | 언젠가 |
| 12 | - | `rules/기술.md` 2 · 3절 | 엇엇박 > 엇박 | (없음) | (사용자가 "공통으로"라고 정할 때만) "엇박 · 반대발 엇박이 엇엇박을 쓰는 중인 상대에게 닿으면 닿지 않은 것으로 한다 — 엇엇박이 이긴다" | 3D 폰 리뷰 3차 원문 "엇박과 엇엇박 기술이 서로 부딪히면 엇엇박이 무조건 이겨" · `src/combat/world.gd:160` | 언젠가 |
| 14 | - | `docs/개발규격/게임개발규격.md` 7절 | 마일스톤 확인 릴리스 | "마일스톤 확인은 프리릴리스(예: `v0.3.0-rc.1`), 배포는 정식 태그" | "폰 확인용 릴리스는 GitHub 앱 → Releases 맨 위(Latest)에서 바로 받게 Latest 로 둘 수 있다(태그 이름은 `-rc.N` 그대로). 본문에 폰에서 할 일(설치 · 1분 경로 · 확인 목록)" — 판이 고르게 한 줄 | 사용자 2026-11-05 "url 치지 않고, github app 들어가서 바로 릴리즈 다운받게 해줘. 그리고 앞으로 폰에서 해야할 것은 모두 github app >release 에서 다운받아 바로 할 수 있게 해줘" → 이 판은 Latest · `docs/폰확인.md`(`android.yml` release 잡) | 다음 마일스톤 |
| 16 | - | `data/characters.json:hayabusa` · `gyeonghodaechoehuui4in` · `guilhwa` (새 줄) | 1층 인물 | (없음) | **사용자 확정**(2026-11-06): 하야부사 준10강 · 긴칼 · 신겐 기술 하향 · 능력치는 신겐을 준10강 수준으로 하향 / 4인 전국구 · 총/칼 · 마준영 기술의 전국구 하향 · 능력치 전국구 / 구일화 (화진 전) 전국구 · (교회 전) 이스크라 평 킬러급 · 주먹/칼 · 기술은 알아서 · 능력치 시기별. 숫자 능력치 · 기술 고르기는 3D 후보 — `src/data/addendum.gd` `CHARACTERS`(값 · provisional 표시) | 사용자 답(3D 세션 2026-11-06) · 원작 `fight:baekui_tower` | 다음 판이 11장을 만들기 전 |
| 17 | - | `data/skills.json` (새 줄 11개) | 1층 기술 | (없음) | 3D 후보: 신겐 `shingen_daegeuk` 대극 큰 호 베기(062 · 098) · `shingen_dive` 낮은 파고들기(062 · 098) · `shingen_frontkick` 앞차기(097 · 099 · 101) · `shingen_leap` 날아차기(101), 하야부사 `hayabusa_arc` · `hayabusa_low`(신겐 기술의 하향 — `from`), 4인 `g4_heelkick` · `g4_chop` · `g4_shot`(마준영 002 · 033 · 045 기술의 하향), 구일화 `guilhwa_headbutt` · `guilhwa_forearm`(057 · 109) — `src/data/addendum.gd` `SKILLS`(desc · refs · from). 비용은 기본 1칸 · effects 없음(기절은 3D stun_3d) | canon/episodes moves 판독 · 사용자 답 | 16 과 같이 |
| 18 | - | `data/characters.json:shingen` | `stats` · `skills` | `{"기술": 85}` · `[]` | 3D 후보 `{"힘": 88, "속도": 80, "기술": 85, "맷집": 90}` · 17 의 신겐 4개 — 하야부사 하향의 기준이라 필요 | 사용자 답 16(신겐을 기준으로 하향) | 16 과 같이 |
| 19 | - | `data/characters.json` 또는 판 쪽 | 이름 없는 경호원(엑스트라) | (없음) | 원작 057 '경호대 정장 8인' 같은 엑스트라를 공통에 둘지(`mobs` 칸이 canon 에 생겼다) — 3D 는 `castle_guard` 경호대급을 임시로 씀 | 3D 11장 28층 | 언젠가 |
