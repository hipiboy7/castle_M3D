# CLAUDE.md — castle M 3D 초안 작업 규칙

「캐슬」 팬게임 castle M 의 **3D 초안**(Godot 4)이다. 목적은 하나 — 엔진 이전(castle_M 보류 결정 #9)을 정할 시험판.
본편은 형제 폴더 `D:\claude\fun\castle_M`(pygame-ce, 저장소 `hipiboy7/castle_M`).
**이 폴더에서 Claude Code 를 따로 열어 개발한다** — 3D 일은 이 폴더 세션에서, 2D 본편 일은 castle_M 폴더 세션에서(2026-10-26 사용자).
이 문서만으로 일할 수 있게 썼다. 여기 없는 규칙이 필요할 때만 castle_M `CLAUDE.md` 의 해당 절을 찾아 읽는다(전체를 읽지 않는다).

> 정정 이력: 2026-10-26 — 이 폴더에서 Claude Code 를 따로 연다(사용자: "디렉토리 2개로 해서 3d와 기존에 하던작업 분리해서 클로드코드로 개발 진행하게") → 0-1절 세션 시작 순서, 4절 말하기 · 사용량 · 토큰 규칙을 castle_M 에서 옮겨 적음, 3절 `tools/ci.py`, 6절 주의.
> 정정 이력: 2026-10-26 — 첫 작성. 사용자: "권장안대로 진행해. 별도 브랜치를 따거나 별도 프로젝트 디렉토리로 만드는게 좋을까?" → 별도 디렉토리 · 별도 저장소(이유는 `docs/P1_설계서_3D초안.md` 1절).

## 0. 요약 (작업 전 필수 확인)
- **무엇**: 인천항 제3부두의 밤, 김신 vs 백도찬 1:1 결투 한 판(castle_M Phase 2 결투의 3D 판). 캐릭터는 임시 3D 관절 인형 → ArtCraft · Mixamo 등으로 만든 GLB 로 바꿔 끼울 예정
- **왜**: castle_M 2D 관절 인형이 "팔다리 움직이는 게 종잇장 같다"(2026-10-26 사용자) → 3D 가 얼마나 나은지 폰에서 보고 엔진을 정한다
- **엔진**: Godot 4.7.2-stable, Compatibility 렌더러(폰 · 에뮬레이터 · CI 가상 화면 공통). 버전은 `scripts/get_godot.py` 와 `.github/workflows/android.yml` 두 곳에 같게
- **원본 데이터(상류)**: 기술 프레임 · 피해 · 예고는 castle_M `castle_m/action/moves.py`, 보스 패턴은 castle_M `docs/P2_설계서_M1전투핵심.md` 8절, 외형 색은 `castle_m/data/looks.py`, 소리 · 음악 · 글꼴은 castle_M `assets/`, 스토리는 castle_M `docs/story/`. 여기는 하류다 — 값을 바꿀 때는 castle_M 쪽이 먼저
- **패키지** `com.hipiboy7.castlem3d`(castle_M 앱과 따로 설치된다), 서명 `android/debug.keystore`(castle_M 과 같은 고정 디버그 키, 의도적으로 커밋)
- **개발 환경**: castle_M 과 같은 Windows Server 2022. Python 은 `py -3.12`(기본 `python` 은 3.14 라 쓰지 않는다), Godot 는 `.tools/`(커밋 안 함, `py -3.12 scripts/get_godot.py` 로 받음)
- **IP**: 비공식 · 비영리 · 비공개(저장소 비공개 유지, 공개 배포 없음). 원작 그림을 클라우드 AI(ArtCraft 등)에 올리는 것은 외부 전송이라 사용자가 정한다

## 0-1. 세션을 시작하면 읽는 순서
1. 사용량 보고 — `py -3.12 D:/claude/usage/usage_cost.py` 출력 두 줄 (4절)
2. `history/` 의 가장 최근 파일 — 마지막 상태와 다음 단계
3. `docs/P1_테스트결과서_3D초안.md` 4절(자체 점검 목록) · `docs/트러블슈팅.md`
4. 전체 검증 `py -3.12 scripts/verify.py` — 실패하면 그것부터 고친다. CI 상태는 `py -3.12 tools/ci.py runs`

대화는 세션이 끝나면 사라진다. 이어받는 데 필요한 사실은 전부 저장소(이 문서 · 문서 · history · 커밋)에 둔다.

## 1. 구조
- `src/combat/` 순수 로직(fighter · world · boss_ai · bot · duel) — 노드 없음, 60프레임 고정, 같은 시드면 같은 결과. 테스트 `tests/test_combat.gd`
- `src/view/` 그림(puppet3d 관절 인형 · poses 각도 표 · arena3d 무대 · fx3d 연출 · camera_rig) — 로직 상태를 읽기만 한다
- `src/ui/` 화면 표시 · 터치, `src/main.gd` 본체(흐름 · 입력 · 소리 · 실행 인자)
- 캐릭터를 GLB 로 바꿀 때: `update_from(f, dt, frozen)` 를 가진 그림 클래스를 새로 만들어 `src/main.gd` 에서 바꿔 끼운다(판정은 그대로)
- `scripts/` 검증 · Godot 받기 · 에뮬레이터 점검(CI 경로 필터에 들어 있다), `tools/` 개발 도우미(경로 필터 밖 — 바꿔도 CI 가 안 돈다)

## 2. 검증
- 전체 검증: `py -3.12 scripts/verify.py` (약 15초 — 가져오기 · 테스트 · 자동 결투 3판. 출력에 ERROR · WARNING · Leaked 가 있으면 실패). 커밋 전에 반드시
- **이 서버에서 게임 창을 띄우지 않는다**(사용자 2026-10-20: "PC에서는 당분간 실행 없었으면 해"). Godot 는 `--headless` 로만 돌린다(그림이 안 나온다). 화면 확인은 CI 가상 화면 스크린샷(`shots` 아티팩트) · 에뮬레이터 스크린샷(`emulator` 아티팩트)으로 — 받아서 직접 본다
- **리뷰는 APK 로**(사용자는 PC 에서 플레이하지 않는다, 2026-10-19): Actions run 번호 · 아티팩트 링크를 알리고 리뷰를 요청한다. 화면을 바꾼 묶음은 스크린샷을 `docs/screenshots/P1/` 에 남기고 테스트결과서에 경로

## 3. Git · 외부 서비스
- 저장소 `hipiboy7/castle_M3D`(비공개, 2026-10-26 REST 로 만듦 — 사용자 확인 "둘 다 push 하고 Actions 돌려줘"). `main` 에 직접 작업하지 않는다(`impl-*` 브랜치, 병합 `--no-ff`, 브랜치 보존). 지금 브랜치 `impl-draft1`
- **사람 확인이 필요한 일**: push(올라갈 커밋을 보여 주고), 저장소 공개 범위(비공개 유지), 릴리스, 이력 재작성 · 강제 push · 삭제, 비용이 드는 외부 호출. 커밋 금지: `.env` · 토큰 · 키(고정 디버그 키 `android/debug.keystore` 는 예외)
- Actions: `main` · `impl-*` push(경로 필터)와 workflow_dispatch. 캐시가 있으면 build 약 2분 + emulator 약 5분(run #2). 무료 분량(계정 전체 월 2,000분)을 castle_M 과 같이 쓴다. 아티팩트는 14일
- GitHub API 는 `gh` 없이 GCM 토큰으로 REST — **`py -3.12 tools/ci.py`** (runs · status · watch · fetch · log · dispatch · cancel, 사용법은 파일 머리). 토큰을 파일 · 로그 · 커밋에 남기지 않는다. CI 를 기다릴 때는 `watch` 를 백그라운드로 돌리고 끝나면 이어서 본다

## 4. 사용자와 말하기 · 사용량 · 토큰 (castle_M CLAUDE.md 11절에서 옮김)
- **사용자에게 보고 · 응답 · 요약 · 질문은 항상 한국어.** 작업 중 출력(도구 호출 전후 메모, 진행 한 줄)은 짧게 쓰고 사용자가 읽을 내용을 섞지 않는다. 코드 · 명령 · 경로 · 오류 원문은 원래 표기대로
- 사용자가 읽을 글은 작업이 끝난 뒤 마지막에 한 덩어리로. 구분선 한 줄 + 표지 제목으로 시작한다: `## ✅ 결과`(작업 결과 · 요약) · `## 💬 답변`(질문에 대한 답) · `## ❓ 확인 요청`(선택 · 결정 · 확인). 작업 중에 꼭 물어야 하면 같은 모양으로 쓰고 거기서 멈춘다
- 답이 필요한 질문은 덩어리 끝에 번호를 달아 모은다. 선택지가 있으면 추천과 이유를 함께
- **예상 비용 · 누적 $**(2026-10-16 사용자 지시): 작업 전에 할 일과 예상 비용($ 범위, 근거는 지난 history 의 실제 증가분). 결과 덩어리마다 첫머리에 `py -3.12 D:/claude/usage/usage_cost.py` 출력 두 줄. 기준일 2026-10-01 — 사용자가 refresh 를 요청하기 전까지 바꾸지 않는다(요청하면 `--refresh`)
- **effort**: 단계마다 추천 effort 를 적는다(문서 · 일반 구현 high, 반복 수정 medium, 구조 설계 · 어려운 버그만 xhigh ~ max). 지금 effort 가 그 단계에 비해 높거나 낮으면 시작 전에 먼저 말한다(사용자가 `/model` · `claude --effort` 로 바꾼다)
- **토큰 효율**: 작업 한 덩어리가 끝나면 상태를 파일에 남기고 새 세션에서 잇는다. 큰 자료 읽기 · 웹 조사 · 에이전트 여러 개 · 일괄 작업은 이유와 대략 비용을 먼저 말하고 확인받는다. 단순 추출 서브에이전트는 Sonnet / Haiku. 작업 중에는 건드린 것만 점검하고 커밋 전에 전체 검증. 보고는 짧게, 자세한 것은 파일로. 절차상 만들게 되는 산출물 중 값어치가 적어 보이는 것은 하기 전에 "빼거나 줄일지" 묻는다
- 세션 기록 `history/<날짜>_<작업자>_<주제>.md` — 머리에 시작 · 끝 누적 $ · 작업별 예상과 실제

## 5. 문서
- `docs/P1_요구사항정의서_3D초안.md` → `docs/P1_설계서_3D초안.md` → 코드 → `docs/P1_테스트결과서_3D초안.md`, 겪은 문제는 `docs/트러블슈팅.md`. 설계서의 인터페이스 세부는 코드 주석으로 대신한다(castle_M 2026-10-16 사용자 승인과 같게)
- 개정은 제자리 개정 + 머리에 정정 이력. 문서에 적은 명령은 적은 그대로 실행해 본다. 수치는 실행 출력을 복사하고 날짜를 적는다
- castle_M 쪽에 알릴 결정(보류 결정 #9 등)은 castle_M `CLAUDE.md` 1절 표 · history 에도 적는다(castle_M 세션이 읽는다)

## 6. 주의 (이 서버에서 겪은 것)
- Git Bash 에서 REST 경로(`/repos/...`)를 인자로 주면 `C:/Program Files/Git/repos/...` 로 바뀐다 → `MSYS_NO_PATHCONV=1`
- Bash 도구의 heredoc 에 쓴 역슬래시가 풀린다(`\f` → 폼 피드). 윈도우 경로가 든 글은 Write · Edit 도구로 쓴다
- 콘솔에서 한글이 깨지면 `PYTHONIOENCODING=utf-8 PYTHONUTF8=1`
- CI 는 소프트웨어 GPU 라 느리고(가상 화면 2fps, 에뮬레이터 1 ~ 2fps) 에뮬레이터는 3D 셰이더가 깨진다 — `docs/트러블슈팅.md` T-2 · T-4
