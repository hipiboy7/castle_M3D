# 2026-11-23 Antigravity — 그래픽 · 캐릭터 · UI/UX 전면 개선 v2 & rc.19 로컬 빌드·릴리스
- 사용량: 측정 없음(서버에 `~/claude/usage/usage_cost.py` 없음 — 기준일 2026-10-01 기준 수동/외부 콘솔 확인 필요)
- 브랜치: `impl-graphics-v2` (from `impl-draft1` `982638f`) → push · 태그 `v0.7.0-rc.19` · GitHub Releases Latest 업로드 완료
- Phase 1(셰이더 · 폰트 · APK): GPU LUT(`assets/textures/ink_lut.png`)로 FBM/보로노이 루프 제거 · 광원 클램프+Bloom 1.45 과노출 제거 · 부위별 셰이딩(`ink_cel.gdshader`) · 거리 적응 컬러 먹선(`ink_line.gdshader`) · 벡터 폰트(Pretendard/BlackHanSans, SIL OFL) · `export_presets.cfg` 미사용 `assets/sprites/*` 제외
- Phase 2(UI/UX · 카메라 · VFX): 느와르 HUD(지연 데미지 트레일 · 상단 리본 알림으로 말풍선 겹침 제거 · 미니바/`!` 분리) · 4+2 엄지 아크 터치 UI(Z Fold 4 반응형 · 실시간 스킬 링 · 벡터 아이콘) · 타이틀/스테이지 느와르 카드 · 컷신 31° 저각도 카메라 · 붓칠 먹선 궤적(`slash_vfx.gdshader`) · 인체 실루엣 잔상 · 웹툰 임팩트 프레임(`grade.gdshader`)
- Phase 3(캐릭터 v2 — 130 GLB 재베이크): `tools/face_painter.gd` 2D 웹툰 4표정 아틀라스 · 멜론 줄무늬 제거 · 리사 모피 망토 연속 로프트 · 3본 스키닝 스커트 · `Glasses`/`HairLoose` 분리 서브메시(`remove_glasses` 복구) · 콘택트 섀도 · `_dome` 감기 방향 수정(정수리/어깨 검은 구멍 제거)
- Phase 4(소품 · 색보정 · 규칙): 장별 컬러 스크립트(`Ink.GRADE_PRESETS`) · 소파/화분/원탁/안락의자/바/당구대/차량·가로등 빛기둥 업그레이드 · AGY Rule `AGENTS.md`→`CLAUDE.md` 링크 추가 · `docs/폰확인.md` rc.19 갱신
- 검증 · 빌드: `verify.py --strict` 26/26 통과(174/174 단위 테스트 · 커버리지 A 100%/B 98% · 자산 출처 404/404) · 로컬 APK 빌드 `versionCode 90` (`castle_m3d-v0.7.0-rc.19.apk`, 디버그 키 SHA-256 일치 · `data/common/*.json` 5개 포함 · `cases/canon/sprites` 제외) → GitHub Releases Latest 게시
- 다음: 사용자 갤럭시 Z 폴드 4 실기 리뷰(rc.19 + rc.18 이월 항목) → 피드백 반영 → `impl-draft1` / `main` 병합 여부 확인

## 새 세션 첫 프롬프트
```
castle_M_3D 이어서. AGENTS.md(→CLAUDE.md)와 history/2026-11-23_Antigravity_그래픽·캐릭터·UI개선.md 읽고, v0.7.0-rc.19(impl-graphics-v2) 폰 실기 리뷰 피드백 반영부터 진행해줘.
```
