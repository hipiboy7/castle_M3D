extends RefCounted
## 원작 기술 전용 동작(3층) — 사용자 2026-11-10 "이름 별로 각각 행동을 다 구체화해. 그 다음에 기술에 따른 행동을 다 구체화해서 반영".
## 기술마다 원작(castle_common canon techniques · refs 화/컷)에서 몸이 하는 일을 적고(주석) 그대로 동작 값으로 옮겼다 — 처음 값은
## 사양 작성 에이전트 2026-11-10(갈래로 원형 동작을 돌려 쓰던 것을 대신한다). 필드 뜻은 moves.gd DEFAULTS. moves.gd get_move 가 M 다음에 본다.
## BY_SKILL: 기술 id → 동작 id (skill_kit 가 원작 표 · 1층 기술 모두 이것으로 고른다). OVERRIDE: 이미 있던 전용 동작에 덧씌우는 칸
## (원작과 어긋난 모양 · 대 수 — 예: 구일화 들이받기를 박치기 자세로). conf ai(묘사뿐) 기술은 연출 근거가 약하다 — [근거] 주석.

const M := {
	# andycheong · 갈고리 걸어 묶기 — 갈고리 날을 바깥으로 쥐고 상대 칼을 기다린다(준비) → 들어온 단검을 갈고리 안쪽 굽이로 걸어 손목째 묶고 몸을 바짝 붙인다(실행, 027/053-061 '떨어지질 않는다?') → 묶인 채 다음 동작으로(027/150 '카각'). [근거: conf ai — 효과음 · 속말뿐, 기술명 없음. 쌍 갈고리(후크소드)는 weapon other]
	"tk_andy_hook_bind": {"startup": 18, "active": 3, "recovery": 14, "damage": 6, "reach": 13, "radius": 10, "arc": 60, "lunge": 4, "knockback": 0.6, "hitstop": 6, "posture": 12, "telegraph": "parry", "shape": "guard_counter", "sfx": "slash", "stance": 14, "label": "갈고리 걸어 묶기", "skill": true, "stance_hit": "tk_andy_hook_bind_hit"},
	# andycheong · 갈고리 걸어 묶기 맞받기
	"tk_andy_hook_bind_hit": {"startup": 2, "active": 4, "recovery": 12, "damage": 8, "reach": 12, "radius": 10, "lunge": 6, "knockback": 0.4, "hitstop": 12, "posture": 26, "shape": "grab", "sfx": "slash", "hit_sfx": "hit_heavy", "shake": 3, "parryable": false, "stun_3d": [30, 24], "label": "갈고리 걸어 묶기", "skill": true},
	# andycheong · 뛰어넘으며 베기·셔츠 가르기 — 칼이 묶여 상대 상체가 숙여진 순간(준비, 027/064-065 낮은 자세) 상대 머리 위로 거꾸로 뛰어넘으며(070) → 양손 갈고리를 맞물려 셔츠 앞섶을 가르고 낮게 지나 착지한다(073 '앗'). [근거: conf ai — 묘사(070 도약 · 073 가르기)]
	"tk_andy_hook_slash": {"startup": 14, "active": 5, "recovery": 18, "damage": 15, "reach": 14, "radius": 11, "arc": 90, "lunge": 34, "knockback": 2.4, "hitstop": 9, "posture": 20, "iframes": true, "telegraph": "unblock", "parryable": false, "shape": "cross", "sfx": "slash", "hit_sfx": "hit_heavy", "shake": 3, "whiff": 16, "label": "뛰어넘으며 베기·셔츠 가르기", "skill": true},
	# andycheong · 쌍 갈고리 자세 — 양손 손가락에 초승달 갈고리를 끼워 늘어뜨렸다가(준비, 026/160) 두 팔을 얼굴 양옆으로 들어 날을 세운다(161) → 세운 날로 한 번 겨누는 척하고 두 갈고리를 앞으로 짧게 찔러 걸어 당긴다. [근거: conf ai — 원작은 자세(겨눔)뿐이고 공격 장면은 없다. 게임용으로 짧은 견제 두 대로 만듦]
	"tk_andy_hook_stance": {"startup": 12, "active": 8, "recovery": 12, "damage": 6, "reach": 14, "radius": 9, "arc": 40, "lunge": 8, "hits": 2, "knockback": 0.8, "hitstop": 4, "posture": 9, "telegraph": "parry", "feints": [6], "shape": "thrust", "seq": ["thrust", "slash_back"], "sfx": "slash", "label": "쌍 갈고리 자세", "skill": true},
	# barista · 바리스타 곡도 베기 — 몸을 낮추고 상대 약점을 읽다가(준비) → 곡도를 옆으로 낮게 그어 배 · 허벅지를 가르고 되돌려 목을 긋는다(실행, p1:082/003 낮게 가르는 곡선 · 081/013 '써악') → 칼을 들어 품평하며 거리를 둔다. [근거: conf ai — 곡도 쥔 손이 가려진 컷 있음]
	"tk_barista_curved_blade": {"startup": 14, "active": 9, "recovery": 16, "damage": 8, "reach": 16, "radius": 10, "arc": 120, "lunge": 12, "hits": 2, "knockback": 2.4, "hitstop": 7, "posture": 14, "telegraph": "parry", "shape": "slash", "seq": ["slash", "slash_back"], "sfx": "slash", "hit_sfx": "hit_heavy", "shake": 2, "label": "바리스타 곡도 베기", "skill": true},
	# barista · 바리스타 총 붙잡기·맨손 칼날 잡기 — 맞붙는 순간을 기다리다(준비) → 총 · 칼 든 상대 손목을 붙잡아 총구를 바닥 · 허공으로 돌린다(실행, p1:065/017 · 029) → 반대손 곡도로 그대로 벤다(상대가 무기를 놓침). [근거: conf ai — 081/008 쪽 '동시에 붙잡음'은 확인 못 함(065 손목 잡기만 확인)]
	"tk_barista_gun_handling": {"startup": 16, "active": 3, "recovery": 14, "damage": 5, "reach": 12, "radius": 10, "lunge": 6, "knockback": 0.6, "hitstop": 5, "posture": 14, "telegraph": "parry", "shape": "grab", "sfx": "wind", "stance": 12, "label": "바리스타 총 붙잡기·맨손 칼날 잡기", "skill": true, "stance_hit": "tk_barista_gun_handling_hit"},
	# barista · 바리스타 총 붙잡기·맨손 칼날 잡기 맞받기
	"tk_barista_gun_handling_hit": {"startup": 2, "active": 8, "recovery": 14, "damage": 8, "reach": 13, "radius": 10, "arc": 80, "lunge": 6, "hits": 2, "knockback": 2.6, "hitstop": 9, "posture": 22, "parryable": false, "shape": "grab", "seq": ["grab", "slash_back"], "sfx": "slash", "hit_sfx": "hit_heavy", "shake": 3, "label": "바리스타 총 붙잡기·맨손 칼날 잡기", "skill": true},
	# barista · 바리스타 맨손 타격 — 말을 끊고 상대를 내려다보다(준비) → 주먹을 올려 치고 몸통을 두드린 뒤 무릎을 올려 찬다(실행, p1:083/001 무릎 · 084/067-069) → 상대 고개가 꺾이고 피가 튄다. [근거: conf ai — 다리 쓸기 · 머리채 메다꽂기는 확인 못 함(뺌)]
	"tk_barista_strike": {"startup": 11, "active": 12, "recovery": 15, "damage": 7, "reach": 12, "radius": 10, "arc": 60, "lunge": 8, "hits": 3, "knockback": 1.2, "hitstop": 6, "posture": 11, "telegraph": "parry", "shape": "uppercut", "seq": ["uppercut", "body_blow", "knee"], "sfx": "kick", "hit_sfx": "hit_heavy", "shake": 2, "label": "바리스타 맨손 타격", "skill": true},
	# deumiteuri · 드미트리 메스 — 메스를 쥐고 비웃다가(준비, p1:075/006) 피 담긴 통을 비스듬히 던져 얼굴에 끼얹고('촤') → 눈이 가려진 상대에게 곧장 오른 주먹을 꽂는다(실행, 075/006 '그래도 상황은 똑같다'). [근거: conf ai — 메스 투척은 컷으로 확인 못 함. 피 끼얹기 → 주먹만 씀(메스는 손에 든 그림)]
	"tk_deumiteuri_scalpel": {"startup": 10, "active": 10, "recovery": 16, "damage": 9, "reach": 14, "radius": 12, "arc": 70, "lunge": 8, "hits": 2, "knockback": 3.0, "hitstop": 8, "posture": 18, "parryable": false, "telegraph": "unblock", "shape": "palm", "seq": ["palm", "straight"], "sfx": "wind", "hit_sfx": "hit_heavy", "shake": 3, "stun_3d": [30, 20], "label": "드미트리 메스", "skill": true},
	# douchen · 악력 움켜쥐기 · 맞잡기 — 발차기 · 골프채 · 옷이 들어오기를 기다리다(준비) → 맨손으로 움켜쥐어 짓누르고 꺾는다(실행, 038/124 골프채 샤프트 · 039/007-009 구두를 두 손으로) → 상대가 돌려차기로 겨우 빠진다. [근거: conf ai — 효과음뿐]
	"tk_douchen_grip": {"startup": 20, "active": 4, "recovery": 16, "damage": 8, "reach": 12, "radius": 11, "lunge": 8, "knockback": 0.4, "hitstop": 8, "posture": 18, "telegraph": "parry", "shape": "grab", "sfx": "wind", "stance": 16, "label": "악력 움켜쥐기 · 맞잡기", "skill": true, "stance_hit": "tk_douchen_grip_hit"},
	# douchen · 악력 움켜쥐기 · 맞잡기 맞받기
	"tk_douchen_grip_hit": {"startup": 2, "active": 4, "recovery": 16, "damage": 12, "reach": 13, "radius": 11, "lunge": 4, "knockback": 0.4, "hitstop": 14, "posture": 32, "parryable": false, "guard_break": true, "shape": "grab", "sfx": "wind", "hit_sfx": "hit_heavy", "shake": 4, "stun_3d": [60, 40], "label": "악력 움켜쥐기 · 맞잡기", "skill": true},
	# douchen · 도우첸 맷집 한 방 — 숨을 참고 상대 연타를 맞아 준 뒤(준비, 038/107 '저걸 버텨..?') → 손바닥으로 얼굴을 덮듯 후려치고 이어 몸통이 빈 곳에 큰 훅을 꽂는다(실행, 038/104 · 039/089-092) → 상대 고개가 젖혀지고 피가 튄다. [근거: conf ai — '맞아 줌'(아머)은 동작 표 필드가 없다. 필요하면 구현자가 판단]
	"tk_douchen_heavy_punch": {"startup": 18, "active": 12, "recovery": 18, "damage": 10, "reach": 13, "radius": 12, "arc": 100, "lunge": 8, "hits": 2, "knockback": 3.6, "hitstop": 9, "posture": 18, "telegraph": "parry", "shape": "palm", "seq": ["palm", "hook"], "sfx": "kick", "hit_sfx": "hit_heavy", "shake": 3, "label": "도우첸 맷집 한 방", "skill": true},
	# douchen · 얼굴 움켜잡아 내리꽂기 — 상대 얼굴 · 몸통을 움켜잡고(준비, 042/019 포효하며 끌어안음) → 코트를 날리며 디뎌 끌어당겨 머리부터 아래로 내리꽂는다(실행, 038/164-165 앞유리 '콱' · 042/021 '쾅') → 누운 상대를 내려다본다. [근거: conf ai — 효과음뿐]
	"tk_douchen_slam": {"startup": 20, "active": 8, "recovery": 22, "damage": 10, "reach": 12, "radius": 10, "lunge": 14, "hits": 2, "parryable": false, "guard_break": true, "knockdown": true, "knockback": 1.8, "hitstop": 14, "posture": 18, "telegraph": "unblock", "shape": "grab", "seq": ["grab", "throw_slam"], "sfx": "wind", "hit_sfx": "hit_heavy", "shake": 6, "stun_3d": [40, 30], "whiff": 20, "label": "얼굴 움켜잡아 내리꽂기", "skill": true},
	# eunbo · 은보 끌어안아 메치기 — 덩치로 정면에서 덮쳐(준비, 026/072 끌어안아 안경이 날아감) → 들어 올려 어깨 너머로 뒤집어 메친다(실행, 026/094) → 둘이 같이 카펫 바닥에 처박힌다(103). [근거: conf ai — 묘사]
	"tk_eunbo_throw": {"startup": 22, "active": 8, "recovery": 26, "damage": 11, "reach": 12, "radius": 11, "lunge": 30, "hits": 2, "parryable": false, "guard_break": true, "knockdown": true, "knockback": 2.4, "hitstop": 14, "posture": 20, "telegraph": "unblock", "shape": "tackle", "seq": ["tackle", "throw_slam"], "sfx": "wind", "hit_sfx": "hit_heavy", "shake": 6, "whiff": 24, "label": "은보 끌어안아 메치기", "skill": true},
	# gangchangseok · 칼 베기 — 웃으며 몸을 낮추고 칼을 반대 손으로 넘겨 쥐었다가(준비, p1:013/025) → 가슴 높이로 수평 원호를 그어 가슴 · 배를 벤다(실행, 018/111) → 그대로 곁을 지나간다. [근거: conf ai — 기술명 없음. 지금 cs_pass 와 거의 같다(옆 비낌만 더함)]
	"tk_gcs_slash": {"startup": 15, "active": 4, "recovery": 13, "damage": 11, "reach": 15, "radius": 10, "arc": 130, "lunge": 24, "side": 8, "knockback": 2.2, "hitstop": 6, "posture": 13, "telegraph": "parry", "shape": "slash", "sfx": "knife", "hit_sfx": "hit_heavy", "label": "칼 베기", "skill": true},
	# gangmanjae · 큰 휘두르기·보디블로 — 하이가드로 성큼 내딛어(준비) → 큰 오른손을 휘두르고 상체를 젖혀 낮춘 채 시계 찬 주먹을 복부 깊이 꽂는다(실행, p1:005/019 · 006/005) → 상대가 주저앉아 기침하고 만재가 내려다본다. [근거: conf ai — 이름 표지 없음(흉터 얼굴로 귀속)]
	"tk_gmj_punch": {"startup": 19, "active": 14, "recovery": 18, "damage": 11, "reach": 14, "radius": 12, "arc": 110, "lunge": 8, "hits": 2, "knockback": 1.6, "hitstop": 10, "posture": 20, "telegraph": "parry", "shape": "hook", "seq": ["hook", "body_blow"], "sfx": "swing", "hit_sfx": "hit_heavy", "shake": 3, "stun_3d": [40, 30], "label": "큰 휘두르기·보디블로", "skill": true},
	# grolla · 칼 베기 · 내리꽂기 — 단검을 쥐고(준비, 062/079) 칼을 뒤로 뻗어 높게 노리는 척하다가 → 호를 그려 다리를 낮게 긋고(092/012 '..페인트!') 넘어진 상대에게 단검을 위에서 내리꽂는다(062/092 '푹'). [근거: conf ai]
	"tk_grolla_blade": {"startup": 16, "active": 10, "recovery": 16, "damage": 9, "reach": 15, "radius": 9, "arc": 70, "lunge": 12, "hits": 2, "knockback": 2.0, "hitstop": 8, "posture": 16, "telegraph": "parry", "feints": [7], "shape": "thrust_low", "seq": ["thrust_low", "reverse_stab"], "sfx": "knife", "hit_sfx": "hit_heavy", "shake": 2, "label": "칼 베기 · 내리꽂기", "skill": true},
	# grolla · 발차기 — 기둥을 등지거나 품으로 파고들어(준비, 089/017) → 몸을 틀어 높은 돌려차기(하이킥)를 머리 · 가슴에 꽂는다(실행, 090/017) → 코트가 펄럭이며 거리가 벌어진다. [근거: conf ai — 효과음뿐]
	"tk_grolla_kick": {"startup": 15, "active": 4, "recovery": 16, "damage": 14, "reach": 16, "radius": 11, "arc": 140, "lunge": 8, "knockback": 4.6, "hitstop": 8, "posture": 18, "telegraph": "parry", "shape": "round_kick", "sfx": "kick", "hit_sfx": "hit_heavy", "shake": 2, "label": "발차기", "skill": true},
	# grolla · 낮은 자세 차올리기 — 두 손이 바닥에 닿게 엎드려 들어오는 공격을 흘리고(준비, 021/143) → 거꾸로 숙인 낮은 자세에서 발바닥을 얼굴로 올려 찬다(실행, 011/021) → 균형을 잃지 않고 바로 일어선다. [근거: conf ai — 묘사(역동작 옆차기 · 엎드려 흘리고 차올리기)]
	"tk_grolla_low_kick": {"startup": 18, "active": 4, "recovery": 16, "damage": 11, "reach": 15, "radius": 10, "lunge": 6, "knockback": 3.4, "hitstop": 7, "posture": 15, "telegraph": "parry", "shape": "duck", "sfx": "kick", "hit_sfx": "hit_heavy", "stance": 14, "label": "낮은 자세 차올리기", "skill": true, "stance_hit": "tk_grolla_low_kick_hit"},
	# grolla · 낮은 자세 차올리기 맞받기
	"tk_grolla_low_kick_hit": {"startup": 3, "active": 4, "recovery": 14, "damage": 16, "reach": 15, "radius": 11, "lunge": 4, "knockback": 4.8, "knockdown": true, "hitstop": 12, "posture": 26, "parryable": false, "shape": "spin_back_kick", "sfx": "kick", "hit_sfx": "hit_heavy", "shake": 5, "label": "낮은 자세 차올리기", "skill": true},
	# grolla · 엄폐 · 구르기 사격 — 엄폐물 뒤에 웅크리거나 낮게 달리다(준비, 089/000) → 권총을 머리 위로 든 채 옆으로 굴러(089/001) 일어나며 두 손으로 응사한다(실행, 021/016) → 다시 엄폐로 들어간다. [근거: conf ai — 효과음 · 내레이션뿐]
	"tk_grolla_low_shoot": {"startup": 24, "active": 2, "recovery": 18, "damage": 12, "reach": 140, "radius": 4, "side": 18, "parryable": false, "knockback": 2.0, "hitstop": 6, "posture": 12, "iframes": true, "telegraph": "unblock", "shape": "shot", "sfx": "shot", "hit_sfx": "hit_heavy", "shake": 3, "hand": "R", "label": "엄폐 · 구르기 사격", "skill": true},
	# grolla · 잡아 메다꽂기 — 손 · 깃 · 다리 · 얼굴을 움켜쥐고(준비, 022/033 손바닥으로 얼굴을 덮어 쥠) → 몸을 틀어 머리부터 바닥에 내리꽂는다(실행, 011/084 · 022/035) → 짓밟거나 일어나 내려다본다. [근거: conf ai]
	"tk_grolla_throw_slam": {"startup": 20, "active": 8, "recovery": 22, "damage": 11, "reach": 12, "radius": 10, "lunge": 12, "hits": 2, "parryable": false, "guard_break": true, "knockdown": true, "knockback": 2.0, "hitstop": 14, "posture": 20, "telegraph": "unblock", "shape": "grab", "seq": ["grab", "throw_slam"], "sfx": "wind", "hit_sfx": "hit_heavy", "shake": 6, "stun_3d": [40, 30], "whiff": 20, "label": "잡아 메다꽂기", "skill": true},
	# guilhwa · 구일화 큰 주먹 — 맨발로 한 발을 크게 디디며 '내가 바로-'(준비, p1:038/064) → 몸을 실어 얼굴에 큰 주먹을 꽂는다(실행, 066 '콱' · 144 '으라아아앗!') → 상대가 쓰러진다(146). [근거: conf ai — 외침뿐]
	"tk_guilhwa_punch": {"startup": 18, "active": 4, "recovery": 18, "damage": 18, "reach": 14, "radius": 10, "lunge": 16, "knockback": 5.0, "knockdown": true, "hitstop": 11, "posture": 24, "telegraph": "parry", "shape": "straight", "sfx": "kick", "hit_sfx": "hit_heavy", "shake": 4, "whiff": 12, "label": "구일화 큰 주먹", "skill": true},
	# gustav · 구스타프 칼 싸움 — 주먹을 맞고 버틴 뒤 민소매를 찢어 왼손 · 팔뚝에 감고(준비, p1:072/021 '쩌억') → 찔러 오는 칼날을 천 감은 손으로 움켜쥐고 오른 칼로 큰 호를 그어 맞받는다(실행, 073/028-035) → 칼끼리 교차 · 권총 쟁탈로. [근거: conf ai — 끌어안아 찌르기(072/020)는 자세 뒤 기본 한 대로]
	"tk_gus_blade": {"startup": 20, "active": 4, "recovery": 16, "damage": 13, "reach": 12, "radius": 9, "lunge": 10, "knockback": 2.4, "hitstop": 8, "posture": 16, "telegraph": "parry", "shape": "guard_counter", "sfx": "knife", "hit_sfx": "hit_heavy", "stance": 16, "label": "구스타프 칼 싸움", "skill": true, "stance_hit": "tk_gus_blade_hit"},
	# gustav · 구스타프 칼 싸움 맞받기
	"tk_gus_blade_hit": {"startup": 2, "active": 4, "recovery": 14, "damage": 19, "reach": 17, "radius": 12, "arc": 140, "lunge": 6, "knockback": 4.4, "hitstop": 12, "posture": 28, "parryable": false, "shape": "slash", "sfx": "slash", "hit_sfx": "hit_heavy", "shake": 5, "label": "구스타프 칼 싸움", "skill": true},
	# gustav · 구스타프 총격 — 판자 틈에서 노란 눈으로 지켜보다 '철컥' 장전하고(준비, p1:071/093-095) → 기관총을 길게 연사해 다리 · 판자를 부순다(실행, 098 '두 두 · 콰득') → 총신에서 연기 — '쯧.. 꼴사납게 내빼기는.' 하며 총을 내던진다(103). [근거: conf ai — 총신 맨손으로 쥐기(053/002)는 뺌]
	"tk_gus_gun": {"startup": 30, "active": 16, "recovery": 26, "damage": 6, "reach": 160, "radius": 5, "hits": 4, "parryable": false, "knockback": 1.2, "hitstop": 4, "posture": 8, "telegraph": "unblock", "shape": "shot", "seq": ["shot", "shot", "shot", "shot"], "sfx": "shot", "hit_sfx": "hit_heavy", "shake": 3, "label": "구스타프 총격", "skill": true},
	# gustav · 구스타프 내리꽂는 주먹 — 맞은 채 버티다 주먹을 머리 위로 치켜들고(준비, p1:121/060) → 위에서 아래로 얼굴 · 몸통에 내리친다(실행, 062 · 008/129 거대한 주먹) → 상대가 바닥에 처박힌다(008/136 '쾅'). [근거: conf ai — 효과음 '쾅'뿐]
	"tk_gus_hammer_fist": {"startup": 24, "active": 4, "recovery": 20, "damage": 22, "reach": 13, "radius": 11, "lunge": 8, "parryable": false, "knockdown": true, "knockback": 3.0, "hitstop": 14, "posture": 30, "telegraph": "unblock", "shape": "hammer_fist", "sfx": "kick", "hit_sfx": "hit_heavy", "shake": 7, "whiff": 18, "label": "구스타프 내리꽂는 주먹", "skill": true},
	# gustav · 구스타프 메치기·내던지기 — 상대 얼굴을 손으로 쥐어 누르거나 몸을 감아(준비, p1:072/064 '쓰으윽') → 들쳐 메 거꾸로 들어 바닥에 처박는다(실행, 073/060 다리가 떠서 날아감 · '꾸아아악!') → 상대가 바닥을 구른다(064 '콰지직'). [근거: conf ai]
	"tk_gus_slam": {"startup": 20, "active": 8, "recovery": 22, "damage": 12, "reach": 12, "radius": 11, "lunge": 12, "hits": 2, "parryable": false, "guard_break": true, "knockdown": true, "knockback": 5.4, "hitstop": 14, "posture": 22, "telegraph": "unblock", "shape": "grab", "seq": ["grab", "throw_slam"], "sfx": "wind", "hit_sfx": "hit_heavy", "shake": 6, "whiff": 20, "label": "구스타프 메치기·내던지기", "skill": true},
	# gustav · 구스타프 몸통박치기·박치기 — 몸을 낮추고 판자 벽을 뚫으며 돌진해(준비, p1:072/008 '콰앙') → 어깨로 받아 벽 · 기둥에 처박고 머리로 들이받는다(실행, 053/006-008) → 올라타 누른다. [근거: conf ai — 벽 뚫고 기습에 가까움]
	"tk_gus_tackle_headbutt": {"startup": 22, "active": 10, "recovery": 24, "damage": 10, "reach": 13, "radius": 11, "lunge": 42, "hits": 2, "parryable": false, "guard_break": true, "knockdown": true, "knockback": 4.6, "hitstop": 12, "posture": 22, "telegraph": "unblock", "shape": "tackle", "seq": ["tackle", "headbutt"], "sfx": "wind", "hit_sfx": "hit_heavy", "shake": 6, "stun_3d": [30, 20], "whiff": 24, "label": "구스타프 몸통박치기·박치기", "skill": true},
	# hantaecheol · 골프채 후려치기 — 골프채를 어깨에 걸치고 기다리다(준비, 037/161) → 달려드는 상대의 머리 · 뒤통수를 두 손으로 크게 한 번 휘둘러 친다(실행, 038/098) → 피 묻은 헤드를 들고 '나이스 샷-'. [근거: conf ai — '나이스 샷'은 감탄. weapon other = 골프채]
	"tk_han_golf_swing": {"startup": 22, "active": 4, "recovery": 18, "damage": 14, "reach": 18, "radius": 12, "arc": 150, "lunge": 6, "knockback": 4.0, "hitstop": 9, "posture": 18, "telegraph": "parry", "shape": "slash", "sfx": "swing", "hit_sfx": "hit_heavy", "shake": 3, "stance": 18, "label": "골프채 후려치기", "skill": true, "stance_hit": "tk_han_golf_swing_hit"},
	# hantaecheol · 골프채 후려치기 맞받기
	"tk_han_golf_swing_hit": {"startup": 3, "active": 4, "recovery": 18, "damage": 20, "reach": 18, "radius": 12, "arc": 150, "lunge": 4, "knockback": 5.4, "knockdown": true, "hitstop": 14, "posture": 30, "parryable": false, "shape": "slash", "sfx": "swing", "hit_sfx": "hit_heavy", "shake": 6, "label": "골프채 후려치기", "skill": true},
	# hwangbomincheol · 쌍단도 베기 — 양손 단도를 쥐고(준비) → 두 칼을 엇갈려 휘두르고 뛰어올라 호를 그려 베고 올려 벤다(실행, p1:099/028 · 035 '탓' '타악') → 착지. [근거: conf ai — p1:093 ref 는 맞지 않음(099 만 근거)]
	"tk_hwangbo_dual_blade": {"startup": 13, "active": 13, "recovery": 15, "damage": 7, "reach": 14, "radius": 11, "arc": 100, "lunge": 14, "hits": 3, "knockback": 1.4, "hitstop": 6, "posture": 10, "telegraph": "parry", "shape": "cross", "seq": ["cross", "slash", "slash_back"], "sfx": "knife", "hit_sfx": "hit_heavy", "shake": 2, "label": "쌍단도 베기", "skill": true},
	# hwangbomincheol · 얼굴 스치기 베기 맞받기
	"hb_face_hit": {"startup": 2, "active": 3, "recovery": 12, "damage": 15, "reach": 15, "radius": 10, "arc": 90, "lunge": 6, "knockback": 3.0, "hitstop": 10, "posture": 24, "parryable": false, "shape": "slash", "sfx": "knife", "hit_sfx": "hit_heavy", "shake": 3, "skill": true, "skill_id": "hwangbo_face_counter", "label": "얼굴 스치기 베기"},
	# iseul · 머리 · 턱 잡아 누르기 — 상대 곁으로 다가가(준비) → 한 손으로 턱 · 목을 잡아 밀어붙이고 머리를 내리눌러 꿇린다(실행, p1:038/070 '콱' · 112/075 목을 쥐어 고개를 젖힘) → 상대가 실신 · 굴복한다. [근거: conf ai]
	"tk_iseul_grab_down": {"startup": 14, "active": 10, "recovery": 18, "damage": 7, "reach": 12, "radius": 10, "lunge": 10, "hits": 2, "guard_break": true, "knockback": 0.2, "hitstop": 12, "posture": 22, "telegraph": "unblock", "parryable": false, "shape": "grab", "seq": ["grab", "choke"], "sfx": "wind", "hit_sfx": "hit_heavy", "shake": 3, "stun_3d": [60, 40], "whiff": 14, "label": "머리 · 턱 잡아 누르기", "skill": true},
	# jangho · 날아 무릎 · 날아차기 — 땅을 박차고 뛰어올라(준비, p1:079/008 무릎을 세우고 양 주먹을 올림) → 무릎을 얼굴에 꽂는다(실행, 080/002 '뻐억') → 착지. [근거: conf ai — 이름 자막 없음]
	"tk_jangho_air_strike": {"startup": 20, "active": 4, "recovery": 20, "damage": 17, "reach": 13, "radius": 11, "lunge": 38, "parryable": false, "knockdown": true, "knockback": 4.8, "hitstop": 12, "posture": 24, "telegraph": "unblock", "shape": "flying_knee", "sfx": "kick", "hit_sfx": "hit_heavy", "shake": 5, "whiff": 18, "label": "날아 무릎 · 날아차기", "skill": true},
	# jangho · 숙여 피하고 주먹 · 칼잡이 붙들기 — 칼 휘두름을 허리를 숙여 흘리고(준비, p1:080/003 '휙') → 오른 주먹을 당겨 칼잡이 얼굴에 꽂는다(실행, '뻐억') → 대신 칼날에 옆구리가 그인다('촤악'). [근거: conf ai — 칼든 팔 붙들고 들이받기 쪽은 뺌(주먹인지 박치기인지 컷에서 가려지지 않음)]
	"tk_jangho_counter_punch": {"startup": 18, "active": 3, "recovery": 12, "damage": 7, "reach": 12, "radius": 9, "lunge": 6, "knockback": 1.6, "hitstop": 5, "posture": 10, "telegraph": "parry", "shape": "duck", "sfx": "swing", "stance": 14, "label": "숙여 피하고 주먹 · 칼잡이 붙들기", "skill": true, "stance_hit": "tk_jangho_counter_punch_hit"},
	# jangho · 숙여 피하고 주먹 · 칼잡이 붙들기 맞받기
	"tk_jangho_counter_punch_hit": {"startup": 2, "active": 3, "recovery": 14, "damage": 15, "reach": 13, "radius": 10, "lunge": 8, "knockback": 4.0, "hitstop": 11, "posture": 22, "parryable": false, "shape": "straight", "sfx": "kick", "hit_sfx": "hit_heavy", "shake": 4, "label": "숙여 피하고 주먹 · 칼잡이 붙들기", "skill": true},
	# jangho · 헬멧 메다꽂기 · 목 조르기 — 성큼 성큼 다가가 헬멧 바이저 위를 움켜쥐고(준비, p1:079/007) → 머리를 땅에 내리꽂은 뒤 목을 감아 조른다(실행, '정신 안 차릴래?' · 080/004) → 깔고 앉는다. [근거: conf ai]
	"tk_jangho_slam_choke": {"startup": 20, "active": 14, "recovery": 22, "damage": 7, "reach": 12, "radius": 10, "lunge": 12, "hits": 3, "parryable": false, "guard_break": true, "knockdown": true, "knockback": 0.6, "hitstop": 10, "posture": 14, "telegraph": "unblock", "shape": "grab", "seq": ["grab", "two_hand_slam", "choke"], "sfx": "wind", "hit_sfx": "hit_heavy", "shake": 5, "stun_3d": [40, 30], "whiff": 20, "label": "헬멧 메다꽂기 · 목 조르기", "skill": true},
	# jintae · 서진태 쌍단검 돌진 베기 — 양손 단검을 엇갈려 쥐고 낮은 자세로(준비, p1:058/042) → 낮게 돌진하며 앞 손으로 찌르고 두 칼을 X자로 엇갈려 벤다(실행, 059/010-016) → 베며 지나치거나 맞부딪혀 거리를 벌린다. [근거: conf ai]
	"tk_jintae_dual_dagger": {"startup": 9, "active": 9, "recovery": 15, "damage": 8, "reach": 14, "radius": 10, "arc": 90, "lunge": 30, "hits": 2, "knockback": 2.6, "hitstop": 7, "posture": 12, "shape": "thrust_low", "seq": ["thrust_low", "cross"], "sfx": "slash", "hit_sfx": "hit_heavy", "shake": 2, "label": "서진태 쌍단검 돌진 베기", "skill": true},
	# jintae · 서진태 낮게 파고들어 베기 — 상대 공격 아래로 몸을 숙여 파고들어(준비, p1:019/003) → 곁을 지나치며 옆구리 · 다리를 칼로 긋는다(실행, 흰 궤적) → 그대로 다음 상대로 간다. [근거: conf ai — p1:076 엇베기는 확인 못 함]
	"tk_jintae_low_slash": {"startup": 6, "active": 5, "recovery": 13, "damage": 11, "reach": 13, "radius": 10, "arc": 80, "lunge": 26, "side": 10, "knockback": 2.0, "hitstop": 6, "posture": 13, "iframes": true, "shape": "slash", "sfx": "knife", "hit_sfx": "hit_heavy", "label": "서진태 낮게 파고들어 베기", "skill": true},
	# kimdaegeon · 큰 직선 주먹 · 몸 던진 일격 — 주먹을 쥐고 어깨를 실어 돌진해(준비, p1:014/027) → 큰 직선 정권을 얼굴에 꽂는다 — 몸을 던지는 일격(실행, 014/032 엇갈려 서로 얼굴에) → 상대 반격을 맞기도 한다. [근거: conf ai — 크로스 카운터는 dg_cross 로 이미 있음]
	"tk_kimdaegeon_big_punch": {"startup": 18, "active": 4, "recovery": 18, "damage": 17, "reach": 14, "radius": 10, "lunge": 22, "knockback": 5.0, "knockdown": true, "hitstop": 11, "posture": 22, "telegraph": "parry", "shape": "straight", "sfx": "kick", "hit_sfx": "hit_heavy", "shake": 4, "whiff": 14, "label": "큰 직선 주먹 · 몸 던진 일격", "skill": true},
	# kimdaegeon · 윗옷 감은 팔 방어 · 타격 — 윗옷을 왼팔에 감고 지친 척 서 있다가(준비, p1:082/001) → 들어오는 칼을 감은 팔뚝으로 받아 막고(082/002 '파아앙') 감은 왼주먹을 채찍처럼 정타로 꽂는다(실행) → 상대를 넘어뜨려 올라탄다. [근거: conf ai — weapon other = 팔에 감은 윗옷(막기용 — 그림만)]
	"tk_kimdaegeon_jacket_wrap": {"startup": 20, "active": 4, "recovery": 14, "damage": 9, "reach": 15, "radius": 10, "lunge": 10, "knockback": 2.4, "hitstop": 7, "posture": 12, "telegraph": "parry", "shape": "guard_counter", "sfx": "swing", "hand": "L", "stance": 16, "label": "윗옷 감은 팔 방어 · 타격", "skill": true, "stance_hit": "tk_kimdaegeon_jacket_wrap_hit"},
	# kimdaegeon · 윗옷 감은 팔 방어 · 타격 맞받기
	"tk_kimdaegeon_jacket_wrap_hit": {"startup": 2, "active": 3, "recovery": 14, "damage": 16, "reach": 14, "radius": 10, "lunge": 8, "knockback": 4.4, "knockdown": true, "hitstop": 12, "posture": 26, "parryable": false, "shape": "straight", "hand": "L", "sfx": "kick", "hit_sfx": "hit_heavy", "shake": 4, "label": "윗옷 감은 팔 방어 · 타격", "skill": true},
	# kimdaegeon · 메치기 · 내리꽂기 · 조르기 — 매달린 상대의 멱살 · 팔을 움켜쥐고(준비, p1:016/000 '콰악') → 몸을 숙여 등 너머로 넘겨 바닥에 꽂는다(실행, 016/001 '화아악') → 올라타 짓누른다. [근거: conf ai]
	"tk_kimdaegeon_slam": {"startup": 20, "active": 8, "recovery": 22, "damage": 10, "reach": 12, "radius": 10, "lunge": 12, "hits": 2, "parryable": false, "guard_break": true, "knockdown": true, "knockback": 3.6, "hitstop": 13, "posture": 20, "telegraph": "unblock", "shape": "grab", "seq": ["grab", "throw_slam"], "sfx": "wind", "hit_sfx": "hit_heavy", "shake": 5, "whiff": 20, "label": "메치기 · 내리꽂기 · 조르기", "skill": true},
	# kimseongjun · 김성준 칼 휘두르기·베어 올리기 — 웃으며 재킷 안주머니에서 칼을 뽑아 정수로 쥐고(준비, p1:009/018 · 010/001) → 크게 호를 그려 휘두른 뒤 아래에서 위로 베어 올린다(실행) → 상대가 몸을 틀어 피한다. [근거: conf ai]
	"tk_kimseongjun_knife": {"startup": 17, "active": 10, "recovery": 16, "damage": 9, "reach": 15, "radius": 11, "arc": 120, "lunge": 8, "hits": 2, "knockback": 2.4, "hitstop": 7, "posture": 13, "telegraph": "parry", "shape": "slash", "seq": ["slash", "slash_back"], "sfx": "knife", "hit_sfx": "hit_heavy", "shake": 2, "label": "김성준 칼 휘두르기·베어 올리기", "skill": true},
	# kimshin · 현석 단검 · 몸 부딪기 — 낮게 돌진해(준비) 단검으로 한 번 베고 → 몸통을 부딪쳐 상대 손목을 잡아 붙든 채 역수로 찔러 넣는다(실행, p1:116/065 몸을 부딪혀 날아감 · 097/033) → 결착. [근거: conf ai — 현석과 같이 쓰는 기술로 귀속(기술 id 는 hyeonseok_)]
	"tk_hyeonseok_blade": {"startup": 12, "active": 16, "recovery": 18, "damage": 9, "reach": 13, "radius": 10, "arc": 70, "lunge": 30, "hits": 3, "guard_break": true, "knockdown": true, "knockback": 3.6, "hitstop": 9, "posture": 16, "shape": "slash", "seq": ["slash", "grab", "reverse_stab"], "sfx": "knife", "hit_sfx": "hit_heavy", "shake": 4, "whiff": 16, "label": "현석 단검 · 몸 부딪기", "skill": true},
	# kimshin · 칼 막기 · 받아내기 — 상대 칼 · 무기가 내려오는 것을 단검을 세워 기다리다(준비) → 칼날 · 날밑으로 쳐내 받아 넘기고(실행, p1:073/040-047 · 101/022) → 그대로 짧게 베어 맞받는다. [근거: conf ai — k_counter(반격 베기)와 가깝다. p1:074/002 철수 자세는 따로 뗄 것 권장(입력 note)]
	"tk_kimshin_blade_defense": {"startup": 18, "active": 3, "recovery": 12, "damage": 8, "reach": 14, "radius": 9, "lunge": 4, "knockback": 1.6, "hitstop": 5, "posture": 10, "shape": "guard_counter", "sfx": "knife", "stance": 16, "label": "칼 막기 · 받아내기", "skill": true, "stance_hit": "tk_kimshin_blade_defense_hit"},
	# kimshin · 칼 막기 · 받아내기 맞받기
	"tk_kimshin_blade_defense_hit": {"startup": 2, "active": 3, "recovery": 12, "damage": 14, "reach": 15, "radius": 11, "arc": 90, "lunge": 6, "knockback": 3.0, "hitstop": 10, "posture": 28, "parryable": false, "shape": "slash_back", "hand": "L", "sfx": "slash", "hit_sfx": "hit_heavy", "shake": 3, "label": "칼 막기 · 받아내기", "skill": true},
	# kimshin · 허세 · 미끼 · 위압 — 일부러 약한 척 · 총을 겨누는 척하며 시선을 끌고(준비, 023/091 담배 낚아채기) → 손에 든 것을 얼굴로 던져 · 뿌려 눈을 가린 틈에 바로 스트레이트를 꽂는다(실행, '총 미끼 놓고 연타') → 상대가 흔들린다. [근거: conf ai — 심리전 묶음이라 게임 동작은 해석(던지기 · 주먹). 총을 던진다면 리천식 삼연타와 겹치지 않게 구현자 확인]
	"tk_kimshin_bluff_feint": {"startup": 16, "active": 10, "recovery": 14, "damage": 6, "reach": 14, "radius": 11, "arc": 60, "lunge": 6, "hits": 2, "knockback": 1.2, "hitstop": 7, "posture": 22, "feints": [6, 12], "shape": "palm", "seq": ["palm", "straight"], "sfx": "wind", "hit_sfx": "hit_heavy", "shake": 2, "stun_3d": [40, 24], "label": "허세 · 미끼 · 위압", "skill": true},
	# kimshin · 몸통 · 머리 들이받기 — 상대 옷깃을 움켜쥐거나 향해 돌진해(준비, 063/044) → 구두로 강하게 내디디며 몸통으로 부딪치고 머리로 올려 받는다(실행, 붉은 큰 효과음) → 넘어뜨리거나 클린치로 이어간다. [근거: conf ai — p1:049/121 차로 들이받기는 다른 동작]
	"tk_kimshin_body_charge": {"startup": 10, "active": 10, "recovery": 16, "damage": 9, "reach": 12, "radius": 11, "lunge": 28, "hits": 2, "knockback": 3.4, "hitstop": 10, "posture": 20, "shape": "shoulder_ram", "seq": ["shoulder_ram", "headbutt"], "sfx": "wind", "hit_sfx": "hit_heavy", "shake": 4, "stun_3d": [30, 20], "label": "몸통 · 머리 들이받기", "skill": true},
	# kimshin · 목 조르기 — 상대 뒤 · 앞을 잡고(준비, 063/045 귀 · 턱 아래를 움켜쥠) → 팔 · 양손으로 목을 조른다(실행, 088/029 '꾸욱') → 무전을 강요하거나 제압한다. [근거: conf ai]
	"tk_kimshin_choke": {"startup": 14, "active": 18, "recovery": 18, "damage": 5, "reach": 11, "radius": 10, "lunge": 10, "hits": 3, "parryable": false, "guard_break": true, "knockback": 0.1, "hitstop": 10, "posture": 18, "shape": "grab", "seq": ["grab", "choke", "choke"], "sfx": "wind", "hit_sfx": "hit", "shake": 2, "stun_3d": [60, 40], "whiff": 14, "label": "목 조르기", "skill": true},
	# kimshin · 맞잡고 밀착 사격 — 상대와 맞잡거나 총 든 팔을 엇걸어 붙고(준비, 072/000 서로 총 든 팔을 잡음) → 총구를 몸 · 머리에 바짝 대고 연달아 쏜다(실행, '탕 · 퉁 · 콰직') → 상대가 무너진다. [근거: conf ai — 판정은 근접 원(shape grab) — seq shot 은 그림 · 소리만(선 판정 아님)]
	"tk_kimshin_clinch_shot": {"startup": 12, "active": 14, "recovery": 18, "damage": 9, "reach": 12, "radius": 10, "lunge": 10, "hits": 3, "parryable": false, "guard_break": true, "knockback": 2.2, "hitstop": 9, "posture": 14, "shape": "grab", "seq": ["grab", "shot", "shot"], "sfx": "shot", "hit_sfx": "hit_heavy", "shake": 4, "whiff": 14, "label": "맞잡고 밀착 사격", "skill": true},
	# kimshin · 숙여 흘리고 카운터 주먹 — 상대 주먹 · 훅 · 무기 휘두름을 기다리다(준비) → 머리를 숙여 흘리고 품으로 파고들어 오른 주먹을 턱에 올려 꽂는다(실행, p1:002/016 '콰악') → 상대가 꺾여 쓰러진다. [근거: conf ai — 기술명 없음(효과음뿐)]
	"tk_kimshin_counter_punch": {"startup": 20, "active": 3, "recovery": 12, "damage": 6, "reach": 12, "radius": 9, "lunge": 4, "knockback": 1.2, "hitstop": 5, "posture": 8, "shape": "duck", "sfx": "swing", "stance": 18, "label": "숙여 흘리고 카운터 주먹", "skill": true, "stance_hit": "tk_kimshin_counter_punch_hit"},
	# kimshin · 숙여 흘리고 카운터 주먹 맞받기
	"tk_kimshin_counter_punch_hit": {"startup": 2, "active": 4, "recovery": 14, "damage": 18, "reach": 13, "radius": 10, "arc": 60, "lunge": 8, "knockback": 4.6, "knockdown": true, "hitstop": 14, "posture": 30, "parryable": false, "shape": "uppercut", "sfx": "kick", "hit_sfx": "hit_heavy", "shake": 5, "label": "숙여 흘리고 카운터 주먹", "skill": true},
	# kimshin · 어둠 속 매복 기습 — 불을 끄고 문 뒤 · 어둠에 숨었다가(준비, p1:025/060 장갑 '스윽') → 비스듬히 튀어나와 칼을 깊이 박아 넣는다(실행, p1:031/104 등 뒤로 침) → 멈추지 않고 다음 상대로 간다. [근거: conf ai — 어둠(소등)은 연출. 등 뒤 보너스는 동작 표 필드 없음]
	"tk_kimshin_dark_ambush": {"startup": 10, "active": 4, "recovery": 18, "damage": 17, "reach": 16, "radius": 9, "lunge": 36, "side": 12, "parryable": false, "knockback": 3.2, "hitstop": 11, "posture": 24, "shape": "thrust", "sfx": "knife", "hit_sfx": "hit_heavy", "shake": 4, "whiff": 16, "label": "어둠 속 매복 기습", "skill": true},
	# kimshin · 양손 칼(두 칼) 운용 — 양손에 칼 두 자루를 뽑아 쥐고(준비, p1:073/018 '스릉—') → 뛰어 들며 두 칼로 연달아 베고 엇갈려 마무리한다 — 하나를 내줘도 남은 칼로 급소(실행, p1:113/051 잔상 · 어깨 · 가슴 베기) → 걸어 나온다. [근거: conf ai]
	"tk_kimshin_dual_knife": {"startup": 8, "active": 16, "recovery": 15, "damage": 6, "reach": 14, "radius": 11, "arc": 100, "lunge": 20, "hits": 4, "knockback": 1.0, "hitstop": 5, "posture": 9, "shape": "slash", "seq": ["slash", "slash_back", "slash", "cross"], "sfx": "slash", "hit_sfx": "hit_heavy", "shake": 2, "label": "양손 칼(두 칼) 운용", "skill": true},
	# kimshin · 팔꿈치 · 무릎 연타 — 붙은 거리에서(준비) → 팔꿈치로 얼굴을 두 번 찍고 무릎을 올려 꽂는다(실행, p1:003/043-044 · 124/069 무릎) → 상대가 몸을 접는다. [근거: conf ai — 무릎이 누구 것인지 컷이 약간 모호(대사로 판단)]
	"tk_kimshin_elbow_knee": {"startup": 5, "active": 12, "recovery": 13, "damage": 7, "reach": 10, "radius": 10, "arc": 60, "lunge": 6, "hits": 3, "knockback": 0.8, "hitstop": 7, "posture": 14, "shape": "elbow", "seq": ["elbow", "elbow", "knee"], "sfx": "kick", "hit_sfx": "hit_heavy", "shake": 3, "label": "팔꿈치 · 무릎 연타", "skill": true},
	# kimshin · 날아차기 — 달려 들어가 도약해(준비, p1:006/004 '시작하자.') → 몸을 옆으로 눕히며 한 다리를 곧게 뻗어 얼굴을 찬다(실행, p1:003/028 · '퍽') → 공중에서 착지한다. [근거: conf ai]
	"tk_kimshin_flying_kick": {"startup": 14, "active": 4, "recovery": 18, "damage": 15, "reach": 15, "radius": 11, "lunge": 40, "knockback": 5.0, "knockdown": true, "hitstop": 11, "posture": 22, "shape": "flying_kick", "sfx": "kick", "hit_sfx": "hit_heavy", "shake": 5, "whiff": 14, "label": "날아차기", "skill": true},
	# kimshin · 주변 물건 · 장도리로 때리기 — 바닥 · 주변의 장도리 · 블록을 집어(준비) → 위에서 얼굴 · 머리로 두 번 내려친다(실행, 095/006 '휘릭' · 090/031 '콰직') → 물건을 버리고 다음 상대로. [근거: conf ai — weapon other = 장도리 · 블록(판마다 다름)]
	"tk_kimshin_improvised": {"startup": 14, "active": 12, "recovery": 18, "damage": 9, "reach": 14, "radius": 10, "arc": 50, "lunge": 8, "hits": 2, "guard_break": true, "knockback": 2.0, "hitstop": 10, "posture": 18, "shape": "overhead_chop", "seq": ["overhead_chop", "overhead_chop"], "sfx": "swing", "hit_sfx": "hit_heavy", "shake": 4, "stun_3d": [30, 20], "label": "주변 물건 · 장도리로 때리기", "skill": true},
	# kimshin · 카람빗 사용 — 카람빗을 손가락 고리에 걸어 '휘릭' 돌려 쥐고(준비, p1:051/002) → 갈고리 날로 상대 손목을 걸어 당긴 뒤 되돌려 빠르게 벤다(실행, p1:050 · 051) → 손도끼 · 칼 든 손을 제압한다. [근거: conf ai — 카람빗 칼(굽은 칼)을 들려야 한다]
	"tk_kimshin_karambit": {"startup": 6, "active": 9, "recovery": 12, "damage": 7, "reach": 12, "radius": 10, "arc": 80, "lunge": 8, "hits": 2, "guard_break": true, "knockback": 1.0, "hitstop": 7, "posture": 14, "shape": "grab", "seq": ["grab", "slash_back"], "sfx": "slash", "hit_sfx": "hit_heavy", "shake": 2, "stun_3d": [24, 16], "label": "카람빗 사용", "skill": true},
	# kimshin · 발차기(앞차기 · 하이킥 · 올려차기) — 상대 앞에서 한 발 딛고 다리를 들어(준비) → 오른발 앞차기로 밀고 이어 하이킥을 머리에 꽂는다(실행, p1:027/072 · 118/049-050) → 빠져나가거나 이어 공격. [근거: conf ai — 누운 자세 올려차기는 뺌]
	"tk_kimshin_kick": {"startup": 10, "active": 12, "recovery": 15, "damage": 9, "reach": 16, "radius": 11, "arc": 100, "lunge": 8, "hits": 2, "knockback": 2.6, "hitstop": 8, "posture": 14, "shape": "front_kick", "seq": ["front_kick", "round_kick"], "sfx": "kick", "hit_sfx": "hit_heavy", "shake": 2, "label": "발차기(앞차기 · 하이킥 · 올려차기)", "skill": true},
	# kimshin · 칼 베기(휩쓸기) — 몸을 낮춰 파고들어(준비, p1:031/142 상대 돌진을 젖혀 흘림) → 칼 쥔 팔을 가로로 크게 휘둘러 목 · 몸통을 벤다(실행, 147 · p1:115/044 흰 호) → 지나치며 다음 상대로. [근거: conf ai]
	"tk_kimshin_knife_slash": {"startup": 8, "active": 4, "recovery": 14, "damage": 13, "reach": 15, "radius": 13, "arc": 160, "lunge": 16, "knockback": 2.8, "hitstop": 8, "posture": 16, "shape": "slash", "sfx": "slash", "hit_sfx": "hit_heavy", "shake": 2, "label": "칼 베기(휩쓸기)", "skill": true},
	# kimshin · 단검 찌르기 — 낮게 숙여 파고들며 칼을 역수로 쥐고(준비) → 아래에서 허벅지 · 몸통에 박고 두 번째 칼로 이어 찌른다(실행, 041/034 '콱' · p1:113/047) → 칼을 빼고 스쳐 지나간다. [근거: conf ai]
	"tk_kimshin_knife_stab": {"startup": 9, "active": 9, "recovery": 15, "damage": 9, "reach": 18, "radius": 8, "lunge": 14, "hits": 2, "knockback": 2.6, "hitstop": 8, "posture": 14, "shape": "thrust_low", "seq": ["thrust_low", "thrust"], "sfx": "knife", "hit_sfx": "hit_heavy", "shake": 2, "label": "단검 찌르기", "skill": true},
	# kimshin · 도약 · 낙하 칼 공격 — 높은 곳 · 벽 · 도약으로 위에서 덮쳐(준비, p1:114/069) → 공중에서 칼을 거꾸로 쥐고 내리찍는다(실행, 낙하 찌르기) → 착지. [근거: conf ai — 벽 차기는 확정 못 함]
	"tk_kimshin_leaping_blade": {"startup": 16, "active": 4, "recovery": 20, "damage": 18, "reach": 14, "radius": 11, "lunge": 40, "parryable": false, "knockdown": true, "knockback": 3.6, "hitstop": 13, "posture": 26, "shape": "reverse_stab", "sfx": "knife", "hit_sfx": "hit_heavy", "shake": 6, "whiff": 20, "label": "도약 · 낙하 칼 공격", "skill": true},
	# kimshin · 낮은 자세 질주 돌파 — 몸을 낮추고 코트를 펄럭이며 달려들어(준비) → 좌우로 잔상 페인트를 흘리며 공격 바깥으로 낮게 스쳐 지나가며 벤다(실행, p1:030 · 071/016) → 멈추지 않고 빠져나간다. [근거: conf ai — 066/046 ref 오류. k_dash(아무르 티그로 대시)와 가깝다 — 합쳐도 됨]
	"tk_kimshin_low_dash": {"startup": 5, "active": 6, "recovery": 10, "damage": 8, "reach": 13, "radius": 10, "arc": 60, "lunge": 48, "side": 12, "zigzag": true, "knockback": 1.6, "hitstop": 5, "posture": 10, "feints": [3], "shape": "thrust_low", "sfx": "wind", "hit_sfx": "hit", "label": "낮은 자세 질주 돌파", "skill": true},
	# kimshin · 권총 손잡이 내려찍기 — 권총을 거꾸로 쥐고 들어 올려(준비, p1:002/018 코트 휘날림) → 손잡이로 뒤통수 · 정수리를 내리친다(실행, 019 붉은 효과음) → 상대가 쓰러진다. [근거: conf ai]
	"tk_kimshin_pistol_butt": {"startup": 9, "active": 3, "recovery": 14, "damage": 11, "reach": 12, "radius": 10, "lunge": 8, "knockback": 1.2, "hitstop": 12, "posture": 20, "shape": "hammer_fist", "sfx": "kick", "hit_sfx": "hit_heavy", "shake": 4, "stun_3d": [60, 24], "label": "권총 손잡이 내려찍기", "skill": true},
	# kimshin · 역수 칼 내려찍기 · 올려 베기 — 칼을 역수로 거꾸로 쥐고(준비, 091/017 가슴 칼집의 청록 칼) → 위에서 내리찍고 되돌려 아래에서 올려 벤다(실행, '촥') → 마무리. [근거: conf ai]
	"tk_kimshin_reverse_grip": {"startup": 7, "active": 9, "recovery": 14, "damage": 8, "reach": 12, "radius": 10, "arc": 70, "lunge": 6, "hits": 2, "knockback": 2.4, "hitstop": 8, "posture": 14, "shape": "reverse_stab", "seq": ["reverse_stab", "slash_back"], "sfx": "knife", "hit_sfx": "hit_heavy", "shake": 2, "label": "역수 칼 내려찍기 · 올려 베기", "skill": true},
	# kimshin · 달리며 · 도약하며 쏘기 — 달리거나 뛰어내리며 몸을 틀어(준비, 088/054 자루 더미 위로) → 움직이는 채 조준해 쏜다(실행) → 착지 뒤 이어 교전. [근거: conf ai — draw_shot 은 선 판정(shot)으로 다뤄야 한다]
	"tk_kimshin_running_shot": {"startup": 14, "active": 2, "recovery": 16, "damage": 12, "reach": 150, "radius": 4, "lunge": 18, "parryable": false, "knockback": 2.0, "hitstop": 6, "posture": 12, "telegraph": "unblock", "shape": "draw_shot", "sfx": "shot", "hit_sfx": "hit_heavy", "shake": 3, "label": "달리며 · 도약하며 쏘기", "skill": true},
	# kimshin · 메치기 · 넘기기 — 재킷 깃을 두 주먹으로 움켜쥐고(준비, p1:004/007 '콱') → 다리를 쓸며 어깨 너머로 띄워 바닥에 꽂는다(실행, 008 '휘익') → 위에서 누르거나 거리를 벌린다. [근거: conf ai]
	"tk_kimshin_throw": {"startup": 12, "active": 8, "recovery": 18, "damage": 9, "reach": 12, "radius": 10, "lunge": 10, "hits": 2, "parryable": false, "guard_break": true, "knockdown": true, "knockback": 3.0, "hitstop": 12, "posture": 20, "shape": "grab", "seq": ["grab", "throw_slam"], "sfx": "wind", "hit_sfx": "hit_heavy", "shake": 5, "whiff": 14, "label": "메치기 · 넘기기", "skill": true},
	# kimshin · 손목 · 팔 잡아 제압 — 상대가 무기 · 주먹을 뻗는 순간을 기다리다(준비) → 무기 쥔 손목을 낚아채 비틀어 칼날을 꺾는다(실행, p1:010/002 칼자루째 꽉 쥠) → 잡은 채 '끝이다.' [근거: conf ai]
	"tk_kimshin_wrist_grab": {"startup": 16, "active": 3, "recovery": 12, "damage": 4, "reach": 12, "radius": 10, "lunge": 4, "knockback": 0.4, "hitstop": 5, "posture": 10, "shape": "grab", "sfx": "wind", "stance": 14, "label": "손목 · 팔 잡아 제압", "skill": true, "stance_hit": "tk_kimshin_wrist_grab_hit"},
	# kimshin · 손목 · 팔 잡아 제압 맞받기
	"tk_kimshin_wrist_grab_hit": {"startup": 2, "active": 4, "recovery": 10, "damage": 6, "reach": 12, "radius": 10, "lunge": 4, "knockback": 0.2, "hitstop": 12, "posture": 34, "parryable": false, "guard_break": true, "shape": "grab", "sfx": "wind", "hit_sfx": "hit_heavy", "shake": 3, "stun_3d": [60, 40], "label": "손목 · 팔 잡아 제압", "skill": true},
	# komodo · 고리 칼 돌리기 — 나무 손잡이 고리 칼을 손가락 고리에 걸어 휘락 돌리며 위협하다가(준비, p1:090/007 · 106/044) → '파앗' 도약해 덮치며 칼을 위에서 박는다(실행, 106/046) → 칼 든 손목을 맞잡는 결박으로 이어진다. [근거: conf ai]
	"tk_komodo_ring_spin": {"startup": 18, "active": 4, "recovery": 18, "damage": 13, "reach": 13, "radius": 10, "lunge": 32, "knockback": 3.0, "hitstop": 9, "posture": 16, "telegraph": "parry", "feints": [6, 12], "shape": "reverse_stab", "sfx": "slash", "hit_sfx": "hit_heavy", "shake": 3, "whiff": 14, "label": "고리 칼 돌리기", "skill": true},
	# lingling · 사슬 식칼 — 손목에 사슬을 감고 넓은 식칼을 늘어뜨린 채 거리를 잰다(준비) → 사슬을 잡아채 식칼을 앞으로 던져 긋고, 당겨 오는 사이 앞발로 밀어 찬다(실행) → 사슬을 당겨 칼을 손에 되돌린다(037/055-059 · 049/029-032). [근거: 던지기 · 발차기 연계는 alias 묘사뿐(conf ai) — 던지는 컷 직접 확인 없음]
	"tk_lingling_chain_cleaver": {"startup": 16, "active": 12, "recovery": 16, "damage": 9, "reach": 26, "radius": 8, "lunge": 4, "hits": 2, "knockback": 2.6, "hitstop": 6, "posture": 14, "telegraph": "parry", "shape": "thrust", "seq": ["thrust", "front_kick"], "sfx": "slash", "hit_sfx": "hit_heavy", "whiff": 12, "label": "사슬 식칼", "skill": true},
	# lingling · 식칼 치켜들어 내려베기 — 허리 칼집에서 식칼을 뽑아 머리 위로 높이 치켜든다(준비) → 뛰어올라 위에서 어깨 · 팔로 내려 벤다(실행) → 칼을 다시 어깨 높이로 올린다(p1:077/008-009 · 051/023-025).
	"tk_lingling_cleaver_overhead": {"startup": 22, "active": 4, "recovery": 20, "damage": 18, "reach": 15, "radius": 10, "lunge": 28, "parryable": false, "knockdown": true, "knockback": 3.6, "hitstop": 12, "posture": 24, "telegraph": "unblock", "shape": "overhead_chop", "sfx": "slash", "hit_sfx": "hit_heavy", "shake": 5, "whiff": 18, "label": "식칼 치켜들어 내려베기", "skill": true},
	# mahakyoung · 군화 걷어차기 — 한 다리를 무릎까지 접어 든다(준비) → 군화 바닥으로 얼굴 · 가슴을 정면으로 찍어 민다(실행) → 롱코트를 펄럭이며 내려서고 상대는 날아가 뒤집힌다(079/044-045 · 122/053-054).
	"tk_mahak_boot_kick": {"startup": 14, "active": 4, "recovery": 16, "damage": 16, "reach": 15, "radius": 10, "lunge": 10, "knockback": 7.0, "knockdown": true, "hitstop": 10, "posture": 22, "telegraph": "parry", "shape": "front_kick", "sfx": "kick", "hit_sfx": "hit_heavy", "shake": 4, "label": "군화 걷어차기", "skill": true},
	# mahakyoung · 근접 소음기 권총 사격 — 몸을 낮추거나 상대를 붙잡아 앞에 세운다(준비) → 어깨 너머 · 머리 옆에 총구를 대고 소음기 권총을 두 번 쏜다(실행) → 그대로 전진한다(079/052-053 · 112/010-014).
	"tk_mahak_close_fire": {"startup": 20, "active": 8, "recovery": 18, "damage": 9, "reach": 70, "radius": 5, "hits": 2, "parryable": false, "knockback": 2.4, "hitstop": 7, "posture": 14, "telegraph": "unblock", "shape": "shot", "seq": ["shot", "shot"], "sfx": "shot", "hit_sfx": "hit_heavy", "shake": 3, "label": "근접 소음기 권총 사격", "skill": true},
	# mahakyoung · 몸 날려 사격(차량·벽) — 질주하거나 벽 · 보닛을 딛는다(준비) → 옆으로 몸을 날리며 공중에서 권총을 세 번 연사한다(실행) → 내려서며 굴러 다시 쫓는다(110/048-049 · 118/029-033).
	"tk_mahak_dive_shoot": {"startup": 24, "active": 12, "recovery": 22, "damage": 7, "reach": 150, "radius": 6, "side": 18, "hits": 3, "parryable": false, "knockback": 1.8, "hitstop": 5, "posture": 10, "telegraph": "unblock", "shape": "shot", "seq": ["shot", "shot", "shot"], "sfx": "shot", "hit_sfx": "hit_heavy", "shake": 2, "label": "몸 날려 사격(차량·벽)", "skill": true},
	# mahakyoung · 검은 장갑 주먹 강타 — 붙어서 상대 옷깃을 쥐거나 오른 주먹을 머리 위로 든다(준비) → 검은 장갑 주먹을 얼굴 · 가슴에 위에서 내리꽂는다(실행) → 상대가 젖혀져 쓰러진다(005/142-144 · 120/000-001).
	"tk_mahak_glove_punch": {"startup": 16, "active": 3, "recovery": 16, "damage": 20, "reach": 13, "radius": 10, "lunge": 10, "knockdown": true, "knockback": 3.0, "hitstop": 12, "posture": 28, "telegraph": "parry", "shape": "hammer_fist", "sfx": "kick", "hit_sfx": "hit_heavy", "shake": 5, "label": "검은 장갑 주먹 강타", "skill": true},
	# mahakyoung · 잡아 내리꽂기 — 머리채 · 목을 움켜쥔다(준비) → 잡은 채 얼굴부터 바닥에 내리꽂아 짓누른다(실행) → 상대가 엎어져 숨이 막히고 머리채를 놓는다(005/209-214 · 120/060-063).
	"tk_mahak_grip_slam": {"startup": 18, "active": 10, "recovery": 20, "damage": 11, "reach": 11, "radius": 10, "lunge": 12, "hits": 2, "parryable": false, "guard_break": true, "knockdown": true, "knockback": 1.0, "hitstop": 14, "posture": 28, "telegraph": "unblock", "shape": "grab", "seq": ["grab", "throw_slam"], "sfx": "wind", "hit_sfx": "hit_heavy", "shake": 6, "stun_3d": [60, 40], "whiff": 20, "label": "잡아 내리꽂기", "skill": true},
	# mahakyoung · 방패 돌진·압박 — 방탄 방패를 앞세워 몸을 숙인다(준비) → 방패로 돌진해 모서리로 치고 면으로 눌러 민다(실행) → 상대를 밀어 넘어뜨린다(079/042-043 · 096/015 · 108/010-011). [근거: 087/005 · 107/008 귀속 불확실 — 079/042 · 096/015 · 108/010 근거만]
	"tk_mahak_shield_rush": {"startup": 18, "active": 10, "recovery": 18, "damage": 9, "reach": 13, "radius": 12, "lunge": 34, "hits": 2, "parryable": false, "guard_break": true, "knockdown": true, "knockback": 5.0, "hitstop": 9, "posture": 30, "telegraph": "unblock", "shape": "shoulder_ram", "seq": ["shoulder_ram", "palm"], "sfx": "wind", "hit_sfx": "hit_heavy", "shake": 4, "whiff": 16, "label": "방패 돌진·압박", "skill": true},
	# mahakyoung · 거꾸로 들어 메치기 — 상대와 엉켜 팔 · 턱을 잡는다(준비) → 거꾸로 들어 올려 머리부터 던진다(실행) → 엎어진 상대가 멀리 굴러 간다(119/012-014 · 123/041-042).
	"tk_mahak_throw": {"startup": 26, "active": 5, "recovery": 24, "damage": 24, "reach": 12, "radius": 10, "lunge": 12, "parryable": false, "guard_break": true, "knockdown": true, "knockback": 6.5, "hitstop": 16, "posture": 34, "telegraph": "unblock", "shape": "throw_slam", "sfx": "wind", "hit_sfx": "hit_heavy", "shake": 7, "whiff": 24, "label": "거꾸로 들어 메치기", "skill": true},
	# majunyeong · 근접 소음기 연사 — 권총을 허리 아래로 들고 붙는다(준비) → 가까이서 소음기 권총을 세 번 끊어 쏜다 — 칼잡이를 앞세워 엄호하기도 한다(실행) → 쏘며 전진한다(043/065-070 · 091/055-059).
	"tk_mj_close_fire": {"startup": 22, "active": 12, "recovery": 18, "damage": 6, "reach": 110, "radius": 6, "hits": 3, "parryable": false, "knockback": 1.6, "hitstop": 4, "posture": 9, "telegraph": "unblock", "shape": "shot", "seq": ["shot", "shot", "shot"], "sfx": "shot", "hit_sfx": "hit", "shake": 2, "label": "근접 소음기 연사", "skill": true},
	# majunyeong · 단검 내리찍기·돌진 — 단검을 역수로 머리 위에 든다(준비) → 정면으로 달려들며 내리찍고, 막히면 다리를 걸어 넘긴다(실행) → 절규하며 다시 일어선다(033/057-060 · 092/046-047). [근거: 내리찍는 칼 자체는 본 조각에 없음 — 다리 걸기 컷(033/059)만 확인]
	"tk_mj_dagger_stab": {"startup": 16, "active": 10, "recovery": 18, "damage": 11, "reach": 13, "radius": 10, "lunge": 26, "hits": 2, "knockdown": true, "knockback": 2.4, "hitstop": 8, "posture": 18, "telegraph": "parry", "shape": "reverse_stab", "seq": ["reverse_stab", "sweep"], "sfx": "knife", "hit_sfx": "hit_heavy", "shake": 2, "label": "단검 내리찍기·돌진", "skill": true},
	# majunyeong · 방패 들이받기·돌진 — 소음기 권총을 겨눈 채 방패를 앞세운다(준비) → 방패로 들이받아 '쾅' 하고 날린다(실행) → 조롱하며 방패를 끌고 다가온다(079/009 · 086/044 · 087/035-039).
	"tk_mj_shield_rush": {"startup": 18, "active": 5, "recovery": 18, "damage": 14, "reach": 13, "radius": 12, "lunge": 32, "knockdown": true, "knockback": 6.0, "hitstop": 10, "posture": 24, "telegraph": "parry", "shape": "shoulder_ram", "sfx": "wind", "hit_sfx": "hit_heavy", "shake": 4, "whiff": 14, "label": "방패 들이받기·돌진", "skill": true},
	# majunyeong · 차체·문짝 때리기 — 문짝을 짚고 뜯어낸다(준비) → 문짝을 두 손으로 들어 위에서 내려친다(실행) → 다음 동작으로 잇는다(044/060-062 · 044/098-101). [근거: 차가 없는 방에서는 문짝을 소품으로 들려야 함 — 근거는 044/061 한 컷]
	"tk_mj_vehicle_smash": {"startup": 26, "active": 4, "recovery": 22, "damage": 20, "reach": 15, "radius": 13, "lunge": 8, "parryable": false, "guard_break": true, "knockdown": true, "knockback": 4.6, "hitstop": 14, "posture": 30, "telegraph": "unblock", "shape": "two_hand_slam", "sfx": "wind", "hit_sfx": "hit_heavy", "shake": 6, "whiff": 20, "label": "차체·문짝 때리기", "skill": true},
	# mark · 몸통 들이받기 · 끌어안고 돌진 — '까짓 차든 말든!' — 차기를 맞으면서도 몸을 숙인다(준비) → 어깨 · 몸통으로 허리를 감아 들이받으며 밀어붙인다(실행) → 상대는 허리가 꺾여 나가떨어진다(009/007 · 009/009).
	"tk_mark_body_charge": {"startup": 18, "active": 6, "recovery": 20, "damage": 17, "reach": 13, "radius": 11, "lunge": 36, "parryable": false, "guard_break": true, "knockdown": true, "knockback": 6.0, "hitstop": 12, "posture": 30, "telegraph": "unblock", "shape": "tackle", "sfx": "wind", "hit_sfx": "hit_heavy", "shake": 5, "whiff": 18, "label": "몸통 들이받기 · 끌어안고 돌진", "skill": true},
	# mark · 혁대 · 손띠 감은 큰 주먹 — 사자 버클 혁대를 풀어 오른 주먹에 감는다(준비) → 큰 훅 · 어퍼 · 스트레이트를 이어 친다(실행) → 피가 튄다(009/006 · 010/000).
	"tk_mark_knuckle": {"startup": 14, "active": 15, "recovery": 16, "damage": 9, "reach": 13, "radius": 11, "arc": 90, "lunge": 10, "hits": 3, "knockback": 2.6, "hitstop": 8, "posture": 16, "telegraph": "parry", "shape": "hook", "seq": ["hook", "uppercut", "straight"], "sfx": "kick", "hit_sfx": "hit_heavy", "shake": 3, "label": "혁대 · 손띠 감은 큰 주먹", "skill": true},
	# namgunghyuk · 남궁혁 발차기 — 발을 뒤로 크게 젖힌다(준비) → 한 발을 수평으로 크게 휘둘러 옆머리 · 몸통을 찬다(실행) → 상대가 꺾여 구른다(p1:024/143-147 · p1:104/070-075).
	"tk_namgung_kick": {"startup": 15, "active": 4, "recovery": 16, "damage": 13, "reach": 15, "radius": 11, "arc": 130, "lunge": 6, "knockback": 3.8, "hitstop": 8, "posture": 18, "telegraph": "parry", "shape": "round_kick", "sfx": "kick", "hit_sfx": "hit_heavy", "shake": 2, "label": "남궁혁 발차기", "skill": true},
	# namgunghyuk · 금 너클 연타 · 내리찍기 — 오른손에 금 너클을 낀다(준비) → 몸통 · 얼굴을 두드리다 올려치고 위에서 내리꽂는다(실행) → 피 묻은 너클을 턴다(p1:029/100-101 · p1:097/126-151).
	"tk_namgung_knuckle_combo": {"startup": 10, "active": 18, "recovery": 16, "damage": 5, "reach": 13, "radius": 10, "arc": 50, "lunge": 10, "hits": 4, "knockdown": true, "knockback": 1.2, "hitstop": 5, "posture": 9, "telegraph": "parry", "shape": "jab", "seq": ["body_blow", "jab", "uppercut", "hammer_fist"], "sfx": "swing", "hit_sfx": "hit", "label": "금 너클 연타 · 내리찍기", "skill": true},
	# namgunghyuk · 너클 낀 주먹 카운터 — 몸을 낮춰 상대 주먹을 기다린다(준비) → 들어오는 주먹 밑으로 머리를 숙여 흘리고 품으로 파고들며 너클 주먹을 갈비에 꽂는다(실행) → 상대가 꺾여 숨이 멎는다(p1:024/136-138 · p1:028/088-089). [근거: 지금 ng_counter 는 자세 없는 빠른 주먹 — 숙여 흘리는 자세(stance)로 바꿈(skill_id namgung_knuckle_counter 유지)]
	"tk_namgung_knuckle_counter": {"startup": 18, "active": 3, "recovery": 14, "damage": 7, "reach": 12, "radius": 9, "lunge": 4, "knockback": 1.6, "hitstop": 5, "posture": 10, "telegraph": "", "shape": "duck", "stance": 16, "sfx": "swing", "label": "너클 낀 주먹 카운터", "skill": true, "stance_hit": "tk_namgung_knuckle_counter_hit"},
	# namgunghyuk · 너클 낀 주먹 카운터 맞받기
	"tk_namgung_knuckle_counter_hit": {"startup": 2, "active": 4, "recovery": 14, "damage": 18, "reach": 13, "radius": 10, "lunge": 8, "parryable": false, "knockback": 4.4, "hitstop": 12, "posture": 26, "shape": "body_blow", "sfx": "kick", "hit_sfx": "hit_heavy", "shake": 5, "stun_3d": [60, 50], "label": "너클 낀 주먹 카운터", "skill": true},
	# namilho · 남일호 피하기·몸으로 막기 — 재킷 안에 손을 넣은 채 서 있다(준비) → 덮쳐 오는 공격을 몸을 틀어 흘리거나 어깨로 받아 밀어낸다(실행) → 손바닥을 들어 멈추거나 이를 악물고 버틴다(p1:043/135-144 · p1:110/045-047). [근거: 110 의 밀치는 순간은 직접 컷 없이 045→046 흐름으로 추정]
	"tk_namilho_guard": {"startup": 16, "active": 3, "recovery": 12, "damage": 5, "reach": 11, "radius": 10, "lunge": 4, "knockback": 3.0, "hitstop": 5, "posture": 12, "telegraph": "", "shape": "sidestep", "stance": 14, "sfx": "swing", "label": "남일호 피하기·몸으로 막기", "skill": true, "stance_hit": "tk_namilho_guard_hit"},
	# namilho · 남일호 피하기·몸으로 막기 맞받기
	"tk_namilho_guard_hit": {"startup": 2, "active": 4, "recovery": 12, "damage": 8, "reach": 12, "radius": 11, "lunge": 10, "side": 8, "knockback": 5.5, "hitstop": 8, "posture": 20, "shape": "shoulder_ram", "sfx": "wind", "hit_sfx": "hit_heavy", "shake": 2, "label": "남일호 피하기·몸으로 막기", "skill": true},
	# namilho · 남일호 타격·메치기 — 도주로에서 기다리다 돌아선다(준비) → 옆구리를 쳐 몸을 꺾고 그대로 붙잡아 등으로 메친다(실행) → 상대가 바닥에 등부터 떨어진다(p1:048/024-032 · p1:057/096-099). [근거: 057/098 머리 돌려차기는 이 기술에서 뺐음(메치기 쪽만) — 048/026 머리채 컷 확인 약함]
	"tk_namilho_strike_throw": {"startup": 16, "active": 10, "recovery": 20, "damage": 10, "reach": 12, "radius": 10, "lunge": 14, "hits": 2, "parryable": false, "guard_break": true, "knockdown": true, "knockback": 3.4, "hitstop": 12, "posture": 26, "telegraph": "unblock", "shape": "body_blow", "seq": ["body_blow", "throw_slam"], "sfx": "wind", "hit_sfx": "hit_heavy", "shake": 5, "whiff": 18, "label": "남일호 타격·메치기", "skill": true},
	# namilho · 남일호 가는 칼 찌르기 — 가는 칼을 역수로 고쳐 쥐고 몸을 낮춘다(준비) → 낮게 수평으로 뛰어들어 허벅지에 칼을 박는다(실행) → 칼을 뽑아 물러선다(p1:057/085-091 · p1:106/005-006).
	"tk_namilho_thin_blade": {"startup": 14, "active": 4, "recovery": 16, "damage": 14, "reach": 17, "radius": 8, "lunge": 28, "parryable": false, "knockback": 2.6, "hitstop": 9, "posture": 20, "telegraph": "unblock", "shape": "thrust_low", "sfx": "knife", "hit_sfx": "hit_heavy", "shake": 2, "whiff": 14, "label": "남일호 가는 칼 찌르기", "skill": true},
	# odohwa · 손도끼 내려찍기 — 손도끼를 머리 위로 치켜든다(준비) → 위에서 어깨 · 쇄골로 내려찍는다(실행) → 날이 박히거나 멈춘다(p1:047/109-110 · p1:053/038-042).
	"tk_odohwa_axe_chop": {"startup": 18, "active": 4, "recovery": 18, "damage": 18, "reach": 13, "radius": 10, "lunge": 8, "knockback": 3.4, "hitstop": 11, "posture": 26, "telegraph": "parry", "shape": "overhead_chop", "sfx": "slash", "hit_sfx": "hit_heavy", "shake": 4, "label": "손도끼 내려찍기", "skill": true},
	# odohwa · 도끼 바꿔 쥐기 · 받아 쥐기 연계 — 손에 힘을 빼고 손바닥 위에서 도끼 자루를 굴려 바꿔 쥔다(준비) → 자루 끝으로 가슴을 찌르고 날을 크게 휘둘러 띄운 뒤 치켜들어 내려찍는다(실행) → 도끼를 다시 치켜든다(p1:105/022-027 · p1:105/046-056).
	"tk_odohwa_axe_flow": {"startup": 12, "active": 18, "recovery": 18, "damage": 8, "reach": 13, "radius": 11, "arc": 100, "lunge": 10, "hits": 3, "knockdown": true, "knockback": 2.0, "hitstop": 7, "posture": 14, "telegraph": "parry", "shape": "thrust", "seq": ["thrust", "slash_back", "overhead_chop"], "sfx": "swing", "hit_sfx": "hit_heavy", "shake": 3, "label": "도끼 바꿔 쥐기 · 받아 쥐기 연계", "skill": true},
	# odohwa · 일본도 · 칼 베기와 찌르기 — 일본도를 뽑는다(준비) → 크게 베고 팔을 일직선으로 뻗어 찌른다(실행) → 피가 흩어진다(p1:047/100-101 · p1:096/149-164). [근거: 047 회상은 얼굴이 가려져 해설로만 귀속]
	"tk_odohwa_blade": {"startup": 14, "active": 10, "recovery": 16, "damage": 11, "reach": 20, "radius": 10, "arc": 80, "lunge": 12, "hits": 2, "knockback": 2.8, "hitstop": 7, "posture": 16, "telegraph": "parry", "shape": "slash", "seq": ["slash", "thrust"], "sfx": "knife", "hit_sfx": "hit_heavy", "shake": 2, "label": "일본도 · 칼 베기와 찌르기", "skill": true},
	# odohwa · 권총 사격 · 쌍수 — 오른손 권총을 내밀고 왼손 손도끼를 세운다(준비) → 다가오는 칼을 도끼로 쳐내며 두 발 쏜다(인질을 방패로 세우기도)(실행) → 붙으면 도끼로 내리친다(p1:096/077-084 · p1:109/001-005).
	"tk_odohwa_gun": {"startup": 22, "active": 8, "recovery": 18, "damage": 9, "reach": 120, "radius": 5, "hits": 2, "parryable": false, "knockback": 2.2, "hitstop": 6, "posture": 12, "telegraph": "unblock", "shape": "shot", "seq": ["shot", "shot"], "sfx": "shot", "hit_sfx": "hit_heavy", "shake": 3, "label": "권총 사격 · 쌍수", "skill": true},
	# odohwa · 기만 · 임기응변 — 캐비닛 뒤에 숨어 기척을 죽인다(준비) → 캐비닛을 넘어뜨리며 몸으로 돌진하고, 그 위로 뛰어올라 도끼를 내려찍는다(실행) → 어깨에 총을 맞고도 버틴다(p1:108/005-013). [근거: 도끼 던지기 · 총알 튕기기는 연출로만(판정 없음) — 도끼 다시 쥐는 컷 직접 확인 없음]
	"tk_odohwa_trick": {"startup": 24, "active": 10, "recovery": 20, "damage": 11, "reach": 14, "radius": 11, "lunge": 34, "hits": 2, "parryable": false, "knockdown": true, "knockback": 4.0, "hitstop": 10, "posture": 22, "telegraph": "unblock", "feints": [10], "shape": "shoulder_ram", "seq": ["shoulder_ram", "overhead_chop"], "sfx": "wind", "hit_sfx": "hit_heavy", "shake": 5, "whiff": 18, "label": "기만 · 임기응변", "skill": true},
	# ojiin · 오지인 단검 찌르기 — 경계하며 단검을 낮게 쥔다(준비) → 몸을 내밀어 얼굴을 거듭 찌른다(실행) → 상대가 멈추고 피가 뿜어진다(p1:033/013-020 · 082/032-034).
	"tk_ojiin_dagger": {"startup": 10, "active": 12, "recovery": 14, "damage": 5, "reach": 13, "radius": 8, "lunge": 8, "hits": 3, "knockback": 0.8, "hitstop": 4, "posture": 7, "telegraph": "parry", "shape": "thrust", "seq": ["thrust", "thrust", "thrust"], "hand": "L", "sfx": "knife", "label": "오지인 단검 찌르기", "skill": true},
	# ojiin · 오지인 카타나 올려 베기 — 카타나를 낮게 쥐거나 쓰러진 채 두 손으로 쥔다(준비) → 아래에서 위로 대각선으로 베어 올린다(실행) → 피가 흩날리고 칼을 짚고 헐떡인다(069/170-171 · 082/035-036). [근거: 069 에 이름 없음 — 외형으로 귀속]
	"tk_ojiin_katana_upslash": {"startup": 14, "active": 4, "recovery": 16, "damage": 13, "reach": 20, "radius": 10, "arc": 70, "lunge": 8, "knockback": 3.4, "hitstop": 8, "posture": 18, "telegraph": "parry", "shape": "rising_slash", "sfx": "slash", "hit_sfx": "hit_heavy", "shake": 2, "label": "오지인 카타나 올려 베기", "skill": true},
	# pantera · 단검 돌진 · 내리꽂기 — 웃으며 몸을 낮춘다(준비) → 소매 밑 역수 단검으로 낮게 뛰어들어 덮치며 내리꽂는다(실행) → 가로베기를 숙여 흘리고 빠진다(020/015-019 · 076/041-045).
	"tk_pantera_dagger": {"startup": 14, "active": 5, "recovery": 18, "damage": 15, "reach": 13, "radius": 9, "lunge": 30, "parryable": false, "knockback": 3.0, "hitstop": 10, "posture": 22, "telegraph": "unblock", "shape": "reverse_stab", "hand": "L", "sfx": "knife", "hit_sfx": "hit_heavy", "shake": 3, "whiff": 16, "label": "단검 돌진 · 내리꽂기", "skill": true},
	# pantera · 소음기 권총 · 칼 양손 전진 — 어둠 · 모퉁이에 몸을 붙이고 오른손 소음기 권총, 왼손 칼을 아래로 쥔다(준비) → 모퉁이에서 엿보다 손을 노려 한 발 쏜다(실행) → 다시 붙는다(075/019-021 · 076/000-007). [근거: 난간 강하 · 착지 사격은 직접 확인 못 함(076/038 효과음만)]
	"tk_pantera_pistol": {"startup": 26, "active": 2, "recovery": 18, "damage": 13, "reach": 155, "radius": 4, "parryable": false, "knockback": 2.0, "hitstop": 7, "posture": 12, "telegraph": "unblock", "shape": "shot", "sfx": "shot", "hit_sfx": "hit_heavy", "shake": 3, "label": "소음기 권총 · 칼 양손 전진", "skill": true},
	# pyoyoung · 뛰어 날아차기 — 낮게 달려 도약한다(준비) → 벽 · 슬롯머신 · 상대 위를 넘으며 발을 꽂는다(실행) → 내려선다(p1:042/127-136 · p1:043/027-032 · 027/182-186).
	"tk_pyoyoung_jump_kick": {"startup": 18, "active": 4, "recovery": 20, "damage": 17, "reach": 14, "radius": 11, "lunge": 42, "parryable": false, "knockdown": true, "knockback": 5.0, "hitstop": 12, "posture": 26, "telegraph": "unblock", "shape": "flying_kick", "sfx": "kick", "hit_sfx": "hit_heavy", "shake": 5, "whiff": 18, "label": "뛰어 날아차기", "skill": true},
	# pyoyoung · 카람빗 낮은 파고들기 연속 베기 — 몸을 낮추고 카람빗을 역수로 쥔다(준비) → 낮게 파고들어 가로 베고 찌른 뒤 아래에서 얼굴로 그어 올린다(실행) → 등 · 옆으로 돌아 계속 붙는다(p1:105/031-032 · 098/011-031 · 115/030-034).
	"tk_pyoyoung_karambit_dive": {"startup": 12, "active": 12, "recovery": 14, "damage": 6, "reach": 12, "radius": 10, "arc": 90, "lunge": 26, "side": 10, "zigzag": true, "hits": 3, "knockback": 1.0, "hitstop": 4, "posture": 8, "telegraph": "parry", "shape": "thrust_low", "seq": ["thrust_low", "reverse_stab", "rising_slash"], "sfx": "slash", "label": "카람빗 낮은 파고들기 연속 베기", "skill": true},
	# pyoyoung · 카람빗 도약 내려 베기 — 낮게 달리거나 웅크려 양손 카람빗을 역수로 쥔다(준비) → 뛰어올라 머리 · 방패 위에서 두 칼을 벌려 X 로 내려 벤다(실행) → 칼날을 맞부딪치며 돌아 빠진다(p1:105/011-015 · 108/004-005).
	"tk_pyoyoung_karambit_leap": {"startup": 20, "active": 4, "recovery": 18, "damage": 18, "reach": 14, "radius": 11, "lunge": 34, "parryable": false, "guard_break": true, "knockback": 3.6, "hitstop": 11, "posture": 26, "telegraph": "unblock", "shape": "cross", "sfx": "slash", "hit_sfx": "hit_heavy", "shake": 4, "whiff": 18, "label": "카람빗 도약 내려 베기", "skill": true},
	# ratel · 라텔 조르기·사슬 구속 — 철사 · 쇠사슬을 손에 감아 쥔다(준비) → 목에 걸어 뒤로 젖혀 조르거나 총 쥔 손목을 묶는다(실행) → 상대가 쓰러지거나 손이 묶인다(p1:089/005 · 112/007-016).
	"tk_ratel_binding": {"startup": 20, "active": 24, "recovery": 20, "damage": 6, "reach": 11, "radius": 10, "lunge": 14, "hits": 3, "parryable": false, "guard_break": true, "knockback": 0.3, "hitstop": 6, "posture": 14, "telegraph": "unblock", "shape": "grab", "seq": ["grab", "choke", "choke"], "sfx": "wind", "hit_sfx": "hit", "shake": 2, "stun_3d": [60, 40], "whiff": 20, "label": "라텔 조르기·사슬 구속", "skill": true},
	# ratel · 라텔 카람빗 공격 — 높이 뛰어오르거나 달려든다(준비) → 위에서 카람빗을 내리찍고 몸통째 부딪쳐 칼을 밀어 넣는다(실행) → 칼이 맞물려 힘겨루기가 된다(030/123-125 · 037/054-063).
	"tk_ratel_karambit": {"startup": 18, "active": 10, "recovery": 18, "damage": 9, "reach": 13, "radius": 10, "lunge": 28, "hits": 2, "knockback": 2.8, "hitstop": 8, "posture": 16, "telegraph": "parry", "shape": "reverse_stab", "seq": ["reverse_stab", "shoulder_ram"], "sfx": "knife", "hit_sfx": "hit_heavy", "shake": 2, "label": "라텔 카람빗 공격", "skill": true},
	# ratel · 라텔 태클 — 몸을 낮춘다(준비) → 허리를 감아 들고 달려 벽에 처박는다(실행) → 상대를 벽에 붙여 둔다(046/016-018).
	"tk_ratel_tackle": {"startup": 18, "active": 8, "recovery": 20, "damage": 15, "reach": 12, "radius": 11, "lunge": 40, "parryable": false, "guard_break": true, "knockdown": true, "knockback": 6.5, "hitstop": 12, "posture": 30, "telegraph": "unblock", "shape": "tackle", "sfx": "wind", "hit_sfx": "hit_heavy", "shake": 5, "stun_3d": [30, 20], "whiff": 20, "label": "라텔 태클", "skill": true},
	# ratel · 라텔 쌍칼 베기 — 위에서 거꾸로 떨어지거나 두 팔을 X 로 세운다(준비) → 두 칼을 엇갈려 휘둘러 양옆을 동시에 베고 한 바퀴 돈다(실행) → 낮게 웅크려 내려선다(p1:090/002-003 · p1:092/003).
	"tk_ratel_twin_knife": {"startup": 14, "active": 10, "recovery": 16, "damage": 9, "reach": 0, "radius": 22, "hits": 2, "knockback": 2.4, "hitstop": 6, "posture": 12, "telegraph": "parry", "shape": "spin", "seq": ["cross", "spin"], "sfx": "slash", "hit_sfx": "hit_heavy", "shake": 2, "label": "라텔 쌍칼 베기", "skill": true},
	# richeon · 리천 줄 조르기 · 멱살 무릎 — 맞교환 거리에서 주먹을 낸다(준비) → 주먹을 안면에 꽂고 숙인 머리를 붙잡아 무릎으로 얼굴을 올려 친다(실행) → 상대가 무릎을 꿇는다(041/090-094 — 뒤에서 줄로 조르기 041/035-042 는 연출).
	"tk_richeon_choke_clinch": {"startup": 10, "active": 16, "recovery": 18, "damage": 8, "reach": 12, "radius": 10, "lunge": 10, "hits": 3, "knockback": 1.0, "hitstop": 8, "posture": 14, "telegraph": "parry", "shape": "jab", "seq": ["jab", "grab", "knee"], "sfx": "swing", "hit_sfx": "hit_heavy", "shake": 3, "stun_3d": [60, 30], "label": "리천 줄 조르기 · 멱살 무릎", "skill": true},
	# richeon · 리천 근접 제압 · 관절 · 메치기 — 한 발 디뎌 거리를 좁히고 손을 잡는다(준비) → 관절을 꺾고 턱을 잡아 메친 뒤 깍지 낀 두 손으로 내려친다(실행) → 상대가 무너져 무릎을 꿇는다(028/119-151 · 029/046-049 · 030/082-108). [근거: 손가락 꺾기 그림은 못 봄(028/032-034 대사 · 효과음뿐)]
	"tk_richeon_clinch": {"startup": 22, "active": 18, "recovery": 22, "damage": 9, "reach": 12, "radius": 10, "lunge": 12, "hits": 3, "parryable": false, "guard_break": true, "knockdown": true, "knockback": 3.0, "hitstop": 12, "posture": 26, "telegraph": "unblock", "shape": "grab", "seq": ["grab", "throw_slam", "two_hand_slam"], "sfx": "wind", "hit_sfx": "hit_heavy", "shake": 6, "whiff": 22, "label": "리천 근접 제압 · 관절 · 메치기", "skill": true},
	# richeon · 리천 단검 파고들기 · 내려찍기 — 구두 디딤발을 박고 단검을 역수로 쥔다(준비) → 옆으로 엇갈려 지나가며 베고 반대쪽에서 다시 들어와 내리찍는다(실행) → 다시 들어올 자리를 잡는다(040/097-099 · 041/001-011).
	"tk_richeon_dagger": {"startup": 14, "active": 12, "recovery": 16, "damage": 11, "reach": 13, "radius": 10, "arc": 80, "lunge": 24, "side": 12, "zigzag": true, "hits": 2, "knockback": 2.4, "hitstop": 8, "posture": 16, "telegraph": "parry", "shape": "slash", "seq": ["slash", "reverse_stab"], "hand": "L", "sfx": "knife", "hit_sfx": "hit_heavy", "shake": 2, "label": "리천 단검 파고들기 · 내려찍기", "skill": true},
	# richeon · 리천 사격 · 클린치 총격 — 정면으로 돌진하며 어깨를 내준다(준비) → 붙은 채 권총을 빼 들어 코앞에서 두 발 쏜다(실행) → 쓰러진 상대를 확인한다(040/068-098 · 041/096-099).
	"tk_richeon_gun": {"startup": 16, "active": 8, "recovery": 18, "damage": 10, "reach": 60, "radius": 5, "lunge": 18, "hits": 2, "parryable": false, "knockback": 2.6, "hitstop": 8, "posture": 16, "telegraph": "unblock", "shape": "draw_shot", "seq": ["draw_shot", "shot"], "sfx": "shot", "hit_sfx": "hit_heavy", "shake": 3, "label": "리천 사격 · 클린치 총격", "skill": true},
	# ryujihak · 도약 교차 내려 베기 — 코트 자락을 날리며 몸을 띄우고 칼을 뒤로 젖힌다(준비) → 공중에서 몸통을 내리그으며 상대와 엇갈려 지나간다(실행) → 등 뒤에 내려서서 돌아선다(p1:062/013-023 · p1:101/021-026).
	"tk_ryujihak_air_cross_slash": {"startup": 22, "active": 5, "recovery": 18, "damage": 20, "reach": 14, "radius": 11, "lunge": 44, "parryable": false, "knockdown": true, "knockback": 4.0, "hitstop": 12, "posture": 26, "telegraph": "unblock", "shape": "overhead_chop", "sfx": "slash", "hit_sfx": "hit_heavy", "shake": 5, "whiff": 18, "label": "도약 교차 내려 베기", "skill": true},
	# ryujihak · 휜 칼 큰 호 베기 — 두 휜 칼을 고쳐 쥔다(준비) → 돌진하며 큰 반원으로 베고 곧바로 반대 손으로 되벤다(실행) → 칼끝이 흘러 지나간다(012/005-006 · 013/033-116 · 085/011-013).
	"tk_ryujihak_curved_arc": {"startup": 16, "active": 10, "recovery": 16, "damage": 11, "reach": 16, "radius": 13, "arc": 160, "lunge": 14, "hits": 2, "knockback": 3.0, "hitstop": 7, "posture": 16, "telegraph": "parry", "shape": "slash", "seq": ["slash", "slash_back"], "sfx": "slash", "hit_sfx": "hit_heavy", "shake": 2, "label": "휜 칼 큰 호 베기", "skill": true},
	# ryujihak · 총 쥔 손 제압 · 권총 걸어 떨어뜨리기 — 칼을 낮추고 다가오는 손을 노린다(준비) → 들어온 손목을 잡아 젖히고 단도 날로 권총 · 팔을 걸어 떨어뜨린 뒤 찌른다(실행) → 총이 떨어지고 상대가 무너진다(p1:116/041-042 · p1:116/067-068 · 045/021-023).
	"tk_ryujihak_gun_disarm": {"startup": 16, "active": 3, "recovery": 14, "damage": 6, "reach": 11, "radius": 9, "lunge": 6, "knockback": 1.2, "hitstop": 5, "posture": 12, "telegraph": "", "shape": "guard_counter", "stance": 14, "sfx": "swing", "label": "총 쥔 손 제압 · 권총 걸어 떨어뜨리기", "skill": true, "stance_hit": "tk_ryujihak_gun_disarm_hit"},
	# ryujihak · 총 쥔 손 제압 · 권총 걸어 떨어뜨리기 맞받기
	"tk_ryujihak_gun_disarm_hit": {"startup": 2, "active": 8, "recovery": 14, "damage": 9, "reach": 12, "radius": 10, "lunge": 6, "hits": 2, "parryable": false, "knockback": 2.4, "hitstop": 10, "posture": 22, "shape": "grab", "seq": ["grab", "reverse_stab"], "sfx": "knife", "hit_sfx": "hit_heavy", "shake": 3, "stun_3d": [30, 20], "label": "총 쥔 손 제압 · 권총 걸어 떨어뜨리기", "skill": true},
	# ryujihak · 저자세 스치며 베기 — 두 칼을 고쳐 쥐고 몸을 낮춘다(준비) → 바닥을 박차 상대 휘두름 아래로 지나가며 하체를 벤다(실행) → 뒤로 빠져 방향을 바꾼다(p1:100/086-095 · p1:101/005-008 · 084/020-036). [근거: p1:079/005 은 김대건 속말 분석(가설) — 그림 근거는 p1:100 · 101 · 084]
	"tk_ryujihak_low_pass_slash": {"startup": 12, "active": 5, "recovery": 14, "damage": 13, "reach": 14, "radius": 9, "arc": 90, "lunge": 36, "side": 8, "iframes": true, "knockback": 2.2, "hitstop": 8, "posture": 20, "telegraph": "parry", "shape": "thrust_low", "sfx": "slash", "hit_sfx": "hit_heavy", "shake": 2, "label": "저자세 스치며 베기", "skill": true},
	# ryujihak · 방패 사이 파고들기 베기 — 포위 속을 질주하다 급정지한다(준비) → 방패 사이 · 밑으로 파고들며 찌르고 좌우로 연속 벤다(실행) → 빠져나가 감촉을 점검한다(043/056-062 · 044/035-086 · 045/005-009).
	"tk_ryujihak_shield_breach": {"startup": 20, "active": 15, "recovery": 18, "damage": 7, "reach": 13, "radius": 10, "arc": 80, "lunge": 30, "hits": 3, "parryable": false, "guard_break": true, "knockback": 1.4, "hitstop": 5, "posture": 12, "telegraph": "unblock", "feints": [8], "shape": "thrust", "seq": ["thrust", "slash", "slash_back"], "sfx": "slash", "hit_sfx": "hit_heavy", "shake": 2, "whiff": 14, "label": "방패 사이 파고들기 베기", "skill": true},
	# sainjin · 사인진 차량 공격 — 차 보닛 위에 올라선다(준비) → 뛰어내려 발바닥으로 짓밟고 이어 앞으로 차 낸다(실행) → 차로 돌아가 추격한다(107/036-041 — SUV 충돌은 연출). [근거: 원작은 차량(SUV 충돌 · 보닛 밟기 · 뒷유리 차기) — 맨몸 동작으로 옮김, 사격 컷 없음]
	"tk_sainjin_vehicle": {"startup": 20, "active": 10, "recovery": 18, "damage": 10, "reach": 13, "radius": 11, "lunge": 26, "hits": 2, "parryable": false, "knockdown": true, "knockback": 4.2, "hitstop": 10, "posture": 20, "telegraph": "unblock", "shape": "stomp", "seq": ["stomp", "front_kick"], "sfx": "kick", "hit_sfx": "hit_heavy", "shake": 5, "whiff": 16, "label": "사인진 차량 공격", "skill": true},
	# scaledanjang · 약 짓이기기 · 처형 연타 — 포로를 엎어 무릎으로 올라탄다(준비) → 머리를 움켜쥐고 주먹을 내리찍어 머리를 바닥에 박는다(실행) → 포로가 축 늘어진다(002/060-069). [근거: 원작은 쓰러진 포로에게 — 서 있는 상대에게 쓰는 것으로 옮김]
	"tk_scaledanjang_execution": {"startup": 18, "active": 20, "recovery": 20, "damage": 6, "reach": 11, "radius": 10, "lunge": 12, "hits": 4, "parryable": false, "guard_break": true, "knockback": 0.6, "hitstop": 6, "posture": 10, "telegraph": "unblock", "shape": "grab", "seq": ["grab", "hammer_fist", "hammer_fist", "hammer_fist"], "sfx": "kick", "hit_sfx": "hit_heavy", "shake": 3, "stun_3d": [50, 30], "whiff": 18, "label": "약 짓이기기 · 처형 연타", "skill": true},
	# scaledanjang · 마체테 · 칼 횡베기 — 허리 칼집에서 마체테를 뽑는다(준비) → 수평 · 사선으로 연달아 휘둘러 목을 벤다(실행) → 피 묻은 칼을 얼굴 앞에 세워 든다(004/213 · 005/150-160).
	"tk_scaledanjang_machete": {"startup": 15, "active": 10, "recovery": 16, "damage": 12, "reach": 17, "radius": 11, "arc": 130, "lunge": 8, "hits": 2, "knockback": 3.0, "hitstop": 8, "posture": 16, "telegraph": "parry", "shape": "slash", "seq": ["slash", "slash_back"], "sfx": "slash", "hit_sfx": "hit_heavy", "shake": 2, "label": "마체테 · 칼 횡베기", "skill": true},
	# scaledanjang · 권총 뽑아 겨누기 — 앉은 채 · 몸을 숙여 권총을 쥔다(준비) → 한 손으로 빼 들어 등 뒤 · 턱밑에 겨누고 '타탕' 두 발 쏜다(실행) → 아무 일 없다는 듯 걸어 나간다(003/104-111 · 005/088-091).
	"tk_scaledanjang_pistol": {"startup": 16, "active": 8, "recovery": 18, "damage": 9, "reach": 90, "radius": 5, "hits": 2, "parryable": false, "knockback": 2.4, "hitstop": 7, "posture": 12, "telegraph": "unblock", "shape": "draw_shot", "seq": ["draw_shot", "shot"], "sfx": "shot", "hit_sfx": "hit_heavy", "shake": 3, "label": "권총 뽑아 겨누기", "skill": true},
	# shingen · 받아치기 반격 — 일부러 맞아 주듯 몸을 비튼다(준비) → 들어온 공격을 흘리며 아래팔로 받아 치고 대도로 이어 벤다(실행) → 웃으며 다음 동작으로 간다(097/003-005 · 099/022-062). [근거: 반격 직접 컷은 097/004 몸 띄우기뿐(100/025 는 김신 쪽 컷)]
	"tk_shingen_counter": {"startup": 18, "active": 3, "recovery": 14, "damage": 8, "reach": 18, "radius": 10, "arc": 60, "lunge": 4, "knockback": 1.8, "hitstop": 5, "posture": 10, "telegraph": "", "shape": "weave", "stance": 16, "sfx": "knife", "label": "받아치기 반격", "skill": true, "stance_hit": "tk_shingen_counter_hit"},
	# shingen · 받아치기 반격 맞받기
	"tk_shingen_counter_hit": {"startup": 2, "active": 8, "recovery": 14, "damage": 12, "reach": 18, "radius": 11, "arc": 80, "lunge": 6, "hits": 2, "parryable": false, "knockback": 3.6, "hitstop": 10, "posture": 24, "shape": "elbow", "seq": ["elbow", "slash"], "sfx": "slash", "hit_sfx": "hit_heavy", "shake": 4, "label": "받아치기 반격", "skill": true},
	# shire · 쇠사슬 추 휘두르기 · 던지기 — 쇠사슬을 손목 · 주먹에 감는다(준비) → 추를 던져 얼굴 · 칼을 치거나 큰 호로 쓸어낸다(실행) → 사슬을 당겨 회수한다(p1:051/000 · 070/044-046). [근거: '승표' 이름은 확인 안 됨]
	"tk_shire_chain": {"startup": 18, "active": 5, "recovery": 20, "damage": 13, "reach": 34, "radius": 8, "arc": 140, "knockback": 3.4, "hitstop": 9, "posture": 18, "telegraph": "parry", "shape": "toss", "sfx": "wind", "hit_sfx": "hit_heavy", "shake": 3, "stun_3d": [24, 12], "whiff": 10, "label": "쇠사슬 추 휘두르기 · 던지기", "skill": true},
	# shire · 텐트 습격 · 제압 사살 — 텐트 밖에서 기다린다(준비) → 칼을 사선으로 긋고 들어가 장갑 손으로 입을 막아 누른 뒤 소음기 권총을 관자놀이에 댄다(실행) → 피가 번진다(135/015-017 · 135/024-025). [근거: 칼 + 소음기 권총 둘 다 듦(weapon 은 칼로 적음)]
	"tk_shire_tent_assault": {"startup": 18, "active": 18, "recovery": 22, "damage": 9, "reach": 13, "radius": 10, "lunge": 16, "hits": 3, "parryable": false, "guard_break": true, "knockback": 1.0, "hitstop": 10, "posture": 16, "telegraph": "unblock", "shape": "slash", "seq": ["slash", "grab", "draw_shot"], "sfx": "knife", "hit_sfx": "hit_heavy", "shake": 5, "whiff": 20, "label": "텐트 습격 · 제압 사살", "skill": true},
	# ttolbae · 큐 · 쇠파이프 내려치기 — 큐를 쥐고 노려본다(준비) → '어디 실력 좀 보자!' 외치며 큐 · 쇠파이프를 사선으로 크게 휘두른다(실행) → 헛치면 큐를 잡아채인다(p1:066/103-108 · 038/045-048).
	"tk_ttolbae_club_swing": {"startup": 16, "active": 4, "recovery": 16, "damage": 12, "reach": 18, "radius": 11, "arc": 120, "lunge": 6, "knockback": 3.2, "hitstop": 8, "posture": 16, "telegraph": "parry", "shape": "slash", "sfx": "swing", "hit_sfx": "hit_heavy", "shake": 2, "whiff": 16, "label": "큐 · 쇠파이프 내려치기", "skill": true},
	# ttolbae · 파고드는 · 돌려 발차기 — 당구대 위에 올라서거나 몸을 낮춰 품으로 파고든다(준비) → 몸을 한 바퀴 돌려 뒷다리로 머리를 흰 원호로 후려친다(실행) → 상대가 당구대 모서리에 숙인다(p1:067/011-015 · p1:066/114-118). [근거: 066/114-118 은 이슬 반격이 섞인 맞교환 — 돌려차기(067)만 확실]
	"tk_ttolbae_kick": {"startup": 18, "active": 4, "recovery": 18, "damage": 15, "reach": 15, "radius": 11, "arc": 120, "lunge": 14, "knockdown": true, "knockback": 4.4, "hitstop": 10, "posture": 22, "telegraph": "parry", "shape": "spin_back_kick", "sfx": "kick", "hit_sfx": "hit_heavy", "shake": 3, "label": "파고드는 · 돌려 발차기", "skill": true},
	# ttolbae · 당구공 던지기 — 당구공을 집는다(준비) → 어깨 위에서 얼굴로 던진다(실행) → 상대가 휘청인다(p1:066/109-113 · p1:067/006-010).
	"tk_ttolbae_pool_ball": {"startup": 14, "active": 2, "recovery": 14, "damage": 6, "reach": 110, "radius": 5, "knockback": 1.2, "hitstop": 5, "posture": 10, "telegraph": "parry", "shape": "toss", "sfx": "swing", "hit_sfx": "hit", "stun_3d": [20, 10], "label": "당구공 던지기", "skill": true},
	# vasily · 삼보 그라운드 기술 — 상대 허리 · 팔을 붙잡는다(준비) → 들어 올려 머리부터 꽂고 위에서 내려친다(실행) → 다리를 넘겨 위를 잡는다(p1:040/040-054). [근거: '삼보'는 출신 설명 · '늪' 팔 꺾기는 확인 안 됨]
	"tk_vasily_sambo": {"startup": 22, "active": 10, "recovery": 22, "damage": 13, "reach": 12, "radius": 10, "lunge": 14, "hits": 2, "parryable": false, "guard_break": true, "knockdown": true, "knockback": 2.0, "hitstop": 14, "posture": 30, "telegraph": "unblock", "shape": "grab", "seq": ["grab", "throw_slam"], "sfx": "wind", "hit_sfx": "hit_heavy", "shake": 6, "stun_3d": [60, 40], "whiff": 22, "label": "삼보 그라운드 기술", "skill": true},
	# vasily · 큰 주먹 휘두르기 — '이런...씨!' 하며 몸을 돌린다(준비) → 오른팔을 크게 휘두르거나 뛰어올라 위에서 아래로 내리친다('붕')(실행) → 빗나가면 빈 공간에 손을 뻗은 채 남는다(p1:040/023-030).
	"tk_vasily_swing": {"startup": 18, "active": 4, "recovery": 18, "damage": 16, "reach": 14, "radius": 12, "arc": 150, "lunge": 10, "knockback": 4.4, "hitstop": 9, "posture": 20, "telegraph": "parry", "shape": "hook", "sfx": "swing", "hit_sfx": "hit_heavy", "shake": 3, "whiff": 22, "label": "큰 주먹 휘두르기", "skill": true},
	# woojin · 피우진 발차기 — 발을 디디고 상체를 젖힌다(준비) → 정강이로 허벅지를 낮게 찬 뒤 구두 앞코로 몸통을 밀어 찬다(실행) → 거리를 벌리고 주먹으로 잇는다(009/008 · 010/001-002 · 039/010-011).
	"tk_woojin_kick": {"startup": 8, "active": 10, "recovery": 14, "damage": 7, "reach": 14, "radius": 10, "lunge": 6, "hits": 2, "knockback": 2.4, "hitstop": 6, "posture": 18, "shape": "low_kick", "seq": ["low_kick", "front_kick"], "sfx": "kick", "hit_sfx": "hit_heavy", "shake": 2, "label": "피우진 발차기", "skill": true},
	# woojin · 내리꽂는 주먹 — 오른 주먹을 머리 위로 높이 치켜든다(뛰어오르기도)(준비) → 위에서 아래로 얼굴 · 정수리 · 가드 위에 내리친다(실행) → 연타로 잇거나 상대가 쓰러진다(134/037-038 · 042/043-050). [근거: 009/010@7314 내리꽂기 컷은 못 찾음]
	"tk_woojin_overhead": {"startup": 12, "active": 4, "recovery": 16, "damage": 16, "reach": 13, "radius": 10, "lunge": 10, "guard_break": true, "knockback": 2.0, "hitstop": 12, "posture": 28, "shape": "hammer_fist", "sfx": "kick", "hit_sfx": "hit_heavy", "shake": 4, "label": "내리꽂는 주먹", "skill": true},
	# woojin · 들어 메다꽂기 · 던지기 — 허리 · 옷깃 · 머리를 움켜쥔다(준비) → 거꾸로 들거나 어깨 너머로 넘겨 바닥에 내리꽂는다(실행) → 함께 쓰러졌다 일어나 숨을 고른다(p1:040/061-066 · p1:041/056-068 · 039/129-148). [근거: 129 는 누운 채 다리 걸기(woojin_leg_sweep 로 분리됨) — 133/030 업어 던지기 · p1 컷 근거]
	"tk_woojin_suplex": {"startup": 10, "active": 8, "recovery": 22, "damage": 10, "reach": 11, "radius": 10, "lunge": 10, "hits": 2, "parryable": false, "guard_break": true, "knockdown": true, "knockback": 3.0, "hitstop": 14, "posture": 26, "shape": "grab", "seq": ["grab", "throw_slam"], "sfx": "wind", "hit_sfx": "hit_heavy", "shake": 6, "stun_3d": [50, 30], "whiff": 18, "label": "들어 메다꽂기 · 던지기", "skill": true},
	# yuwoosung · 칼 연속 · 근접 찌르기 — 상대를 잡아당겨 고정한다(준비) → 허벅지 · 옆구리를 연달아 찌르고 아래에서 찔러 올린 뒤 거꾸로 들어 메친다(실행) → 쓰러진 상대를 내려다본다(048/010-014 · 049/051-099).
	"tk_yuwoosung_dagger_stab": {"startup": 16, "active": 20, "recovery": 20, "damage": 6, "reach": 11, "radius": 10, "lunge": 14, "hits": 4, "parryable": false, "guard_break": true, "knockdown": true, "knockback": 2.6, "hitstop": 6, "posture": 12, "telegraph": "unblock", "shape": "grab", "seq": ["grab", "thrust_low", "thrust", "throw_slam"], "sfx": "knife", "hit_sfx": "hit_heavy", "shake": 3, "whiff": 18, "label": "칼 연속 · 근접 찌르기", "skill": true},
	# yuwoosung · 한 손 권총 사격 — 걸으며 다가간다(준비) → 한 손 소음기 권총을 세 번 연사한다(바닥 총을 쏴 날리기도)(실행) → 난간을 넘어 그대로 나아간다(028/037-042 · 028/079-080 · 047/062-066).
	"tk_yuwoosung_gun_shot": {"startup": 22, "active": 14, "recovery": 18, "damage": 6, "reach": 140, "radius": 6, "hits": 3, "parryable": false, "knockback": 1.6, "hitstop": 4, "posture": 9, "telegraph": "unblock", "shape": "shot", "seq": ["shot", "shot", "shot"], "sfx": "shot", "hit_sfx": "hit", "shake": 2, "label": "한 손 권총 사격", "skill": true},
	# yuwoosung · 물건 이용 타격 — 가까운 술병 · 잔 · 의자를 쥐거나 발에 건다(준비) → 술병을 머리에 내려쳐 깨고 의자를 차 보낸다(실행) → '협상 결렬이군.'(015/183-188 · 016/007 · 047/010-015). [근거: 병 바닥에 던져 '쾅'(016/007@9063)은 못 봄]
	"tk_yuwoosung_prop_strike": {"startup": 14, "active": 10, "recovery": 16, "damage": 9, "reach": 13, "radius": 10, "lunge": 8, "hits": 2, "knockback": 3.0, "hitstop": 8, "posture": 16, "telegraph": "parry", "shape": "hammer_fist", "seq": ["hammer_fist", "front_kick"], "sfx": "swing", "hit_sfx": "hit_heavy", "shake": 3, "stun_3d": [30, 20], "label": "물건 이용 타격", "skill": true},
	# yuwoosung · 시체 · 인질 방패 — 시체 · 인질의 멱살을 움켜쥐고 앞에 세운다(준비) → 들어오는 공격을 인질 몸으로 받고 그 몸 너머로 관통 사격하거나, 안 오면 인질째 밀어붙인다(실행) → 인질을 버리고 걸어간다(047/089-091 · 049/055-060). [근거: 인질 · 시체 소품이 필요 — 없으면 자세만(그림)]
	"tk_yuwoosung_shield_hostage": {"startup": 20, "active": 5, "recovery": 18, "damage": 12, "reach": 12, "radius": 11, "lunge": 24, "knockdown": true, "knockback": 4.6, "hitstop": 9, "posture": 20, "telegraph": "", "shape": "shoulder_ram", "stance": 18, "sfx": "wind", "hit_sfx": "hit_heavy", "shake": 3, "label": "시체 · 인질 방패", "skill": true, "stance_hit": "tk_yuwoosung_shield_hostage_hit"},
	# yuwoosung · 시체 · 인질 방패 맞받기
	"tk_yuwoosung_shield_hostage_hit": {"startup": 3, "active": 2, "recovery": 16, "damage": 16, "reach": 90, "radius": 5, "parryable": false, "knockback": 3.0, "hitstop": 10, "posture": 20, "shape": "shot", "sfx": "shot", "hit_sfx": "hit_heavy", "shake": 4, "label": "시체 · 인질 방패", "skill": true},
}

