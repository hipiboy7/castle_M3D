# 캐슬 M 3D (초안)

네이버 웹툰 「캐슬」 팬게임 [castle M](../castle_M) 의 **3D 시험판** — 비공식 · 비영리 · 비공개.
인천항 제3부두의 밤, 김신 대 백도찬 1:1 결투 한 판을 Godot 4 로 만들어 폰에서 2D 판과 비교하고 엔진 이전을 정한다
(castle_M 보류 결정 #9).

## 빠른 시작 (Windows 개발 서버 — 창을 띄우지 않는다)

```
py -3.12 scripts/get_godot.py     # Godot 4.7.2 를 .tools/ 에 받는다 (처음 한 번, 약 80MB)
py -3.12 scripts/verify.py        # 가져오기 · 테스트 · 자동 결투 3판 (약 15초)
```

APK 와 화면은 GitHub Actions 가 만든다(`.github/workflows/android.yml`): `build` 잡의 `castle_m3d-apk`(폰 · 에뮬레이터 겸용 APK)와
`shots`(PC · 폰 크기 스크린샷), `emulator` 잡의 `emulator`(에뮬레이터 스크린샷 · logcat · FPS).

## 조작

| 동작 | 폰 | 키보드 |
|---|---|---|
| 이동 | 왼쪽 절반 아무 데나 누르고 끌기 | WASD · 방향키 |
| 베기 (3연타 · 빈틈이면 제압 · 쳐낸 직후면 반격) | 베기 | J · Z |
| 칼날 쳐내기 (누르고 있으면 막기) | 쳐내기 | K · X |
| 구르기 (무적) | 구르기 | Space · L · C |

흰 ! 는 커지며 깜빡일 때 쳐내기, 빨간 ! 는 쳐낼 수 없으니 구르기. 체간(노란 막대)이 차면 빈틈 → 베기가 제압.
첫 화면에서 6초 동안 가만히 두면 데모(봇 대 백도찬)가 돈다.

## 구조

- `src/combat/` 판정 · AI (순수 로직, 테스트 `tests/test_combat.gd`) — 수치 원본은 castle_M `castle_m/action/moves.py`
- `src/view/` 3D 관절 인형 · 무대 · 연출 · 카메라, `src/ui/` 화면 표시 · 터치, `src/main.gd` 본체
- 문서: `docs/P1_요구사항정의서_3D초안.md` · `docs/P1_설계서_3D초안.md` · `docs/P1_테스트결과서_3D초안.md`, 작업 규칙 `CLAUDE.md`
- 소리 · 음악은 castle_M `tools/gen_sfx.py` · `tools/music.py` 생성물을 복사했다. 글꼴 Galmuri11 Bold(SIL OFL 1.1, `assets/fonts/LICENSE.txt`)
