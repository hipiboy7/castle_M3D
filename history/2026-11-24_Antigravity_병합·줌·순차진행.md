# 2026-11-24 Antigravity — 병합 · 줌 · 순차 진행 · 실사 PBR + CC0 모캡 파일럿

- **사용량**: 측정 없음 (`~/claude/usage/usage_cost.py` 없음)
- **브랜치**: `impl-draft1` (`impl-graphics-v2` `--no-ff` 병합 + 줌/순차 진행 + 실사 파일럿)
- **한 일**:
  - `impl-graphics-v2` → `impl-draft1` 병합(`0ceb83e`), 카메라 줌 조절(버튼·핀치·메뉴·세이브) 및 스테이지 순차 진행(`'메뉴'` 제외) 구현(`d00a828`).
  - 포터블 Blender 4.2.23 + MPFB2 + MakeHuman CC0 팩(`/data/users/juho.hong/tools/blender`, 미커밋) 구축 및 `tools/bake_realistic.py` 작성 → **실사 PBR 파일럿 9종 GLB**(김신 정장/코트/1부 · 백도찬 · 리사 프롤로그/본편 · 서진태 · 오지인 · 의뢰인, 18k tris · ~1.7–2.4MB, 100% CC0).
  - Quaternius Universal Animation Library CC0 20클립을 17본으로 리타게팅(`tools/bake_anims.py` → `assets/animations/humanoid_cc0.glb` 432KB) + `src/view/mocap_driver.gd` + `tests/unit/test_mocap.gd` + `puppet_glb.gd` 실사 PBR(카툰 먹선 제거 · Burley/GGX · BoneAttachment3D 무기 · 모캡 블렌딩) 연동.
  - 검증: `python3.11 scripts/verify.py` 통과(179/179 테스트, 커버리지 A 100% / B 98%, 리플레이 해시 일치) + Xvfb 전 캐릭터·인게임 육안 확인.
- **다음 단계**: ① 사용자 비교 캡처 확인 후 `impl-draft1` 푸시 + `v0.7.0-rc.20` 로컬 APK 빌드·릴리스 ② 나머지 주요 인물 실사 PBR 확대 여부 결정.
- **새 세션 첫 프롬프트**:
```text
CLAUDE.md와 history/2026-11-24_Antigravity_병합·줌·순차진행.md를 읽고 impl-draft1 상태를 확인해줘.
실사 PBR + CC0 모캡 파일럿 확인 결과야: (여기에 피드백 입력 — rc.20 빌드·릴리스 / 추가 캐릭터 실사 확대 등)
```