const OVERRIDE := {
	# guilhwa · 팔뚝 연타 — 근거리에서(준비) 팔꿈치 · 팔뚝으로 경호원 얼굴을 연달아 후려친다 — 팔꿈치 · 팔뚝 등 · 팔꿈치(실행, 057/056 '콰') → 얼굴에 웃음, 상대가 버틴다(058). [근거: conf ai — 효과음뿐(지금 값 유지, 모양만 팔꿈치로)]
	"s_gu_forearm": {"shape": "elbow", "seq": ["elbow", "backfist", "elbow"], "reach": 11, "sfx": "kick", "hit_sfx": "hit_heavy"},
	# guilhwa · 들이받기 — 몸을 낮춰(준비) 뛰어들며 머리 · 어깨로 경호원 턱 · 목을 받는다(실행, 057/065 '콰악') → 상대가 '쿵' 쓰러진다(066). [근거: conf ai — 묘사]
	"s_gu_headbutt": {"shape": "headbutt", "knockdown": true, "telegraph": "parry"},
	# gyeonghodaechoehuui4in · 칼 내리찍기 — 칼을 머리 위로 치켜들었다가(준비) → 한 손으로 위에서 아래로 내리찍는다(실행, 033/057-060 — 마준영 칼 내리찍기의 하향) → 칼끝이 바닥 가까이. [근거: conf ai — 마준영 기술 하향(근거 글 없음)]
	"s_g4_chop": {"shape": "overhead_chop"},
	# gyeonghodaechoehuui4in · 내려찍기 하이킥 — 다리를 머리 높이까지 곧게 들어 올렸다가(준비) → 뒤꿈치로 내려찍는다(실행, 002/101-103 — 마준영 구속복 하이킥의 하향) → 맞으면 잠깐 기절. [근거: conf ai — 하향]
	"s_g4_heel": {"shape": "axe_kick"},
	# gyeonghodaechoehuui4in · 근거리 사격 — 권총을 겨누고(준비, 빨간 !) → 한 발 쏜다(실행, 045/082-086) → 총구를 거둔다. [근거: conf ai — 하향. shape draw_shot 이 선 판정을 이어받아야 한다(world.gd shape shot)]
	"t_shot": {"shape": "draw_shot"},
	# hayabusa · 낮은 다리 베기 — 무릎 꿇듯 몸을 낮추고(준비) → 칼날을 바닥 가까이 그어 상대 다리를 벤다(실행, 095/080 '어이, 가네무라.') → 낮은 자세에서 일어난다. [근거: conf ai — 신겐 낮은 파고들기 하향]
	"s_hy_low": {"arc": 80},
	# hwangbomincheol · 얼굴 스치기 베기 — 돌진해 오는 상대를 칼을 내린 채 기다리다(준비) → 맞받아 오른손 칼로 얼굴 높이를 가로로 스친다(실행, p1:026/005 '탓') → 서로 물러선다(010 '타탓'). [근거: conf ai — 효과음뿐]
	"hb_face": {"startup": 15, "stance": 12, "shape": "guard_counter", "stance_hit": "hb_face_hit"},
	# iseul · 양팔 머리 낚아채 메다꽂기 — 좌우에서 칼 든 둘이 찌르며 다가오면(준비, p1:028/065) → 양팔로 두 사람 머리를 동시에 감아 쥐고(066 '콱!') → 바닥에 내리꽂는다(068). [근거: conf ai]
	"s_is_slam": {"hits": 2, "active": 10, "damage": 8, "shape": "grab", "seq": ["grab", "two_hand_slam"]},
	# iseul · 붙잡아 후려 날리기 — 칼 든 사내를 마주 붙잡고(준비, p1:026/000 '으라아앗!') → 오른팔을 크게 휘둘러 후려쳐 멀리 날려 보낸다(실행, 001 '퍽' '억') → 팔을 편 채 선다. [근거: conf ai]
	"s_is_throw": {"hits": 2, "active": 8, "damage": 8, "shape": "grab", "seq": ["grab", "hook"]},
	# jintae · 근거리 급소 베기 — 바짝 붙은 상태에서(준비, 047/030 오른손 권총 · 왼손 역수 단검) → 왼손 역수 칼로 급소를 짧게 벤다(실행, '얼마나 빨리 닿느냐가 관건이잖아') → 바로 물러선다. [근거: conf guess — 대사 요지뿐]
	"s_jt_vital": {"shape": "reverse_stab"},
	# kimshin · 아무르 티그로 3연타 — 품으로 파고들어(준비) → 하복부에 주먹을 '쾅, 쾅, 쾅' 세 번 꽂는다(실행, p1:020/017-023) → 셋째 대에 상대가 몸을 접고 0.5초 멈춘다. [근거: conf guess — 원작은 5~6타 연속(주먹 · 팔 · 늑골 · 가슴 차기), '3연타'는 게임 작명]
	"s_amur3": {"shape": "body_blow", "seq": ["body_blow", "body_blow", "body_blow"]},
	# kimshin · 아무르 티그로 위빙 — 상체를 좌우로 흔들어 들어오는 공격을 다 흘리며(준비, p1:020/005 숙여 빠짐) → 훅 · 옆구리 · 어퍼 세 대를 꽂는다(실행) → 외성 상위 이하는 쓰러진다. [근거: conf guess — 기술명은 게임 작명]
	"s_weave": {"shape": "weave", "seq": ["hook", "body_blow", "uppercut"]},
	# kimshin · 각법 — 다리를 머리 위까지 곧게 들어 올렸다가(준비) → 바닥까지 내려찍는다(실행, p1:113/040 '이 각법은…') → 맞으면 기절(아랫급 3초 · 같은 급 · 윗급 1초). [근거: 원작 각법은 백도찬 대사 — 김신이 쓰는 것은 사용자 결정]
	"s_kick": {"shape": "axe_kick"},
	# kimshin · 리천식 삼연타 — 상대의 방심을 노려(준비) → 왼 잽 두 번으로 붙잡아 두고 오른 스트레이트를 세게 꽂는다(실행) → 셋째 대에 기절. 총을 들었으면 총을 내줘 상대가 받는 사이 친다. [근거: 리천식 기술(owner richeon) — 원작 refs 없음]
	"s_triple": {"shape": "jab", "seq": ["jab", "jab", "straight"]},
	# kimshin · 좌우로 사라지는 스텝 — 좌우로 사라지듯 비켜 들어가(준비, 073/045 '또 사라졌...') → 옆에서 단검을 두 번 찔러 넣는다(실행, 047 어깨 · 목 뒤) → 몸통 강타로 끝(048). [근거: '좌우로 사라지는 스텝'은 구스타프 해설 문구]
	"s_vanish": {"shape": "sidestep"},
	# namgunghyuk · 너클 훅 — 오른 주먹을 크게 뒤로 젖힌다(준비) → 금 너클 주먹을 둥근 궤적으로 휩쓸어 옆얼굴을 친다(실행) → 상대가 피를 튀기며 나가떨어진다(p1:029/117-118 · p1:030/010).
	"ng_hook": {"shape": "hook"},
	# shingen · 대극 큰 호 베기 — 대극(긴 칼)을 옆으로 크게 뻗어 든다(준비) → 흰 호를 그리며 크게 휘두르고 곧바로 아래에서 위로 쳐올린다(실행) → 칼을 높이 든 채 멈춘다(062/084-106 · 098/035-047).
	"s_sg_daegeuk": {"active": 10, "hits": 2, "damage": 13, "seq": ["slash", "rising_slash"]},
	# shingen · 앞차기 — 무게를 뒷발에 싣는다(준비) → 구두 바닥으로 몸통을 정면으로 밀어 찬다(실행) → 상대가 멀리 날아간다(097/000-001 · 101/036-037).
	"s_sg_kick": {"shape": "front_kick"},
	# shingen · 날아차기 — 창틀 · 바닥을 박차 한 발로 뛰어오른다(준비) → 위에서 내리찍듯 발바닥으로 흉골을 찬다(실행) → 상대가 유리창을 깨며 날아간다(101/042-044 · 085/014).
	"s_sg_leap": {"shape": "flying_kick", "knockdown": true},
	# sintaejin · 숨긴 두 번째 칼 — 얼굴 찌르기 · 수평 베기로 시선을 끈다(준비) → 허리 뒤 가로 칼집의 칼을 왼손으로 뽑아 왼어깨를 찌른다(실행) → 쌍칼로 밀어붙인다(p1:032/032-038).
	"st_second": {"feints": [7], "shape": "reverse_stab"},
	# woojin · 미친 코어 카운터 맞받기 그림
	"s_wj_core_hit": {"shape": "uppercut"},
	# woojin · 미친 코어 카운터 — 몸을 낮춰 가드를 올린 받을 자세(준비) → 들어온 공격을 흘리고 코어를 비틀어 올려 치기로 강하게 맞받는다(실행) → 상대가 1초 기절한다. [근거: 원작 refs 없음(conf guess — 사용자 정의 기술)]
	"s_wj_core": {"shape": "guard_counter"},
}

