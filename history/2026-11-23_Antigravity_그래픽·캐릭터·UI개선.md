# 2026-11-23 Antigravity — 그래픽 · 캐릭터 · UI/UX 전면 개선 (impl-graphics-v2)
- 브랜치: `impl-graphics-v2` (from `impl-draft1` `982638f`), 추천안 1~3번 일괄 수행
- Phase 1(셰이더 · 폰트 · APK 경량화): 공유 GPU LUT(`tools/gen_ink_lut.py` → `assets/textures/ink_lut.png`)로 프래그먼트 FBM/보로노이 루프 제거 · 광원 소프트 클램프+Bloom 임계 1.45로 흰옷/클럽 과노출 제거 · 피부/머리/옷/가죽 부위별 셰이딩 분리(`ink_cel.gdshader`) · 거리 적응+부위별 컬러 먹선(`ink_line.gdshader`) · 벡터 한글 폰트(`Pretendard-Bold.otf` · `BlackHanSans-Regular.ttf`, SIL OFL, `ASSETS.md` 등록) · `export_presets.cfg` 미사용 `assets/sprites/*` APK 제외
- Phase 2(UI/UX · 카메라 · VFX): 느와르 HUD 전면 개편(지연 데미지 트레일 · 체간 과열 펄스 · 전투/장면 알림 상단 리본으로 이동해 말풍선 겹침 제거 · 미니바/예고 `!` 높이 분리) · 터치 UI 4+2 엄지 호+Z Fold 4 반응형 스케일+실시간 스킬 게이지 링+벡터 아이콘 · 타이틀/스테이지 메뉴 느와르 카드화(`test_ui_logic` 계약 보존) · 장면 연출 저각도 시네마틱 카메라(`camera_rig.gd` 31°) · 붓칠 먹선 칼 궤적(`slash_vfx.gdshader`) · 인체 실루엣 잔상 · 패리/엇박/제압 웹툰 임팩트 프레임(`grade.gdshader`)
- Phase 3(캐릭터 모델 v2 — 130 GLB 일괄 재베이크): `tools/face_painter.gd` 2D 웹툰 4표정(평소/분노/피격/기절) 아틀라스 + `make_models.gd` v2 풀컬러 512² 아틀라스 · 정수리 멜론 먹선 제거 · 리사 모피 망토 연속 로프트 · 3본 스키닝 스커트(관통 제거) · `Glasses`/`HairLoose` 분리 서브메시(`remove_glasses` 복구) · 발밑 콘택트 섀도(`contact_shadow.gdshader`) · `_dome` 감기 방향 버그 수정으로 정수리/어깨 검은 구멍 제거
- Phase 4(소품 · 색보정): 장별 컬러 스크립트(`Ink.GRADE_PRESETS`) · 소파/화분/원탁/안락의자/바/당구대/차량 디테일 상향 · 가로등/당구대 초경량 빛기둥 원뿔(광원 0 추가) · 클럽 바닥 반투명 디스크
- 검증: `verify.py` 26/26 통과(174/174 단위 테스트 · 커버리지 A 100%/B 98% · 리플레이 결정성 · 자산 출처 404/404) · 가상 화면 6장면 + 캐릭터 7종 육안 검수 완료 · 11장 `--crowd 30` `perf_probe` 트라이앵글 35% 절감(캐릭터당 ~6.2k tris)
- 다음: 사용자 확인 후 `impl-graphics-v2` push · 폰 실기 확인용 APK 빌드/릴리스 · 필요 시 Track B(외부 CC0/Blender 베이스 바디) 검토

## 새 세션 첫 프롬프트
```
castle_M_3D 이어서. 브랜치 impl-graphics-v2 에서 history/2026-11-23_Antigravity_그래픽·캐릭터·UI개선.md 읽고, 사용자 피드백(폰 실기 확인 또는 push/APK 빌드)부터 진행해줘.
```
