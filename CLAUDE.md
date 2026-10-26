# CLAUDE.md — castle M 3D 초안 작업 규칙

「캐슬」 팬게임 castle M 의 **3D 초안**(Godot 4)이다. 목적은 하나 — 엔진 이전(castle_M 보류 결정 #9)을 정할 시험판.
본편은 형제 폴더 `D:\claude\fun\castle_M`(pygame-ce, 저장소 `hipiboy7/castle_M`). 이 문서에 없는 규칙은 그쪽 CLAUDE.md 를 따른다.

> 정정 이력: 2026-10-26 — 첫 작성. 사용자: "권장안대로 진행해. 별도 브랜치를 따거나 별도 프로젝트 디렉토리로 만드는게 좋을까?" → 별도 디렉토리 · 별도 저장소(이유는 `docs/P1_설계서_3D초안.md` 1절).

## 0. 요약 (작업 전 필수 확인)
- **무엇**: 인천항 제3부두의 밤, 김신 vs 백도찬 1:1 결투 한 판(castle_M Phase 2 결투의 3D 판). 캐릭터는 임시 3D 관절 인형 → ArtCraft · Mixamo 등으로 만든 GLB 로 바꿔 끼울 예정
- **왜**: castle_M 2D 관절 인형이 "팔다리 움직이는 게 종잇장 같다"(2026-10-26 사용자) → 3D 가 얼마나 나은지 폰에서 보고 엔진을 정한다
- **엔진**: Godot 4.7.2-stable, Compatibility 렌더러(폰 · 에뮬레이터 · CI 가상 화면 공통). 버전은 `scripts/get_godot.py` 와 `.github/workflows/android.yml` 두 곳에 같게
- **원본 데이터(상류)**: 기술 프레임 · 피해 · 예고는 castle_M `castle_m/action/moves.py`, 보스 패턴은 castle_M `docs/P2_설계서_M1전투핵심.md` 8절, 외형 색은 `castle_m/data/looks.py`, 소리 · 음악 · 글꼴은 castle_M `assets/`, 스토리는 castle_M `docs/story/`. 여기는 하류다 — 값을 바꿀 때는 castle_M 쪽이 먼저
- **패키지** `com.hipiboy7.castlem3d`(castle_M 앱과 따로 설치된다), 서명 `android/debug.keystore`(castle_M 과 같은 고정 디버그 키, 의도적으로 커밋)
- **개발 환경**: castle_M 과 같은 Windows Server 2022. Python 은 `py -3.12`(검증 스크립트), Godot 는 `.tools/`(커밋 안 함, `py -3.12 scripts/get_godot.py` 로 받음)

## 1. 구조
- `src/combat/` 순수 로직(fighter · world · boss_ai · bot · duel) — 노드 없음, 60프레임 고정, 같은 시드면 같은 결과. 테스트 `tests/test_combat.gd`
- `src/view/` 그림(puppet3d 관절 인형 · poses 각도 표 · arena3d 무대 · fx3d 연출 · camera_rig) — 로직 상태를 읽기만 한다
- `src/ui/` 화면 표시 · 터치, `src/main.gd` 본체(흐름 · 입력 · 소리 · 실행 인자)
- 캐릭터를 GLB 로 바꿀 때: `update_from(f, dt, frozen)` 를 가진 그림 클래스를 새로 만들어 `src/main.gd` 에서 바꿔 끼운다(판정은 그대로)

## 2. 검증
- 전체 검증: `py -3.12 scripts/verify.py` (약 15초 — 가져오기 · 테스트 · 자동 결투 3판. 출력에 ERROR · WARNING · Leaked 가 있으면 실패). 커밋 전에 반드시
- **이 서버에서 게임 창을 띄우지 않는다**(castle_M 사용자 규칙 2026-10-20). Godot 는 `--headless` 로만 돌린다(그림이 안 나온다). 화면 확인은 CI 가상 화면 스크린샷 · 에뮬레이터 스크린샷으로
- **리뷰는 APK 로**(사용자는 PC 에서 플레이하지 않는다): Actions run 번호 · 아티팩트 링크를 알리고 리뷰를 요청한다

## 3. Git · 외부 서비스
- 저장소 `hipiboy7/castle_M3D`(비공개, 2026-10-26 REST 로 만듦 — 사용자 확인 "둘 다 push 하고 Actions 돌려줘"). push 는 올라갈 커밋을 보여 주고 사용자 확인 뒤. `main` 에 직접 작업하지 않는다(`impl-*` 브랜치, 병합 `--no-ff`, 브랜치 보존)
- Actions: `main` · `impl-*` push(경로 필터)와 workflow_dispatch(`POST /repos/hipiboy7/castle_M3D/actions/workflows/396637959/dispatches {"ref":"impl-draft1"}`). 한 번 약 15 ~ 25분(빌드 + 에뮬레이터). 무료 분량(계정 전체 월 2,000분)을 castle_M 과 같이 쓴다
- GitHub API 는 `gh` 없이 GCM 토큰으로 REST. 토큰을 파일 · 로그 · 커밋에 남기지 않는다

## 4. 사용자와 말하기 · 사용량
- castle_M CLAUDE.md 11절 그대로: 사용자에게는 한국어, 작업이 끝난 뒤 구분선 + 표지(✅ 결과 · 💬 답변 · ❓ 확인 요청) 한 덩어리, 질문은 번호를 달아 끝에, 선택지는 추천과 이유
- 작업 전 예상 비용($ 범위), 결과를 낼 때마다 `py -3.12 D:/claude/usage/usage_cost.py` 두 줄, 단계마다 추천 effort
- 세션 기록 `history/<날짜>_<작업자>_<주제>.md` — 머리에 시작 · 끝 누적 $ · 작업별 예상과 실제

## 5. 문서
- `docs/P1_요구사항정의서_3D초안.md` → `docs/P1_설계서_3D초안.md` → 코드 → `docs/P1_테스트결과서_3D초안.md`. 설계서의 인터페이스 세부는 코드 주석으로 대신한다(castle_M 2026-10-16 사용자 승인과 같게)
- 문서에 적은 명령은 적은 그대로 실행해 본다. 수치는 실행 출력을 복사하고 날짜를 적는다
