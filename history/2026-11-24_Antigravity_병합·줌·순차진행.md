# 2026-11-24 Antigravity — 병합 · 줌 · 순차 진행 · 실사 PBR + CC0 모캡 파일럿

- **사용량**: 측정 없음 (`~/claude/usage/usage_cost.py` 없음)
- **브랜치**: `impl-draft1` (`impl-graphics-v2` `--no-ff` 병합 + 줌/순차 진행 + 실사 파일럿)
- **한 일**:
  - `impl-graphics-v2` → `impl-draft1` 병합(`0ceb83e`), 카메라 줌 조절(버튼·핀치·메뉴·세이브) 및 스테이지 순차 진행(`'메뉴'` 제외) 구현(`d00a828`).
  - 포터블 Blender 4.2.23 + MPFB2 + MakeHuman CC0 팩(`/data/users/juho.hong/tools/blender`, 미커밋) 구축 및 `tools/bake_realistic.py` 작성 → **실사 PBR 파일럿 9종 GLB**(김신 정장/코트/1부 · 백도찬 · 리사 프롤로그/본편 · 서진태 · 오지인 · 의뢰인, 18k tris · ~1.7–2.4MB, 100% CC0).
  - Quaternius Universal Animation Library CC0 20클립을 17본으로 리타게팅(`tools/bake_anims.py` → `assets/animations/humanoid_cc0.glb` 432KB) + `src/view/mocap_driver.gd` + `tests/unit/test_mocap.gd` + `puppet_glb.gd` 실사 PBR(카툰 먹선 제거 · Burley/GGX · BoneAttachment3D 무기 · 모캡 블렌딩) 연동(`1a2c74d`).
  - `docs/폰확인.md` · `CLAUDE.md` 갱신, `python3.11 scripts/verify.py --strict` 통과, `impl-draft1` 푸시 및 `v0.7.0-rc.20`(versionCode 91) 로컬 APK 빌드 · GitHub Releases **Latest** 발행.
- **다음 단계**: ① 폰에서 `v0.7.0-rc.20` 실기 확인(줌 · 순차 진행 · 실사 PBR 파일럿 9종 · CC0 모캡 · 실기 FPS) ② 피드백에 따라 나머지 주요 인물 실사 PBR 확대 및 추가 폴리싱.
- **새 세션 첫 프롬프트**:
```text
CLAUDE.md와 history/2026-11-24_Antigravity_병합·줌·순차진행.md를 읽고 impl-draft1 (v0.7.0-rc.20) 상태를 확인해줘.
폰 실기 확인 결과야: (여기에 피드백 입력 — 실사 톤 · CC0 모캡 · 줌 · 순차 진행 · FPS / 나머지 캐릭터 실사 확대 여부 등)
```