const BY_SKILL := {
	"andy_hook_bind": "tk_andy_hook_bind",
	"andy_hook_slash": "tk_andy_hook_slash",
	"andy_hook_stance": "tk_andy_hook_stance",
	"barista_curved_blade": "tk_barista_curved_blade",
	"barista_gun_handling": "tk_barista_gun_handling",
	"barista_strike": "tk_barista_strike",
	"deumiteuri_scalpel": "tk_deumiteuri_scalpel",
	"douchen_grip": "tk_douchen_grip",
	"douchen_heavy_punch": "tk_douchen_heavy_punch",
	"douchen_slam": "tk_douchen_slam",
	"eunbo_throw": "tk_eunbo_throw",
	"gcs_slash": "tk_gcs_slash",
	"gmj_punch": "tk_gmj_punch",
	"grolla_blade": "tk_grolla_blade",
	"grolla_kick": "tk_grolla_kick",
	"grolla_low_kick": "tk_grolla_low_kick",
	"grolla_low_shoot": "tk_grolla_low_shoot",
	"grolla_throw_slam": "tk_grolla_throw_slam",
	"guilhwa_forearm": "s_gu_forearm",
	"guilhwa_headbutt": "s_gu_headbutt",
	"guilhwa_punch": "tk_guilhwa_punch",
	"gus_blade": "tk_gus_blade",
	"gus_gun": "tk_gus_gun",
	"gus_hammer_fist": "tk_gus_hammer_fist",
	"gus_slam": "tk_gus_slam",
	"gus_tackle_headbutt": "tk_gus_tackle_headbutt",
	"g4_chop": "s_g4_chop",
	"g4_heelkick": "s_g4_heel",
	"g4_shot": "t_shot",
	"han_golf_swing": "tk_han_golf_swing",
	"hayabusa_arc": "s_hy_arc",
	"hayabusa_low": "s_hy_low",
	"hwangbo_bait": "hb_bait",
	"hwangbo_dual_blade": "tk_hwangbo_dual_blade",
	"hwangbo_face_counter": "hb_face",
	"iseul_double_slam": "s_is_slam",
	"iseul_grab_down": "tk_iseul_grab_down",
	"iseul_throw": "s_is_throw",
	"jangho_air_strike": "tk_jangho_air_strike",
	"jangho_counter_punch": "tk_jangho_counter_punch",
	"jangho_slam_choke": "tk_jangho_slam_choke",
	"jin_original": "s_jt_original",
	"jintae_dual_dagger": "tk_jintae_dual_dagger",
	"jintae_low_slash": "tk_jintae_low_slash",
	"jintae_storm": "s_jt_storm",
	"jintae_vital": "s_jt_vital",
	"kimdaegeon_big_punch": "tk_kimdaegeon_big_punch",
	"kimdaegeon_jacket_wrap": "tk_kimdaegeon_jacket_wrap",
	"kimdaegeon_slam": "tk_kimdaegeon_slam",
	"kimseongjun_knife": "tk_kimseongjun_knife",
	"amur_triple": "s_amur3",
	"amur_weaving": "s_weave",
	"hyeonseok_blade": "tk_hyeonseok_blade",
	"kickarts": "s_kick",
	"kimshin_blade_defense": "tk_kimshin_blade_defense",
	"kimshin_bluff_feint": "tk_kimshin_bluff_feint",
	"kimshin_body_charge": "tk_kimshin_body_charge",
	"kimshin_choke": "tk_kimshin_choke",
	"kimshin_clinch_shot": "tk_kimshin_clinch_shot",
	"kimshin_counter_punch": "tk_kimshin_counter_punch",
	"kimshin_dark_ambush": "tk_kimshin_dark_ambush",
	"kimshin_dual_knife": "tk_kimshin_dual_knife",
	"kimshin_elbow_knee": "tk_kimshin_elbow_knee",
	"kimshin_flying_kick": "tk_kimshin_flying_kick",
	"kimshin_improvised": "tk_kimshin_improvised",
	"kimshin_karambit": "tk_kimshin_karambit",
	"kimshin_kick": "tk_kimshin_kick",
	"kimshin_knife_slash": "tk_kimshin_knife_slash",
	"kimshin_knife_stab": "tk_kimshin_knife_stab",
	"kimshin_leaping_blade": "tk_kimshin_leaping_blade",
	"kimshin_low_dash": "tk_kimshin_low_dash",
	"kimshin_pistol_butt": "tk_kimshin_pistol_butt",
	"kimshin_reverse_grip": "tk_kimshin_reverse_grip",
	"kimshin_running_shot": "tk_kimshin_running_shot",
	"kimshin_throw": "tk_kimshin_throw",
	"kimshin_wrist_grab": "tk_kimshin_wrist_grab",
	"offbeat": "s_offbeat",
	"offbeat2": "s_offbeat2",
	"offbeat_rev": "s_offbeat_rev",
	"triple": "s_triple",
	"vanish_step": "s_vanish",
	"komodo_ring_spin": "tk_komodo_ring_spin",
	"lingling_chain_cleaver": "tk_lingling_chain_cleaver",
	"lingling_cleaver_overhead": "tk_lingling_cleaver_overhead",
	"mahak_boot_kick": "tk_mahak_boot_kick",
	"mahak_close_fire": "tk_mahak_close_fire",
	"mahak_dive_shoot": "tk_mahak_dive_shoot",
	"mahak_glove_punch": "tk_mahak_glove_punch",
	"mahak_grip_slam": "tk_mahak_grip_slam",
	"mahak_shield_rush": "tk_mahak_shield_rush",
	"mahak_throw": "tk_mahak_throw",
	"mj_close_fire": "tk_mj_close_fire",
	"mj_dagger_stab": "tk_mj_dagger_stab",
	"mj_shield_rush": "tk_mj_shield_rush",
	"mj_vehicle_smash": "tk_mj_vehicle_smash",
	"mark_body_charge": "tk_mark_body_charge",
	"mark_knuckle": "tk_mark_knuckle",
	"namgung_kick": "tk_namgung_kick",
	"namgung_knuckle_combo": "tk_namgung_knuckle_combo",
	"namgung_knuckle_counter": "tk_namgung_knuckle_counter",
	"namgung_knuckle_hook": "ng_hook",
	"namilho_guard": "tk_namilho_guard",
	"namilho_strike_throw": "tk_namilho_strike_throw",
	"namilho_thin_blade": "tk_namilho_thin_blade",
	"odohwa_axe_chop": "tk_odohwa_axe_chop",
	"odohwa_axe_flow": "tk_odohwa_axe_flow",
	"odohwa_blade": "tk_odohwa_blade",
	"odohwa_gun": "tk_odohwa_gun",
	"odohwa_trick": "tk_odohwa_trick",
	"ojiin_dagger": "tk_ojiin_dagger",
	"ojiin_katana_upslash": "tk_ojiin_katana_upslash",
	"ojiin_skirt_dagger": "oj_dagger",
	"pantera_dagger": "tk_pantera_dagger",
	"pantera_pistol": "tk_pantera_pistol",
	"pyoyoung_jump_kick": "tk_pyoyoung_jump_kick",
	"pyoyoung_karambit_dive": "tk_pyoyoung_karambit_dive",
	"pyoyoung_karambit_leap": "tk_pyoyoung_karambit_leap",
	"ratel_binding": "tk_ratel_binding",
	"ratel_karambit": "tk_ratel_karambit",
	"ratel_tackle": "tk_ratel_tackle",
	"ratel_twin_knife": "tk_ratel_twin_knife",
	"richeon_choke_clinch": "tk_richeon_choke_clinch",
	"richeon_clinch": "tk_richeon_clinch",
	"richeon_dagger": "tk_richeon_dagger",
	"richeon_gun": "tk_richeon_gun",
	"ryujihak_air_cross_slash": "tk_ryujihak_air_cross_slash",
	"ryujihak_curved_arc": "tk_ryujihak_curved_arc",
	"ryujihak_gun_disarm": "tk_ryujihak_gun_disarm",
	"ryujihak_low_pass_slash": "tk_ryujihak_low_pass_slash",
	"ryujihak_shield_breach": "tk_ryujihak_shield_breach",
	"sainjin_vehicle": "tk_sainjin_vehicle",
	"scaledanjang_execution": "tk_scaledanjang_execution",
	"scaledanjang_machete": "tk_scaledanjang_machete",
	"scaledanjang_pistol": "tk_scaledanjang_pistol",
	"shingen_counter": "tk_shingen_counter",
	"shingen_daegeuk": "s_sg_daegeuk",
	"shingen_dive": "s_sg_dive",
	"shingen_frontkick": "s_sg_kick",
	"shingen_leap": "s_sg_leap",
	"shire_chain": "tk_shire_chain",
	"shire_tent_assault": "tk_shire_tent_assault",
	"sintaejin_pistol": "st_pistol",
	"sintaejin_second_blade": "st_second",
	"sintaejin_sweep": "st_sweep",
	"ttolbae_club_swing": "tk_ttolbae_club_swing",
	"ttolbae_kick": "tk_ttolbae_kick",
	"ttolbae_pool_ball": "tk_ttolbae_pool_ball",
	"vasily_sambo": "tk_vasily_sambo",
	"vasily_swing": "tk_vasily_swing",
	"woojin_core_counter": "s_wj_core",
	"woojin_kick": "tk_woojin_kick",
	"woojin_overhead": "tk_woojin_overhead",
	"woojin_suplex": "tk_woojin_suplex",
	"yuwoosung_dagger_stab": "tk_yuwoosung_dagger_stab",
	"yuwoosung_gun_shot": "tk_yuwoosung_gun_shot",
	"yuwoosung_prop_strike": "tk_yuwoosung_prop_strike",
	"yuwoosung_shield_hostage": "tk_yuwoosung_shield_hostage",
}
