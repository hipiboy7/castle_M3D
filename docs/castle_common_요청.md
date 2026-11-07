# castle_common 요청 — castle M 3D → castle_common (누적)

> 정정 이력: 2026-11-08 — 23 · 24행 지움(castle_common 79 · 80차 반영 — looks.json · 2장 인물 5 · 남궁혁 rank), 25 · 26행 더함(rc.2 폰 피드백 묶음 B — 사용자 2026-11-07).
> 정정 이력: 2026-11-06 — 1 ~ 4 · 12 · 20 ~ 22행 지움(castle_common 72차가 직접 — `b7e1065`: 기절 `stun_rel_sec` 넷 · `stun_hit` · `beats` 공통(사용자 답58 #5 '공통으로') · 기획서 00 결정 7 · 03 S5 · games.json 이 판 canon 받기 · `data/characters.json` 0 · 1장 인물 7). 23행(looks)은 castle_common 이 받아 진행 중.
> 정정 이력: 2026-11-06 — 8 · 9 · 10 · 11 · 13 · 15행 지움(castle_common `92cdd4b` 반영 — `docs/하류요청_반영_2026-11-06.md`), 16 ~ 19행 더함(11장 1층 — 사용자 답 2026-11-06).
> 정정 이력: 2026-11-05 (2) — 5 · 6 · 7행 지움: castle_common `ab9c8551`(답45 규격 확정)이 반영 — 문서 머리 `<마일스톤 id>_요구사항정의서`(5) · 디버그 키 커밋 유지 가능(6) · 4절 엔진 칸(7). 번호는 그대로 둔다(다른 문서가 1 ~ 4 · 8 ~ 13행을 가리킨다).
> 정정 이력: 2026-11-05 — S1 공통 받기 뒤: 11행 확인 결과 · 13행 반영 현황 채움, 5행 castle_common `0ff47f5a`(규격 이름 `P{N}_요구사항정의서`) 메모.
> 정정 이력: 2026-11-04 — 첫 작성(S0 조사 · `docs/기획_차이.md`). 양식은 castle_common `docs/개발규격/캐슬_게임공통.md` 3절. castle_common 이 반영하면 그 줄을 지운다.

- 넘기는 법: 이 파일 내용을 castle_common 세션에 붙여 넣는다(같은 PC 면 경로 `../castle_M_3D/docs/castle_common_요청.md` 만 알려 줘도 된다 — 2026-11-06 폴더 이름이 `castle_M3D` → `castle_M_3D`)
- 원작 위치가 있는 줄은 없다 — 모두 데이터 칸 · 문서 · 규격 줄이라 `파일:id` 순
- 2층 수치는 '바랄 값'에 후보만 적었다 — 확정은 사용자다

| # | 위치 | 파일:id | 칸 | 지금 값 | 바랄 값 | 근거 | 급함 |
|---|---|---|---|---|---|---|---|
| 25 | - | `data/skills.json`:amur_triple · amur_dash · amur_weaving · jintae_original · jintae_vital · jintae_storm · woojin_core_counter / `data/characters.json`:kimshin · jintae · woojin skills | 조작 인물 새 기술 1층(이름 · 효과 글) | 없음(김신은 kickarts · vanish_step 만, 서진태 · 피우진은 []) | 이름 · 효과는 이 판 `src/data/addendum.gd` SKILLS 그대로: 아무르 티그로 3연타(하복부 3연타 · 0.5초 기절 · 외성 이상 큰 타격) · 아무르 티그로 대시(낮은 대시 찌르기) · 아무르 티그로 위빙(무적 3대 · 외성 이하 한 방) · 서진태 오리지널(3단 · 외성 하위 이하 한 방) · 근거리 급소 베기 · 서진태 난무(둘레 전부) · 미친 코어 카운터(카운터 · 1초 기절). vanish_step 효과 글에 "내성 중위 이하는 못 막는다 · 두 번 찌르기" | 사용자 2026-11-07(3D rc.2 폰 피드백) — 공통으로 올릴지는 사용자 | 보통 |
| 26 | - | `data/rules.json`:rank_gap | 등급 차 한 방(새 칸 후보 `one_shot_gap`) | 없음(rank_gap 피해 배율 up_max 4.0 까지만) | `one_shot_gap: 5` — 치는 쪽이 5등급 이상 윗급이면 보통 공격도 한 대에(이 판은 조작 인물 · 방의 보스는 뺌 — `src/data/skills.gd` ONE_SHOT_GAP) | 사용자 2026-11-07 "김신은 10강 아래급들은 다 원콤 · 약한 캐릭터들을 팍팍 쓸어버리는 느낌" — 3D 덧붙임, 공통으로 올릴지는 사용자 | 보통 |
