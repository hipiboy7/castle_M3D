# 2026-11-06 castle_common 세션 — 공통 인물 외형(data/looks.json) 받기

- 사용량: 측정 없음(castle_common 세션 원장에 적음)
- 한 일: castle_common `data/looks.json`(답58 인물 그림 다시 점검 L1 · L2) 받음 → `tools/looks_from_common.py` 가 `src/view/looks_common.gd` 를 만들고 `looks.gd` look() 이 그 값을 먼저 쓴다 · `make_models.gd` 가 Looks.look 으로 GLB 를 만든다 · `tools/shot_looks.gd`(외형 확인 찍기) · `scripts/verify.py` 외형 생성물 줄. GLB 7 · 도트 7 다시 만듦.
- 검증: `python3.11 scripts/verify.py` 21/21 통과(84초).
- 합의: 이 판 세션은 looks.gd · puppet3d.gd · 모델 도구를 castle_common 세션이 L3 를 끝낼 때까지 안 건드린다.
- 다음: castle_common L3 검토 지적 반영 뒤 looks.json 을 다시 받아 GLB · 도트를 다시 만든다(같은 세션이 한다).
