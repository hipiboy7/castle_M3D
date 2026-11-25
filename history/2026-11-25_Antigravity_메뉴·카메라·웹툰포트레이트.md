# 2026-11-25 Antigravity — 타이틀 4버튼 메뉴 · 카메라 하향 · 2D 웹툰 포트레이트/컷인 파일럿

- **사용량**: 측정 없음 (`~/claude/usage/usage_cost.py` 없음) · 모델 Gemini 4 Neon (XHigh)
- **브랜치**: `impl-draft1` (`v0.7.0-rc.21` 준비, `versionCode 92`)
- **한 일**:
  - **타이틀 4버튼 메뉴**: `이어서 하기 / 스테이지 선택 / 처음부터 / 끝내기` 수직 느와르 메뉴 구현(`title_menu.gd` · `main.gd` · `lines.json` · `touch_ui.gd` 타이틀 `난이도`만 유지 · 타이틀 중 전투 HUD 숨김, `tests/unit/test_ui_logic.gd` Z Fold 4 전 비율 검증).
  - **카메라 앵글 하향**: `camera_rig.gd` 57° 탑뷰 → **35.4° 전투 쿼터뷰** · 31° → **19.6° 눈높이 컷신 앵글**(기존 줌/핀치 유지).
  - **2D 웹툰 포트레이트 · 스탠딩 · 사선 컷인 · HUD 파일럿**: 원작 픽셀 미사용 신규 느와르 웹툰 일러스트 6인 스탠딩/HUD(김신·백도찬·리사·서진태·오지인·의뢰인) + 4인 사선 눈매 컷인(김신·백도찬·서진태·오지인) 생성·후처리(`tools/process_portraits.py` → `assets/portraits/*.png` 16개 4.4MB, `assets/ASSETS.md` 등록) 및 통합(`src/view/portraits.gd` · `src/ui/webtoon_stage.gd` · `src/ui/hud.gd` · `src/view/event_fx.gd` · `tests/unit/test_portraits.gd`).
  - Xvfb 실기 스크린샷 검증(타이틀 · 프롤로그 대화 스탠딩 · 6장 백도찬 컷인 · HUD 초상화), `python3.11 scripts/verify.py --strict` **26/26 통과**(테스트 183/183 · 커버리지 A 100%/B 98%), 로컬 APK(`v0.7.0-rc.21`, versionCode 92) 빌드·서명·내용 검증 완료.
- **다음 단계**: ① 사용자 확인 후 `impl-draft1` 푸시 · 태그 `v0.7.0-rc.21` · GitHub Releases Latest 발행 ② 폰 실기 확인 후 3단계(로컬 Blender 웹툰/애니 8.5등신 베이스메시 + 3D 조각 만화 헤어 + 느와르 만화 셰이더 3인 파일럿) 착수.
- **새 세션 첫 프롬프트**:
```text
CLAUDE.md와 history/2026-11-25_Antigravity_메뉴·카메라·웹툰포트레이트.md를 읽고 impl-draft1 (v0.7.0-rc.21) 상태를 확인해줘.
폰 실기 확인 결과야: (여기에 피드백 입력 — 타이틀 4버튼 메뉴 · 카메라 각도 · 2D 웹툰 스탠딩/컷인/HUD 체감 → 3단계 로컬 만화 3D 모델 파일럿 진행 여부)
```
