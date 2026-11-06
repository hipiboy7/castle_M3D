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
| `sfx/slash.wav` | 직접(절차 생성) — castle_M `tools/gen_sfx.py` | 베기 · 찌르기 (`src/main.gd` `_play`) |
| `sfx/step.wav` | 직접(절차 생성) — castle_M `tools/gen_sfx.py` | 걸음 (`src/main.gd` `_play`) |
| `sfx/swing.wav` | 직접(절차 생성) — castle_M `tools/gen_sfx.py` | 휘두름 (`src/main.gd` `_play`) |
| `sfx/wind.wav` | 직접(절차 생성) — castle_M `tools/gen_sfx.py` | 큰 동작 · 연출 (`src/main.gd` `_play`) |
| `music/boss.ogg` | 직접(절차 생성) — castle_M `tools/gen_music.py` | 결투 (`src/main.gd` `_music`) |
| `music/gameover.ogg` | 직접(절차 생성) — castle_M `tools/gen_music.py` | 짐 (`src/main.gd` `_music`) |
| `music/victory.ogg` | 직접(절차 생성) — castle_M `tools/gen_music.py` | 이김 (`src/main.gd` `_music`) |
