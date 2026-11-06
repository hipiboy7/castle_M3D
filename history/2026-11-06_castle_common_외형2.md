# 2026-11-06 castle_common ddeeb4c 받음 — 외형 2차(2장 하성 본사 인물 · 그리는 쪽 고침)
- 사용량: 측정 없음. 받기: `data/common/` ← castle_common ddeeb4c(looks.json blind_eye · bucket_hat · 김신 수염 · 흉터 없음 · 색 고침, canon 인물 · 조직 · 용어)
- 새 외형 이름(looks.gd LOOKS + looks_from_common NAMES 장 "2" + GLB · 도트): `kim_p1_blade`(김신 2장 = kim_bare + 군용 단검 — looks.json 에 2장 차림이 없어 1장 차림, GLB 는 kimshin_p1 공유 · 도트만 따로) · `sintaejin`(2장 '청소부' 비니 · 검은 롱코트) · `namgunghyuk`(금 너클) · `hwangbomincheol`(2장 흰 셔츠 · X 멜빵 · 단도 둘) · `iseul` · `ojiin`(쪽머리 · 펜슬 스커트 · 카타나) · `kimjaehoon`(조끼 · 권총) · `insu`(비니) · `gangchangseok`
- 엑스트라(LOOKS 만 — 관절 인형, 기존 엑스트라와 같이 그림 A · B 없음): `haseong_suit`(단도) · `haseong_guard`(턱수염 · 귀걸이 거구) · `namgu_youth`(검은 비니)
- looks_from_common.py: 장 번호는 periods chapters 로만 맞춤(label '2부' 가 2장으로 잡히던 것), stubble · blind_eye · hat(beanie · bucket) · 맑은 렌즈(lens clear → 검지 않은 안경 + 테 색) · skirt · vest · crew(티) · lips · 눈 세로 흉터(eye_l · eye_r) · bun
- puppet3d · make_models: 턱 수염 그늘은 stubble 일 때만(김신 수염 · 왼뺨 흉터 사라짐 — kimshin_a 다시 만듦), 모자 · 먼 눈 · 조끼(팔은 셔츠) · 스커트 · 쪽머리 · 너클, GLB 에 홀스터 X 멜빵 · 에비에이터 금테 · 맑은 안경, 짧은 머리 정수리 살 비침(인형) · 바가지 머리(GLB crew · buzz · short) 고침
- 검토: shot_looks(이름 끝 _a 면 GLB)로 찍어 원작 조각(castle_common work/looks/ref)과 서브에이전트 3개가 대조 → 한 차례 고침(머리 · 수염 그늘 색 · 비니 높이 · 스커트 길이 · 색)
- 남은 것: 김신 2부(kim) GLB 머리 · 셔츠 V 가 약함(앞 차 그대로), 오지인 여성 몸매는 비율만, 비니 아래 머리 일부 가려짐
- 검증: `python3.11 scripts/verify.py` 21/21 통과 · 84초
- 다음: 3D 세션이 2장(하성 본사) 장 표에서 위 외형 이름을 쓴다
