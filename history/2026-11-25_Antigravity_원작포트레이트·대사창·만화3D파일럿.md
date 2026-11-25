# 2026-11-25 Antigravity — 원작 웹툰 포트레이트 · 전 챕터 대사창 · 대형 컷인 · 3단계 만화 3D 파일럿(rc.22)
- 사용량: 측정 없음(도구 없음) · 브랜치: `impl-draft1` · 릴리스: `v0.7.0-rc.22` (`versionCode 93`) · `castle_common` `a02b729` 일치
- 한 일:
  1. **원작 웹툰 2D 포트레이트/컷인(작가 협의 완료)**: `tools/extract_canon_portraits.py` 로 113인 스탠딩/HUD + 36인 파노라마 컷인 추출(`assets/portraits/*.jpg`, 5.59MB) 및 `portraits_data.gd` 자동 생성(구 AI PNG 제거)
  2. **전 챕터 웹툰 대사창 & 대형 컷인**: 0~13장 대화 전반을 스탠딩+이름표 리본+대사창(`webtoon_stage.gd` · `event_fx.gd`, 전투 중 상단 컴팩트 토스트)으로 전환 · 컷인 68pt 대형 붓글씨 · 6장 첫 컷인 1.55s · 쳐내기 첫 성공 1회 한정(`should_cutin_parry`)
  3. **타이틀 데모 복귀 & 프롤로그 연출**: 데모 중 터치 시 타이틀 4버튼+난이도 화면 복귀 · 0장 주점 의뢰인 추적 카메라 + 김신 숨김 → 리사 은퇴식 멘트 직후 스포트라이트 리빌 + `아무르 티그로` 컷인(`prologue.gd` · `scene.gd` · `world3d.gd` · `lines.json`)
  4. **3단계 로컬 만화 3D 파일럿 9종**: `tools/prep_webtoon_faces.py` + `tools/bake_webtoon3d.py` + `src/view/shaders/webtoon_3d.gdshader` 로 김신(3종)·백도찬·서진태·오지인·리사(2종)·의뢰인 원작 얼굴 투영 + 두개골 실표면 래핑 만화 헤어 + 셀/잉크 셰이더 굽기 완료(Xvfb 턴어라운드·실기 4장면 검수 완료)
  5. **검증 · 빌드 · 릴리스**: `verify.py --strict` **26/26 통과**(테스트 184/184 · 커버리지 A 100% / B 98%), 로컬 APK 서명/badging/`data/common/*.json` 검증 후 `v0.7.0-rc.22` Latest 릴리스
- 다음 단계: Z Fold 4 실기에서 `docs/폰확인.md` 체크리스트 7항목 확인 → 피드백 반영 및 3단계 만화 3D 모델 나머지 주요 보스/아군(피우진·김대건·남궁혁·군터·윤덕수·구스타프·신겐 등) 확장
- 새 세션 첫 프롬프트:
```
CLAUDE.md와 history/2026-11-25_Antigravity_원작포트레이트·대사창·만화3D파일럿.md를 읽고 impl-draft1(v0.7.0-rc.22) 상태를 확인해줘. 폰 실기 확인 결과를 공유할 테니 피드백 반영과 나머지 주요 캐릭터 3단계 만화 3D 확장을 이어서 진행하자.
```
