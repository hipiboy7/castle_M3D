# CLAUDE.md — castle M 3D 초안 작업 규칙

「캐슬」 팬게임 castle M 의 **3D 초안**(Godot 4)이다. 폴더 `D:/claude/fun/castle_M_3D`(2026-11-06 — 전 이름 `castle_M3D`), 저장소 · 판 id 는 `castle_M3D`. 목적은 하나 — 엔진 이전(castle_M 보류 결정 #9)을 정할 시험판.
본편은 형제 폴더 `../castle_M`(pygame-ce, 저장소 `hipiboy7/castle_M`). 공통 규칙 · 데이터 · 개발 규격은 `../castle_common`.
**이 폴더에서 Claude Code 를 따로 열어 개발한다** — 3D 일은 이 폴더 세션에서, 2D 본편 일은 castle_M 폴더 세션에서(2026-10-26 사용자).
이 문서만으로 일할 수 있게 썼다. 여기 없는 규칙은 개발 규격(받은 사본 `data/common/docs/개발규격/` — `캐슬_게임공통.md` · `게임개발규격.md`)의 해당 절을 찾아 읽는다(전체를 읽지 않는다). 우선순위: 사용자 답(기획서 00 결정 10 포함) → 이 문서 → 기획서(castle_common `docs/기획서/03`) → 규격.

> 정정 이력: 2026-11-08 — 1절 그림 B(도트)는 굳혀 둔다 · 다시 굽지 않음(사용자 "그림은 다시 (b)로 … 다 개발이 끝나면 그 이후에 추가하던지").
> 정정 이력: 2026-11-06 (8) — S5 묶음 4(2장 하성 본사 — 사용자 답 등급 · 남궁혁 A · 추천 범위): 0절 무엇, 1절 stage(방마다 조작 인물 · 따돌리기) · 장 표 haseong · 무대 haseong3d.
> 정정 이력: 2026-11-06 (7) — S5 묶음 2 · 3(프롤로그 · 1장 — 사용자 "묶음 2,3 동시에 진행해"): 0절 무엇, 1절 장 표 · 무대 그림(town3d · set3d).
> 정정 이력: 2026-11-06 (6) — #9 결정(3D 본편화 · 그림 A — 사용자 "1, 2, 3 추천대로"): 0절 무엇, 1절 campaign · save · title_menu.
> 정정 이력: 2026-11-06 (5) — 1절 · 2-1절 replay(입력 리플레이 · 상태 해시).
> 정정 이력: 2026-11-06 (4) — 리눅스 이전: 0절 개발 환경 실제 값 · 명령 `python3.11` · 2절 작업 서버 스크린샷(xvfb).
> 정정 이력: 2026-11-06 (3) — 문서 최소화(사용자 "불필요한 문서작업은 다 없애자"): 5절 다시 씀 · 0-1절 4 · 2절 기록 줄.
> 정정 이력: 2026-11-06 (2) — 2-1절 새로: agentic-sdlc 골격 2 · 3 · 5 · 13절(SOLID · TDD 등급 · 하드코딩 금지 · 도메인 품질)을 옮겨 적음 — 사용자 "현재 개발이 SOLID, TDD 기반 등 agentic-sdlc를 따르도록 되어있어?" → 따르지 않던 것을 적고 맞춤(`docs/기획_차이.md` 9-6).
> 정정 이력: 2026-11-06 — 폴더 이름 `castle_M3D` → **`castle_M_3D`**(사용자 "현재 프로젝트 디렉토리명을 castle_M_3D로 바꿔."). 저장소 이름 `hipiboy7/castle_M3D` · 판 id `castle_M3D`(castle_common `games.json`) · 패키지는 그대로. 받기 명령에 `--dest`(castle_common `games.json` 의 dest 가 옛 폴더 — 요청 15행).
> 정정 이력: 2026-11-05 (4) — 폰에서 할 일은 GitHub 앱 → Releases → Latest 에서(사용자): 2절 · 3절, 릴리스는 Latest · 본문 `docs/폰확인.md`.
> 정정 이력: 2026-11-05 (3) — 릴리스(규격 7절): 2절 리뷰는 릴리스 APK · 3절 태그 → release 잡 · versionCode · 아티팩트 1일, 5절 문서 이름 `S{N}_요구사항정의서`(사용자 "1~3 전부 추천대로").
> 정정 이력: 2026-11-05 (2) — 확정 규격(castle_common `ab9c8551` · 답45) 반영: 0절 서명 키(유지 · 릴리스도 이 키) · 접는 폰 지원, 2절 창 없는 스크린샷을 이 판에서 안 하는 이유(`docs/기획_차이.md` 9-5).
> 정정 이력: 2026-11-05 — S1 공통 받기: 개발 규격 반영(사용자 2026-11-04 "1~6 추천대로" — `docs/기획_차이.md` 9 · 10절). 0절 Android 전용 · PC판 없음(결정 10 — 옛 '모바일 우선 · PC 는 다음에'를 바꿈) · castle_common 은 읽기만 · 1 · 2층 원본 castle_common · 3층 이 판 소유 · 플랫폼 줄 · 사용자 폰 갤럭시 Z 폴드 4, 0-1절 castle_common 최신 확인 · git fetch, 2절 verify 공통 데이터 · 자산 출처, 3절 push 에는 build 만 · 에뮬레이터 수동 · 태그, 4절 출력 · 크레딧 상한 · 새 세션 · 토큰 ①~⑤, 5절 산출물 2장 · 자산 출처 목록 · id 참조.
> 정정 이력: 2026-10-26 — 0절 모바일 우선(사용자: "PC 버전은 모바일 버전이 완성된 다음에 진행하자. 모바일 버전 우선으로 진행해." — 2026-11-04 결정 10 'Android 전용'으로 바뀜), **공통 규칙 폴더** castle_common(사용자: "이런 내용은 '공통'으로 빼서 별도 디렉토리에 구성하고 castle 게임에서 공통으로 참고하도록").
> 정정 이력: 2026-10-26 — 이 폴더에서 Claude Code 를 따로 연다(사용자: "디렉토리 2개로 해서 3d와 기존에 하던작업 분리해서 클로드코드로 개발 진행하게") → 0-1절 세션 시작 순서, 4절 말하기 · 사용량 · 토큰 규칙을 castle_M 에서 옮겨 적음, 3절 `tools/ci.py`, 6절 주의.
> 정정 이력: 2026-10-26 — 첫 작성. 사용자: "권장안대로 진행해. 별도 브랜치를 따거나 별도 프로젝트 디렉토리로 만드는게 좋을까?" → 별도 디렉토리 · 별도 저장소(이유는 `docs/P1_설계서_3D초안.md` 1절).

## 0. 요약 (작업 전 필수 확인)
- **무엇**: **castle M 본편**(#9 결정 2026-11-06 — 3D 본편화 · 그림 A(GLB 툰 모델), castle_M pygame 은 Phase 3 전에 멈춤). 기획서 02 캠페인(장 0 ~ 13)을 이 판으로 — S5. 지금 할 수 있는 장: 0장 프롤로그(블라디보스토크 · 군터) · 1장 범죄도시 회암(김대건 · 윤덕수) · 2장 하성 본사(김신 / 서진태 방마다 · 남궁혁 따돌리기 · 신태진) · 6장 인천항 결투 · 11장 호텔 캐슬. 다음: 3장(청주 교도소 · 블라디보스토크 케이지 · 부산). 멀티(S6)는 기기 2대가 생기면 · 첫 모드 11장 협동
- **왜**: castle_M 2D 관절 인형이 "팔다리 움직이는 게 종잇장 같다"(2026-10-26 사용자) → 시험판(S1 ~ S4)으로 폰에서 보고 3D 로 정했다(`docs/S4_보고서_9엔진이전.md`)
- **엔진**: Godot 4.7.2-stable, Compatibility 렌더러(폰 · 에뮬레이터 · CI 가상 화면 공통). 버전은 `scripts/get_godot.py` 와 `.github/workflows/android.yml` 두 곳에 같게
- **Android 전용**(기획서 00 결정 10 · 2026-11-04 사용자): PC판 · iOS 는 만들지 않는다. 조작 · 화면 · 성능은 폰 기준으로 만들고 판단한다. 키보드 입력(`src/main.gd`)은 개발 편의로만 둔다
- **플랫폼**: 내보내기 `export_presets.cfg` 'Android' 하나 — ABI arm64-v8a(폰) + x86_64(에뮬레이터), 화면 가로(센서 가로 `project.godot` `orientation=4`, 기준 1280x720 · `stretch aspect="expand"`), minSdk · targetSdk 는 Godot 4.7 기본값(따로 정하지 않음). 워크플로 `.github/workflows/android.yml`, 수동 실행 `python3.11 tools/ci.py dispatch [브랜치] [--emulator]`, 에뮬레이터 API 34 x86_64 pixel_6. 첫 폰 확인 2026-10-26(run #6 APK, 폰 리뷰 1차 — 테스트결과서 4.6)
- **사용자 폰**: Android · **갤럭시 Z 폴드 4**(2026-11-04 사용자) — 커버 화면 약 23:9 · 펼친 안쪽 약 6:5. 접기 · 펴기(실행 중 화면 크기 · 비율 바뀜)를 지원한다 — 터치(`touch_ui.gd`) · HUD(`hud.gd` `_layout`)는 매 프레임 화면 크기를 다시 읽는다. 바뀐 뒤 그림 · 터치 자리를 폰 확인 목록에 둔다(규격 5절). 2022년 상위 기종(Snapdragon 8+ Gen 1)이라 '중급기 60fps' 판단은 따로 한다
- **castle_common(최상류) — 읽기만**: 엔진과 상관없는 게임 규칙(`rules/` — 쳐내기 · 등급 · 기술)과 1 · 2층 데이터(`data/` — 등급 · 게이지 · 비용 · 엇박 피해 · 기절 초 · 진행), 개발 규격(`docs/개발규격/`)의 원본. 이 세션은 castle_common 을 고치지 않는다 — 고칠 거리는 `docs/castle_common_요청.md`(캐슬_게임공통 3절 양식)에 적어 넘긴다. 받기는 `python3.11 ../castle_common/tools/sync.py castle_M3D`(`games.json` dest = `castle_M_3D/data/common` — castle_common `92cdd4b`) → `data/common/`(받은 사본 — 손으로 고치지 않는다, 도장 `data/common/SOURCE.json`) → 테스트(cases 포함) → "castle_common <커밋> 받음" 커밋. CHANGELOG 의 **[깨짐]** 항목은 받기 전에 읽는다
- **3층은 이 판 소유**: 기술 프레임 · 거리 · 피해 · 예고(`src/data/moves.gd`), 체력 · 체간 · 속도(`src/combat/duel.gd`), 보스 패턴(`src/combat/boss_ai.gd` · `skills.gd` `BAEK_OFFBEAT`), 외형 · 연출 · 소리. 처음 값의 출처는 castle_M(`castle_m/action/moves.py` · `docs/P2_설계서_M1전투핵심.md` 8절 · `castle_m/data/looks.py` · `assets/`)이고 그 뒤 폰 리뷰로 이 판이 바꿔 왔다. 스토리는 castle_M `docs/story/`. 3D 에서 먼저 시험한 규칙(엇박 계열 기절 등)은 **3D 덧붙임**(`docs/S1_테스트결과서_공통받기.md` 3절) — 공통으로 올릴지는 사용자
- **패키지** `com.hipiboy7.castlem3d`(castle_M 앱과 따로 설치된다), 서명 `android/debug.keystore`(castle_M 과 같은 고정 디버그 키, 의도적으로 커밋 · 유지 — 확정 규격 7절이 허용, 사용자 2026-11-04). 키는 바꾸지 않는다 — 릴리스(태그)에 붙이는 APK 도 이 키로 서명한다(덮어 설치 · 세이브 유지)
- **개발 환경**(2026-11-06 리눅스로 옮김): RHEL 9.6 x86_64 · root 없음. Python `python3.11`(기본 `python3` 는 3.9 — 쓰지 않는다. Windows 였던 때의 `py -3.12` 는 이것으로 읽는다). Godot 는 `.tools/`(커밋 안 함, `python3.11 scripts/get_godot.py` 가 리눅스 판을 받음). castle_common 은 `../projects/castle_common` 에 있고 `../castle_common` 은 그것을 가리키는 심볼릭 링크. 가상 화면 스크린샷 `tools/xvfb_shot.sh 폴더 [프레임] [초] [시드]`(Xvfb · Mesa 는 RPM 을 `~/.local-opt/xvfb/` 에 풀어 씀 — 트러블슈팅 T-8). push 는 SSH 원격(`git@github.com`). `tools/ci.py` 는 환경 변수 `GITHUB_TOKEN` 이 있어야 CI 를 본다(없으면 CI 조회 없이 진행). Blender 없음(필요하면 사용자 폴더에 받아 씀). 사용량 도구 없음 → 보고에 "측정 없음"
- **IP**: 비공식 · 비영리 · 비공개(저장소 비공개 유지, 공개 배포 없음). 원작 그림을 클라우드 AI(ArtCraft 등)에 올리는 것은 외부 전송이라 사용자가 정한다

## 0-1. 세션을 시작하면 읽는 순서
1. 사용량 보고 — `~/claude/usage/usage_cost.py` 가 있으면 출력 두 줄, 없으면 "측정 없음" (4절)
2. `git fetch` (이 저장소) · `git -C ../castle_common fetch` 뒤 `git -C ../castle_common status -sb` — castle_common 이 뒤처져 있으면 멈추고 알린다
3. `history/` 의 가장 최근 파일 — 마지막 상태와 다음 단계
4. `docs/트러블슈팅.md`(환경 문제가 나면)
5. 전체 검증 `python3.11 scripts/verify.py` — 실패하면 그것부터 고친다. '공통 데이터' 줄에 **[알림] castle_common 이 앞섰다**가 뜨면 CHANGELOG 를 읽고 그 세션 첫 일로 받는다. CI 상태는 `python3.11 tools/ci.py runs`

대화는 세션이 끝나면 사라진다. 이어받는 데 필요한 사실은 전부 저장소(이 문서 · 문서 · history · 커밋)에 둔다.

## 1. 구조
- `src/combat/` 순수 로직(fighter · world · boss_ai · bot · duel(6장) · stage(장 표의 방 · 여럿 · 교대 — 방마다 조작 인물 cast · kit · 따돌리기 escape) · enemy_ai(적 프로필) · replay(입력 기록 · 상태 해시 — 판 끝마다 `user://replay_last.json`, `--replay 경로` 로 재생)) — 노드 없음, 60프레임 고정, 같은 시드면 같은 결과. 시험 `tests/unit/`(A) · `tests/integration/`(B) · 공통 `tests/helpers.gd`
- `src/data/campaign.gd` **장 목록**(본편 장 차례 · 종류 duel | stage | soon · 진행 사건 · 장 표 — 장을 더하면 여기 한 줄 + 장 표 + `lines.json` chapters) · `save.gd` 세이브(형식 버전 · 옛 · 깨진 · 새 형식 규칙은 파일 머리, `user://save.json`)
- `src/data/common.gd` 공통 데이터 읽기 + 규칙 함수(castle_common `ref/rules.py` 와 같은 이름 · 인자, 시험 `tests/unit/test_common_cases.gd`), `skills.gd` 이 판의 기술 값(id → 동작 · 3층) · `moves.gd` 동작 표(3층) · `addendum.gd` **3D 덧붙임 1층**(castle_common 에 아직 없는 인물 · 기술 — 사용자 답 2026-11-06, 요청 16 ~ 19행) · 장 표(방 · 역할 · 시점 · 원작 근거 CANON · 3층 — `stage.gd` 가 장 id 로 읽는다): `prologue.gd` 0장 · `hoeam.gd` 1장 · `haseong.gd` 2장 · `hotel.gd` 11장 · `lines.gd` 대사(`data/story/lines.json`)
- `data/common/` 받은 사본(sync 가 쓴다 — json 5개는 APK 에 들어가고 `cases/` · `docs/` 는 안 들어간다)
- `src/view/` 그림(puppet3d 관절 인형 · poses 각도 표 · looks 외형 표 · arena3d 부두 · set3d 무대 도구 → hotel3d 호텔 층 · town3d 0 · 1장 거리 · 실내 → haseong3d 2장 하성 본사 · fx3d 연출 · event_fx 신호 → 연출 · sound · camera_rig) — 로직 상태를 읽기만 한다
- `src/ui/` 화면 표시 · 터치 · 안전 영역 · 뒤로 버튼 규칙(nav) · 처음 화면 장 고르기(title_menu), `src/main.gd` 본체(흐름 · 입력 · 무대 · 인형 바꿔 끼우기 · 실행 인자)
- 인물 · 기술은 id(castle_common `characters.json` · `skills.json` — `kimshin` · `kickarts` …)로 참조하고, 화면 이름은 `name`
- 캐릭터를 GLB 로 바꿀 때: `update_from(f, dt, frozen)` 를 가진 그림 클래스를 새로 만들어 `src/main.gd` 에서 바꿔 끼운다(판정은 그대로)
- `assets/` 자산 — 출처 목록 `assets/ASSETS.md`(새 파일은 여기 한 줄, verify 가 본다)
- `scripts/` 검증 · Godot 받기 · 에뮬레이터 점검(CI 경로 필터에 들어 있다), `tools/` 개발 도우미(경로 필터 밖 — 바꿔도 CI 가 안 돈다)
- 그림 A · B(S3): `tools/make_models.gd`(헤드리스 — GLB `assets/models/<id>_a.glb`) · `tools/make_sprites.gd`(가상 화면 `tools/xvfb_run.sh` — 도트 시트 `assets/sprites/<id>_b.png/json`). 외형을 고치면 `make_models.gd` 만 다시 돌리고 `--import` — **그림 B(도트)는 굳혀 둔다**(다시 굽지 않음 · A 와 모습이 어긋나도 둔다, 개발이 끝난 뒤 다시 다룬다 — 사용자 2026-11-08 "너무 시간이 오래 걸리네", 한 번에 117장 약 20분). 게임은 `--art puppet|a|b` · 처음 화면 '그림' 버튼. 수치 조정은 `tests/sim_stage.gd`(11장 봇 6판) · `tests/sim.gd`(6장)

## 2. 검증
- 전체 검증: `python3.11 scripts/verify.py` (약 20초 — 공통 데이터(도장 · castle_common 비교) · 자산 출처 · 가져오기 · 테스트(공통 cases 1,464줄 포함) · 자동 결투 3판. 출력에 ERROR · WARNING · Leaked 가 있으면 실패). 커밋 전에 반드시. 마일스톤 끝 · 태그 전에는 `--strict`(castle_common 이 앞서 있으면 실패)
- **작업 서버에서는 전체 검증 + 가상 화면 스크린샷까지**(결정 10 덧붙임 2 · 규격 4 · 5절 '창 없는 그리기' 허용 — 리눅스로 옮긴 이유, 사용자 2026-11-06): 게임 창 · Android 빌드 · 에뮬레이터는 여기서 돌리지 않는다. 화면을 바꾼 묶음은 `tools/xvfb_shot.sh`(Xvfb 가상 화면 · llvmpipe — CI '화면 찍기'와 같은 인자, 약 1 ~ 2fps)로 찍어 직접 본다. CI `shots` · `emulator` 아티팩트는 `GITHUB_TOKEN` 이 있을 때 받아 본다
- **리뷰는 릴리스의 APK 로**(사용자는 PC 에서 플레이하지 않는다, 2026-10-19 · 규격 7절 2026-11-05): **폰에서 할 일은 모두 GitHub 앱 → `castle_M3D` → Releases → 맨 위(Latest)에서 바로 하게 한다**(사용자 2026-11-05 "url 치지 않고, github app 들어가서 바로 릴리즈 다운받게" · "앞으로 폰에서 해야할 것은 모두 github app > release 에서"). 그래서 ① 폰 리뷰가 필요하면 늘 태그를 올려 릴리스를 만든다(Actions 아티팩트 · 주소 링크로 안내하지 않는다) ② 릴리스는 프리릴리스로 두지 않고 **Latest** 로(태그 이름은 `v0.N.0-rc.M` 그대로 — 규격 7절 '프리릴리스'와 다름, 요청 14행) ③ 태그 전에 `docs/폰확인.md`(설치 · 1분 경로 · 이번에 볼 것)를 그 마일스톤에 맞게 고친다 — CI 가 릴리스 본문으로 붙인다. 사용자에게는 "GitHub 앱 → castle_M3D → Releases → 맨 위"로만 알린다. 화면을 바꾼 묶음은 CI 스크린샷을 받아 직접 본다(저장은 S4 보고서용만)
- 마일스톤 보고는 채팅으로 짧게: 되는 것 · 안 되는 것 · CI run · 다음 · 비용(문서로 따로 쓰지 않는다)

## 2-1. 설계 · 시험 원칙 (agentic-sdlc `docs/howtoCLAUDEMD.md` 골격 2 · 3 · 5 · 13절 · `docs/howtoGAME.md` 4절 — `7110098` 에서 옮겨 적음)
- **SOLID**
  - SRP: 로직(`src/combat`) · 데이터(`src/data`) · 그림(`src/view`) · 화면 표시(`src/ui`) · 흐름(`src/main.gd`)을 나눈다. `main.gd` 는 S2 에서 소리(`sound.gd`) · 연출(`event_fx.gd`) · 외형(`looks.gd`) · 대사(`lines.json`)를 뺐다. `fighter.gd` · `puppet3d.gd` 는 아직 크다
  - OCP: 2층 값은 castle_common JSON(`common.gd`), 3층 조정 값은 표(`moves.gd` `M` · `main.gd` `LOOKS` · `skills.gd` `BAEK_OFFBEAT`)로 늘린다 — 규칙 코드를 고치지 않고
  - LSP: 그림 클래스는 `update_from(f, dt, frozen)`(+ `remove_glasses`)만 갖추면 바꿔 끼울 수 있어야 한다(관절 인형 → GLB · 도트 빌보드)
  - ISP: 로직은 그림을 모른다 — 그림 · 소리는 `World.events` 신호와 상태만 읽는다
  - DIP: 이 판에서 가장 바뀌기 쉬운 두 축 = **그림**(관절 인형 → GLB · 도트) · **공통 데이터**(castle_common 판 · 형식). 상위(`main.gd` · `duel.gd`)는 구체 그림 · 파일이 아니라 그 인터페이스(`update_from` · `common.gd` 함수)에 기댄다
- **TDD — 선별 적용**(애매하면 "같은 입력에 늘 같은 출력인가")

  | 등급 | 이 판 | 규칙 | 커버리지 |
  |---|---|---|---|
  | A 핵심 순수 로직 | `src/data/common.gd` · `skills.gd` · `moves.gd`, `src/combat/world.gd` · `fighter.gd`(판정 · 피해 · 기절 · 게이지 · 등급) | **테스트 먼저(Red → Green → Refactor)**. 상류 골든(castle_common cases)은 반드시 시험에 | ≥ 90% |
  | B 오케스트레이션 | `src/combat/duel.gd` · `boss_ai.gd` · `bot.gd`, `main.gd` 흐름(결투 → 2차 → 결과) | 구현 뒤 통합 시험 — headless N 프레임(`--autoplay` · `tests/sim.gd`), 같은 시드 같은 결과 | ≥ 70% |
  | C 콘텐츠 | `src/view/*` · `src/ui/*` · `assets/` · 연출 · 대사 | 검사 스크립트(자산 출처) + CI 스크린샷을 직접 본다 | 측정 제외 |

  - 배치: A → `tests/unit/`, B → `tests/integration/`(`tests/run_tests.gd` 가 두 폴더를 돈다)
  - 커버리지: GDScript 는 줄 단위 도구가 없다 — **함수 단위**(A · B 파일의 함수 중 시험이 부르는 비율)를 verify '커버리지' 줄이 잰다(`.tools/cov/` 사본에 표시 줄을 넣어 돌림 · 기준 밑이면 실패 · 파일 목록 `scripts/verify.py` `COV_FILES`)
  - 입력 리플레이 · 상태 해시(같은 입력 기록이면 같은 해시)는 멀티 ④ 의 바탕 — `src/combat/replay.gd`(2026-11-06). 사람 입력은 양자화해서 판에 넣고, 봇도 입력(intent)으로만 움직인다(판 상태를 직접 바꾸지 않는다)
- **하드코딩 금지**: 경로는 상대(`res://` · `../castle_common`), 환경마다 다른 값은 환경 변수(`GODOT` · `CASTLE_COMMON`), 비밀 없음(디버그 키는 0절 예외). 도메인 상수는 그 파일 머리 `const` 한 곳, 3층 조정 값은 표. 대사는 `data/story/lines.json`(원작 인용은 refs 화/컷). 재현성 값(시드)은 고정
- **도메인 품질**(골격 13절): 판정 결정성(60Hz 고정 · 시드 하나) · 받은 공통 데이터는 손대지 않음(도장 — verify) · 자산 출처(`assets/ASSETS.md` — verify) · 원작 신뢰도(canon `conf: ai` 는 연출에만, 근거 주석에 표시) · 성능 예산(`docs/성능.md` — 실기 FPS, 다음 단계) · 세이브는 아직 없음(생기면 형식 버전 · 옛 세이브 시험)

## 3. Git · 외부 서비스
- 저장소 `hipiboy7/castle_M3D`(비공개, 2026-10-26 REST 로 만듦 — 사용자 확인 "둘 다 push 하고 Actions 돌려줘"). `main` 에 직접 작업하지 않는다(`impl-*` 브랜치, 병합 `--no-ff`, 브랜치 보존). 지금 브랜치 `impl-draft1`
- commit · push 전에 `git fetch`(여러 서버 · PC 에서 일한다 — 규격 2-14)
- **사람 확인이 필요한 일**: push(올라갈 커밋을 보여 주고), 태그 push, 저장소 공개 범위(비공개 유지), 릴리스, 이력 재작성 · 강제 push · 삭제, 비용이 드는 외부 호출. 커밋 금지: `.env` · 토큰 · 키(고정 디버그 키 `android/debug.keystore` 는 예외). `git add -A` 대신 경로를 적는다
- Actions: `main` · `impl-*` push(경로 필터 — `src/` · `data/` · `assets/` · `tests/` · `scripts/` · 설정)에는 **build 만**(검증 · APK · APK 안 json 검사 · 폰 스크린샷, 캐시가 있으면 약 2 ~ 3분). **에뮬레이터 점검은 수동 실행(`tools/ci.py dispatch --emulator`)과 태그 push 때만**(약 5 ~ 8분 더 — 규격 1 · 9절, 사용자 2026-11-04). 태그 push 는 build → emulator → **release**(APK 를 GitHub Releases 에 Latest 로, 본문 `docs/폰확인.md`, 디버그 키 서명). `versionCode` = run 번호 · `versionName` = 태그(가지 빌드는 `0.2.0-dev.<run>`). 무료 분량(계정 전체 월 2,000분)을 castle_M 과 같이 쓴다. 아티팩트는 1일(빌드 검사용 — 남길 스크린샷은 바로 `docs/screenshots/` 로)
- GitHub API 는 `gh` 없이 토큰(환경 변수 `GITHUB_TOKEN`, 없으면 git credential)으로 REST — **`python3.11 tools/ci.py`** (runs · status · watch · fetch · log · dispatch · cancel, 사용법은 파일 머리). 토큰을 파일 · 로그 · 커밋에 남기지 않는다. CI 를 기다릴 때는 `watch` 를 백그라운드로 돌리고 끝나면 이어서 본다

## 4. 사용자와 말하기 · 사용량 · 토큰 (castle_M CLAUDE.md 11절 · 규격 캐슬_게임공통 1절)
- **사용자에게 보고 · 응답 · 요약 · 질문은 항상 한국어.** 작업 중 출력(도구 호출 전후 메모, 진행 한 줄)은 짧게 쓰고(영어 짧은 메모도 된다) 사용자가 읽을 내용을 섞지 않는다. 코드 · 명령 · 경로 · 오류 원문은 원래 표기대로
- 사용자가 읽을 글은 작업이 끝난 뒤 마지막에 한 덩어리로. 구분선 한 줄 + 표지 제목으로 시작한다: `## ✅ 결과`(작업 결과 · 요약) · `## 💬 답변`(질문에 대한 답) · `## ❓ 확인 요청`(선택 · 결정 · 확인). 덩어리 안의 소제목은 `###`. 작업 중에 꼭 물어야 하면 같은 모양으로 쓰고 거기서 멈춘다
- 답이 필요한 질문은 덩어리 끝에 번호를 달아 모은다. 선택지가 있으면 추천과 이유를 함께
- **예상 비용 · 누적 $**(2026-10-16 사용자 지시): 작업 전에 할 일과 예상 비용($ 범위, 근거는 지난 history 의 실제 증가분). 결과 덩어리마다 첫머리에 `py -3.12 D:/claude/usage/usage_cost.py` 출력 두 줄. 기준일 2026-10-01 — 사용자가 refresh 를 요청하기 전까지 바꾸지 않는다(요청하면 `--refresh`)
- **크레딧 상한**(규격 1-3): 한 묶음 상한 $100 — 80% 에서 멈추고 묻고, 100% 면 중단. 예상이 $40 을 넘으면 쪼갠 계획을 먼저 낸다
- **effort**: 단계마다 추천 effort 를 적는다(조사 · 기획 차이 medium, 문서 · 일반 구현 high, 반복 수정 medium, 구조 설계 · 어려운 버그만 xhigh ~ max). 지금 effort 가 그 단계에 비해 높거나 낮으면 시작 전에(그 자리에서) 먼저 말한다(사용자가 `/model` · `claude --effort` 로 바꾼다)
- **토큰 효율**: 큰 단계 전에 한 번 제안한다 — ① 미리 읽을 것 ② 별도 프롬프트 파일 ③ 검토를 잘게 ④ 서브에이전트(단순 추출은 Sonnet / Haiku) ⑤ 단계별 effort. 큰 자료 읽기 · 웹 조사 · 에이전트 여러 개 · 일괄 작업은 이유와 대략 비용을 먼저 말하고 확인받는다. 작업 중에는 건드린 것만 점검하고 커밋 전에 전체 검증. 보고는 짧게, 자세한 것은 파일로. 절차상 만들게 되는 산출물 중 값어치가 적어 보이는 것은 하기 전에 "빼거나 줄일지" 묻는다
- **새 세션을 권할 때**: 작업 한 덩어리가 끝나면 상태를 파일에 남기고, `/exit` · `/clear` 해도 되는지와 새 세션 첫 프롬프트 전문(코드 블록)을 매번 보인다
- 세션 기록 `history/<날짜>_<작업자>_<주제>.md` — 머리에 시작 · 끝 누적 $ · 작업별 예상과 실제

## 5. 문서 — 최소만 (사용자 2026-11-06 "불필요한 문서작업은 다 없애자")
- **만드는 것(이것뿐)**
  - `history/<날짜>_<작업자>_<주제>.md` — 세션 끝에 15줄 안: 사용량 · 한 일 · 다음 단계 · 새 세션 첫 프롬프트. 이어받기의 유일한 기록
  - `docs/폰확인.md` — 태그 전에 그 판에서 볼 것으로 고친다(릴리스 본문)
  - `assets/ASSETS.md` — 자산을 더할 때 한 줄(verify 가 본다)
  - `docs/castle_common_요청.md` — 상류에 넘길 것이 생길 때만 한 줄
  - `docs/트러블슈팅.md` — 새로 겪은 환경 · 빌드 문제만, 증상 · 원인 · 해결 3줄
  - **S4 #9 보고서**(최종 결과물) — 기획서 03 2절 기준 표 + 추천
- **만들지 않는 것**: 마일스톤마다의 요구사항정의서 · 테스트결과서(규격 3절과 다름 — 사용자 결정), 문서 머리 정정 이력(CLAUDE.md 만 한 줄), `docs/기획_차이.md` 갱신, 스크린샷 저장(S4 보고서에 쓸 비교 캡처만), sha256 · 크기 기록(릴리스 페이지에 있다). 지난 문서(P1 · S1 · 기획_차이)는 고치지 않고 그대로 둔다
- 설계는 코드 주석으로. 수치 · 결과는 커밋 메시지와 history 에 한 줄
- 원작 위치는 `화/컷`(예: `062/099-106`), 원작 컷을 쓴 자산은 `ASSETS.md` 에 위치와 함께. castle_M 에 알릴 결정(#9)은 castle_M `CLAUDE.md` 1절 표 · history 에

## 6. 주의 (이 서버에서 겪은 것)
- Git Bash 에서 REST 경로(`/repos/...`)를 인자로 주면 `C:/Program Files/Git/repos/...` 로 바뀐다 → `MSYS_NO_PATHCONV=1`
- Bash 도구의 heredoc 에 쓴 역슬래시가 풀린다(`\f` → 폼 피드, 파이썬 글 안의 `\r\n` 도 — S1 에서 verify.py 가 깨졌다). 윈도우 경로 · 역슬래시가 든 글은 Write · Edit 도구로 쓴다
- 콘솔에서 한글이 깨지면 `PYTHONIOENCODING=utf-8 PYTHONUTF8=1` (`scripts/verify.py` 는 스스로 UTF-8 로 출력한다)
- CI 는 소프트웨어 GPU 라 느리고(가상 화면 2fps, 에뮬레이터 1 ~ 2fps) 에뮬레이터는 3D 셰이더가 깨진다 — `docs/트러블슈팅.md` T-2 · T-4
