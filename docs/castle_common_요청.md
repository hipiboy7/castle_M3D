# castle_common 요청 — castle M 3D → castle_common (누적)

> 정정 이력: 2026-11-05 — S1 공통 받기 뒤: 11행 확인 결과 · 13행 반영 현황 채움, 5행 castle_common `0ff47f5a`(규격 이름 `P{N}_요구사항정의서`) 메모.
> 정정 이력: 2026-11-04 — 첫 작성(S0 조사 · `docs/기획_차이.md`). 양식은 castle_common `docs/개발규격/캐슬_게임공통.md` 3절. castle_common 이 반영하면 그 줄을 지운다.

- 넘기는 법: 이 파일 내용을 castle_common 세션에 붙여 넣는다(같은 PC 면 경로 `../castle_M3D/docs/castle_common_요청.md` 만 알려 줘도 된다)
- 원작 위치가 있는 줄은 없다 — 모두 데이터 칸 · 문서 · 규격 줄이라 `파일:id` 순
- 2층 수치는 '바랄 값'에 후보만 적었다 — 확정은 사용자다

| # | 위치 | 파일:id | 칸 | 지금 값 | 바랄 값 | 근거 | 급함 |
|---|---|---|---|---|---|---|---|
| 1 | - | `data/skills.json:offbeat` | `effects.stun_rel_sec` | (없음) | 후보 `[1.5, 1.0]` — **사용자가 "공통으로"라고 정할 때만** | 3D 폰 리뷰 3차(2026-10-27) 사용자 원문 "그래서 당했을 때 맞은 상대는 스턴 상태로 빠져야해" → 3D 에서 먼저 시험(`src/data/moves.gd` `s_offbeat` `stun_rel` [90, 60] 프레임) | 언젠가 |
| 2 | - | `data/skills.json:offbeat2` | `effects.stun_rel_sec` | (없음) | 후보 `[2.0, 1.5]` — 1과 같음 | 3D 폰 리뷰 3차 · `s_offbeat2` [120, 90] | 언젠가 |
| 3 | - | `data/skills.json:offbeat_rev` | `effects.stun_rel_sec` | (없음) | 후보 `[0.67, 0.4]` — 1과 같음 | 3D 폰 리뷰 3차 "상대 스턴도 적고" · `s_offbeat_rev` [40, 24] | 언젠가 |
| 4 | - | `data/skills.json:triple` | `effects` 기절(셋째 대만) | (없음) | 후보 셋째 대 `[1.5, 0.5]` — 칸 이름(예: `stun_rel_sec` + `stun_hit: 3`)은 castle_common 이 정한다. 1과 같음 | 3D 폰 리뷰 2차(2026-10-26) "삼연타 맞고도 각법보다 1/2 정도 스턴 하자" · `s_triple` [90, 30] | 언젠가 |
| 5 | - | `docs/개발규격/게임개발규격.md` 3절 | 산출물 파일 이름 | `docs/P{N}_계획_<Topic>.md` · 그러나 2절 "이름 · 번호는 기획서를 따른다" | 둘 중 하나로 — 기획서 마일스톤이 `S0 ~ S6` · `M0 ~ M6` 인 판에서 `P{N}` 을 쓸지 `S{N}` 을 쓸지 | 이 판은 이미 `P1_*`(3D 초안) 3장이 있고 다음이 S1 이다 — 이름이 갈린다. 2026-11-04 사용자는 `S1_계획` · `S1_테스트결과서` 로 정함. 그 뒤 castle_common `0ff47f5a` 가 규격 이름을 `P{N}_요구사항정의서_<Topic>.md` 로 바꿈 — 이 판은 사용자 답대로 두고 맞출지 다시 묻는다 | 다음 마일스톤 |
| 6 | - | `docs/개발규격/게임개발규격.md` 7절 | 서명 키 | "서명 키(keystore)는 커밋하지 않는다" | (사용자가 '유지'로 정하면) "고정 **디버그** 키는 비공개 저장소에 커밋해도 된다 — release 키만 Secrets" 예외 한 줄 | 이 판 · castle_M 이 `android/debug.keystore` 를 의도적으로 커밋(CLAUDE.md 0절) — CI 가 만든 APK 를 폰에 덮어 설치하려면 같은 키여야 한다 | 다음 마일스톤 |
| 7 | - | `docs/개발규격/캐슬_게임공통.md` 4절 | castle M 3D 줄 엔진 | Godot 4(초안) | Godot 4.7.2-stable · Compatibility 렌더러 | 이 판 CLAUDE.md 0절 · `project.godot` | 언젠가 |
| 8 | - | `docs/기획서/03_castle_M3D_3D탑뷰.md` 1절 | 어긋남 ② 설명 | "김신 등급을 내성 상위로 박음(원작은 처음 내성 중위 → 구스타프 이긴 뒤 내성 상위)" | "6장 백도찬전 시점은 진행으로도 내성 상위라 **값은 맞다** — 진행에서 끌어내지 않고 박아 둔 것이 문제" | `ref/rules.py` `progress("kimshin", events_until(4))` = 내성 상위(2026-11-04) · castle_M `DUELS["baekdochan"].hero_events` = `beat:gustav` · `beat:komodo` | 언젠가 |
| 9 | - | `docs/기획서/03_castle_M3D_3D탑뷰.md` 1절 | 어긋남 목록 | ①②③ | ④ 게이지 배율 절반 — `skills.gd` 2.494 ↔ 공통 `gauge_rate(내성 상위, 95)` 4.988(`fast_rank_k` 2배 빠짐) · ⑤ 얻는 양 `dodge` · `ko` 없음 을 더함 | `docs/기획_차이.md` 4절 · castle_M `roster.py:51` 에는 2배가 있다 | 다음 마일스톤 |
| 10 | - | `docs/설계서_공통데이터.md` 1절 | castle M 3D 줄 '이미 어긋남' | 8 · 9 와 같은 문장 | 8 · 9 와 같게 | 〃 | 언젠가 |
| 11 | - | `docs/세션인계.md` '확인된 것' · `CHANGELOG.md` · 기획서 03 1절 | `strength_ref` 를 castle_M3D 가 무시하나 | 미확인 | **확인됨 — 무시한다**: castle_M3D `src/data/common.gd` 는 `ranks.json` 의 `ladder` 만 읽는다(`strength` · `strength_ref` 를 읽지 않음, 모르는 칸이 있어도 오류 없음) | 시험 `tests/test_common_cases.gd` `test_ranks_ignores_unknown_fields`(2026-11-05 통과 · castle_common `8a6acfc` 받음) | 다음 마일스톤 |
| 12 | - | `rules/기술.md` 2 · 3절 | 엇엇박 > 엇박 | (없음) | (사용자가 "공통으로"라고 정할 때만) "엇박 · 반대발 엇박이 엇엇박을 쓰는 중인 상대에게 닿으면 닿지 않은 것으로 한다 — 엇엇박이 이긴다" | 3D 폰 리뷰 3차 원문 "엇박과 엇엇박 기술이 서로 부딪히면 엇엇박이 무조건 이겨" · `src/combat/world.gd:160` | 언젠가 |
| 13 | - | `rules/기술.md` · `rules/등급과_게이지.md` 5절 · `README.md` 받는 판 표 | castle M 3D 반영 현황 | 할 일 | castle M 3D: **castle_common `8a6acfc` 받음**(`data/` · `cases/` 는 `c7ba55cd` 와 같다) · 규칙 함수 13개 cases 1,464줄 통과 · 손 복사 값 제거 · 등급 차 강함 · 진행으로 등급 · 비용 공식 · 게이지 배율 4.988 · 얻는 양 dodge · ko · 즉사 구간 · stun_rank 반영 — S1 커밋(`docs/S1_테스트결과서_공통받기.md` 머리). 3D 덧붙임(1 ~ 4 · 12행)은 반영 아님 | 캐슬_게임공통 2절 4항 | 다음 마일스톤 |
