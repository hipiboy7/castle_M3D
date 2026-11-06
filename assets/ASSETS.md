# 자산 출처 목록 — castle M 3D 초안

> 정정 이력: 2026-11-05 — 첫 작성(S1 · 개발 규격 `게임개발규격.md` 6절). `scripts/verify.py` '자산 출처' 줄이 `assets/` 의 파일(`.import` 빼고)과 이 표의 첫 칸을 맞춰 본다 — 새 자산을 넣으면 여기 한 줄.

- 원작 컷 · 원작 그림을 쓴 자산은 **없다**(인물 · 무대는 코드로 만든 3D 관절 인형 · 도형 — `src/view/`)
- 효과음 · 음악은 castle_M 이 절차 생성한 파일을 그대로 가져왔다(castle_M `tools/gen_sfx.py` · `tools/gen_music.py` + `tools/synth.py` · `tools/music.py`, 처음 출처는 캐슬 취호전 v1.4.1 — castle_M `6da1bb0`). 다시 만들려면 castle_M 에서 그 도구를 돌려 복사한다. 이 판으로 가져온 커밋 `b57db00`(2026-10-26, castle_M `c8fc86c` 무렵)
- 외부 자산은 글꼴 하나 — 배포 허용(SIL OFL 1.1)

| 파일 (`assets/` 기준) | 출처 | 쓰는 곳 |
|---|---|---|
| `fonts/Galmuri11-Bold.ttf` | 외부 — Galmuri(Lee Minseo, quiple) · SIL Open Font License 1.1 · https://github.com/quiple/galmuri | 화면 글자 전부(`project.godot` `gui/theme/custom_font`) |
| `fonts/LICENSE.txt` | 위 글꼴의 라이선스 원문 | — |
| `sfx/counter.wav` | 직접(절차 생성) — castle_M `tools/gen_sfx.py` | 반격 베기 (`src/main.gd` `_play`) |
| `sfx/fall.wav` | 직접(절차 생성) — castle_M `tools/gen_sfx.py` | 넘어짐 (`src/main.gd` `_play`) |
| `sfx/guard.wav` | 직접(절차 생성) — castle_M `tools/gen_sfx.py` | 막기 (`src/main.gd` `_play`) |
| `sfx/hit.wav` | 직접(절차 생성) — castle_M `tools/gen_sfx.py` | 맞음 (`src/main.gd` `_play`) |
| `sfx/hit_heavy.wav` | 직접(절차 생성) — castle_M `tools/gen_sfx.py` | 세게 맞음 (`src/main.gd` `_play`) |
| `sfx/kick.wav` | 직접(절차 생성) — castle_M `tools/gen_sfx.py` | 발차기 · 옆차기 (`src/main.gd` `_play`) |
| `sfx/knife.wav` | 직접(절차 생성) — castle_M `tools/gen_sfx.py` | 사시미 · 엇박 계열 (`src/main.gd` `_play`) |
| `sfx/ko.wav` | 직접(절차 생성) — castle_M `tools/gen_sfx.py` | 쓰러뜨림 (`src/main.gd` `_play`) |
| `sfx/miss.wav` | 직접(절차 생성) — castle_M `tools/gen_sfx.py` | 헛침 (`src/main.gd` `_play`) |
| `sfx/shine.wav` | 직접(절차 생성) — castle_M `tools/gen_sfx.py` | 예고 · 습득 · 연출 (`src/main.gd` `_play`) |
| `sfx/shot.wav` | 직접(절차 생성) — 이 저장소 `tools/gen_sfx.py` (2026-11-06) | 근거리 사격 (경호대 최후의 4인 `t_shot` — `src/view/sound.gd`) |
| `sfx/slash.wav` | 직접(절차 생성) — castle_M `tools/gen_sfx.py` | 베기 · 찌르기 (`src/main.gd` `_play`) |
| `sfx/step.wav` | 직접(절차 생성) — castle_M `tools/gen_sfx.py` | 걸음 (`src/main.gd` `_play`) |
| `sfx/swing.wav` | 직접(절차 생성) — castle_M `tools/gen_sfx.py` | 휘두름 (`src/main.gd` `_play`) |
| `sfx/wind.wav` | 직접(절차 생성) — castle_M `tools/gen_sfx.py` | 큰 동작 · 연출 (`src/main.gd` `_play`) |
| `music/boss.ogg` | 직접(절차 생성) — castle_M `tools/gen_music.py` | 결투 (`src/main.gd` `_music`) |
| `music/gameover.ogg` | 직접(절차 생성) — castle_M `tools/gen_music.py` | 짐 (`src/main.gd` `_music`) |
| `music/victory.ogg` | 직접(절차 생성) — castle_M `tools/gen_music.py` | 이김 (`src/main.gd` `_music`) |
| `models/kimshin_a.glb` | 직접(스크립트 생성) — `tools/make_models.gd` (2026-11-06, 외형은 castle_common canon look 글 — conf ai) | 그림 A 김신 (`src/view/puppet_glb.gd`, `--art a`) |
| `models/shingen_a.glb` | 직접(스크립트 생성) — `tools/make_models.gd` (2026-11-06, 〃) | 그림 A 사사키 신겐 |
| `sprites/kimshin_b.png` | 직접(스크립트 생성) — `tools/make_sprites.gd` 가 `models/kimshin_a.glb` 를 8방향으로 그려 도트로 줄임 | 그림 B 김신 (`src/view/puppet_dot.gd`, `--art b`) |
| `sprites/kimshin_b.json` | 〃 — 도트 시트 칸 이름 · 크기 | 그림 B 김신 |
| `sprites/shingen_b.png` | 직접(스크립트 생성) — `tools/make_sprites.gd` (`models/shingen_a.glb`) | 그림 B 사사키 신겐 |
| `sprites/shingen_b.json` | 〃 | 그림 B 사사키 신겐 |
| `models/kimshin_p1_a.glb` | 직접(스크립트 생성) — `tools/make_models.gd` (2026-11-06, 외형은 castle_common canon look · looks_by_period 글 — conf ai, `src/view/looks.gd` 주석) | 그림 A 김신 1부 처음(터틀넥 · 맨손 — 0 · 1장) |
| `models/gunter_a.glb` | 〃 | 그림 A 군터(0장) |
| `models/jintae_a.glb` | 〃 | 그림 A 서진태(1장) |
| `models/kimhyeokju_a.glb` | 〃 | 그림 A 김혁주(1장) |
| `models/kimseongjun_a.glb` | 〃 | 그림 A 김성준(1장) |
| `models/kimdaegeon_a.glb` | 〃 | 그림 A 김대건(1장) |
| `models/gangmanjae_a.glb` | 〃 | 그림 A 강만재(1장) |
| `models/yundeoksu_a.glb` | 〃 | 그림 A 윤덕수(1장) |
| `sprites/kimshin_p1_b.png` | 직접(스크립트 생성) — `tools/make_sprites.gd` (`models/kimshin_p1_a.glb`) | 그림 B 김신 1부 처음 |
| `sprites/kimshin_p1_b.json` | 〃 | 그림 B 김신 1부 처음 |
| `sprites/gunter_b.png` | 직접(스크립트 생성) — `tools/make_sprites.gd` (`models/gunter_a.glb`) | 그림 B 군터 |
| `sprites/gunter_b.json` | 〃 | 그림 B 군터 |
| `sprites/jintae_b.png` | 직접(스크립트 생성) — `tools/make_sprites.gd` (`models/jintae_a.glb`) | 그림 B 서진태 |
| `sprites/jintae_b.json` | 〃 | 그림 B 서진태 |
| `sprites/kimhyeokju_b.png` | 직접(스크립트 생성) — `tools/make_sprites.gd` (`models/kimhyeokju_a.glb`) | 그림 B 김혁주 |
| `sprites/kimhyeokju_b.json` | 〃 | 그림 B 김혁주 |
| `sprites/kimseongjun_b.png` | 직접(스크립트 생성) — `tools/make_sprites.gd` (`models/kimseongjun_a.glb`) | 그림 B 김성준 |
| `sprites/kimseongjun_b.json` | 〃 | 그림 B 김성준 |
| `sprites/kimdaegeon_b.png` | 직접(스크립트 생성) — `tools/make_sprites.gd` (`models/kimdaegeon_a.glb`) | 그림 B 김대건 |
| `sprites/kimdaegeon_b.json` | 〃 | 그림 B 김대건 |
| `sprites/gangmanjae_b.png` | 직접(스크립트 생성) — `tools/make_sprites.gd` (`models/gangmanjae_a.glb`) | 그림 B 강만재 |
| `sprites/gangmanjae_b.json` | 〃 | 그림 B 강만재 |
| `sprites/yundeoksu_b.png` | 직접(스크립트 생성) — `tools/make_sprites.gd` (`models/yundeoksu_a.glb`) | 그림 B 윤덕수 |
| `sprites/yundeoksu_b.json` | 〃 | 그림 B 윤덕수 |
| `models/sintaejin_a.glb` | 직접(스크립트 생성) — `tools/make_models.gd` (2026-11-06, 외형은 castle_common `data/looks.json` ddeeb4c — 원작 조각 대조 · conf ai, `src/view/looks.gd` 주석) | 그림 A 신태진(2장) |
| `models/namgunghyuk_a.glb` | 〃 | 그림 A 남궁혁(2장) |
| `models/hwangbomincheol_a.glb` | 〃 | 그림 A 황보민철(2장) |
| `models/iseul_a.glb` | 〃 | 그림 A 이슬(2장) |
| `models/ojiin_a.glb` | 〃 | 그림 A 오지인(2장) |
| `models/kimjaehoon_a.glb` | 〃 | 그림 A 김재훈(2장) |
| `models/insu_a.glb` | 〃 | 그림 A 인수(2장) |
| `models/gangchangseok_a.glb` | 〃 | 그림 A 강창석(2장) |
| `sprites/sintaejin_b.png` | 직접(스크립트 생성) — `tools/make_sprites.gd` (`models/sintaejin_a.glb`) | 그림 B 신태진 |
| `sprites/sintaejin_b.json` | 〃 | 그림 B 신태진 |
| `sprites/namgunghyuk_b.png` | 직접(스크립트 생성) — `tools/make_sprites.gd` (`models/namgunghyuk_a.glb`) | 그림 B 남궁혁 |
| `sprites/namgunghyuk_b.json` | 〃 | 그림 B 남궁혁 |
| `sprites/hwangbomincheol_b.png` | 직접(스크립트 생성) — `tools/make_sprites.gd` (`models/hwangbomincheol_a.glb`) | 그림 B 황보민철 |
| `sprites/hwangbomincheol_b.json` | 〃 | 그림 B 황보민철 |
| `sprites/iseul_b.png` | 직접(스크립트 생성) — `tools/make_sprites.gd` (`models/iseul_a.glb`) | 그림 B 이슬 |
| `sprites/iseul_b.json` | 〃 | 그림 B 이슬 |
| `sprites/ojiin_b.png` | 직접(스크립트 생성) — `tools/make_sprites.gd` (`models/ojiin_a.glb`) | 그림 B 오지인 |
| `sprites/ojiin_b.json` | 〃 | 그림 B 오지인 |
| `sprites/kimjaehoon_b.png` | 직접(스크립트 생성) — `tools/make_sprites.gd` (`models/kimjaehoon_a.glb`) | 그림 B 김재훈 |
| `sprites/kimjaehoon_b.json` | 〃 | 그림 B 김재훈 |
| `sprites/insu_b.png` | 직접(스크립트 생성) — `tools/make_sprites.gd` (`models/insu_a.glb`) | 그림 B 인수 |
| `sprites/insu_b.json` | 〃 | 그림 B 인수 |
| `sprites/gangchangseok_b.png` | 직접(스크립트 생성) — `tools/make_sprites.gd` (`models/gangchangseok_a.glb`) | 그림 B 강창석 |
| `sprites/gangchangseok_b.json` | 〃 | 그림 B 강창석 |
| `sprites/kimshin_p1_blade_b.png` | 직접(스크립트 생성) — `tools/make_sprites.gd` (`models/kimshin_p1_a.glb` + 군용 단검) | 그림 B 김신 2장(1부 차림 · 칼) |
| `sprites/kimshin_p1_blade_b.json` | 〃 | 그림 B 김신 2장 |
