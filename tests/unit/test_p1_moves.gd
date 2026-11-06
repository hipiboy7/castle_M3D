extends "res://tests/helpers.gd"
## 0 · 1장(1부 처음) 동작 · 적 프로필(A 등급 — src/data/moves.gd 3층 표 · src/combat/enemy_ai.gd PROFILES 표 값).
## 표끼리 맞는지: 프로필이 부르는 동작이 다 있다 · 사람마다 제 동작(뼈대 복사 아님) · 프레임이 말이 된다 · 못 막는 큰 동작은
## 빨간 ! 로 읽을 틈이 있다 · 김혁주 첫 베기는 잽 · 두 번째가 진짜(멈칫) · 2차가 있는 보스는 2차 표가 따로 ·
## 김신 맨손 연타 차례. 판정 규칙은 그대로(fighter · world) — 그 규칙 위에서 새 동작이 뜻대로 걸리는지도 본다(기절 · 넘어짐 · 버팀).

const EnemyAI = preload("res://src/combat/enemy_ai.gd")
const Prologue = preload("res://src/data/prologue.gd")
const Hoeam = preload("res://src/data/hoeam.gd")

## 0 · 1장 프로필 → 그 사람 동작 id 머리
const OWNERS := {"thug": "m_", "thug_brute": "m_", "thug_revolver": "m_", "thug_uzi": "m_", "thug_pipe": "m_", "gunter": "gt_",
	"hyeokju": "hj_", "seongjun": "sj_", "daegeon": "dg_", "manjae": "mj_", "deoksu": "yd_"}
const PREFIXES := ["m_", "gt_", "hj_", "sj_", "dg_", "mj_", "yd_"]
const READ_MIN := 14          # 못 막는 동작(빨간 !)의 준비 프레임 하한 — 보고 구를 틈(봇은 7프레임 앞에서 구른다)


static func _moves_of(prof: Dictionary) -> Array:
	var out: Array = []
	for p in prof["patterns"].values():
		for step in p:
			out.append(str(step[0]))
	if prof.has("ranged"):
		out.append(str(prof["ranged"][0]))
	if prof.has("counter"):
		out.append(str(prof["counter"][0]))
	return out


## 프로필의 한 차(phase 1 · 2) 무게 표에 나오는 동작
static func _phase_moves(prof: Dictionary, phase: int) -> Array:
	var out: Array = []
	var tables: Array = prof["weights"]
	for row in tables[mini(phase, tables.size()) - 1]:
		for step in prof["patterns"][row[0]]:
			out.append(str(step[0]))
	return out


static func _enemy_ids() -> Array:
	var out: Array = []
	for k in Moves.M:
		for p in PREFIXES:
			if str(k).begins_with(p):
				out.append(k)
	return out


func test_p1_profiles_use_own_moves() -> void:
	for pid in OWNERS:
		check(EnemyAI.PROFILES.has(pid), "프로필 %s" % pid)
		var prof: Dictionary = EnemyAI.PROFILES.get(pid, {})
		if prof.is_empty():
			continue
		for mid in _moves_of(prof):
			check(Moves.M.has(mid), "%s 동작 %s 이 moves.gd 에" % [pid, mid])
			check(mid.begins_with(OWNERS[pid]), "%s 는 제 동작(%s…)을 쓴다 — %s (뼈대 복사 아님)" % [pid, OWNERS[pid], mid])
		for table in prof["weights"]:
			check(not table.is_empty(), "%s 무게 표가 비지 않았다" % pid)
			for row in table:
				check(prof["patterns"].has(row[0]) and int(row[1]) > 0, "%s 무게 표 %s 가 패턴에" % [pid, row])
		for k in ["cd", "near", "far", "engage"]:
			check(prof.has(k), "%s 칸 %s" % [pid, k])
	# 총잡이는 총을 쏘고, 맨손 · 칼잡이는 총이 없다
	for pid in ["thug_revolver", "thug_uzi", "gunter"]:
		check(EnemyAI.PROFILES[pid].has("ranged"), "%s 는 총" % pid)
	for pid in ["thug", "thug_brute", "thug_pipe", "hyeokju", "seongjun", "daegeon", "manjae", "deoksu"]:
		check(not EnemyAI.PROFILES[pid].has("ranged"), "%s 는 총이 없다" % pid)
	# 패턴이 서로 다르다(같은 표를 복사해 두지 않았다)
	var seen := {}
	for pid in OWNERS:
		var key := JSON.stringify(EnemyAI.PROFILES[pid]["patterns"])
		check(not seen.has(key), "%s 패턴이 %s 와 같다" % [pid, seen.get(key, "")])
		seen[key] = pid


func test_p1_move_frames() -> void:
	var ids := _enemy_ids()
	check(ids.size() >= 30, "0 · 1장 적 동작 %d 개" % ids.size())
	for k in ids + ["kf_jab", "kf_jab2", "kf_upper", "kf_dash", "kf_counter", "kf_finisher", "j_jab", "j_jab2", "j_kick", "j_dash", "j_finisher"]:
		var mv := Moves.get_move(k)
		check(int(mv["startup"]) >= 1 and int(mv["active"]) >= 1 and int(mv["recovery"]) >= 0, "%s 프레임" % k)
		check(Moves.total(mv) <= 90, "%s 가 1.5초 안에 끝난다 (%d)" % [k, Moves.total(mv)])
		check(float(mv["damage"]) > 0.0 and float(mv["reach"]) > 0.0, "%s 피해 · 거리" % k)
		check(int(mv["hits"]) <= int(mv["active"]), "%s 여러 대는 판정 프레임 안에" % k)
		for fr in mv["feints"]:
			check(int(fr) > 0 and int(fr) < int(mv["startup"]), "%s 멈칫(%d)은 준비 안에" % [k, fr])
		check(str(mv["telegraph"]) in ["", "parry", "unblock"], "%s 예고 종류" % k)
		check(str(mv["shape"]) in ["slash", "slash_back", "thrust", "thrust_low", "sidekick", "axe", "punch", "shot", "spin"], "%s 자세 %s 는 있는 모양" % [k, mv["shape"]])
	for k in ids:
		var mv := Moves.get_move(k)
		check(str(mv["telegraph"]) != "", "적 동작 %s 는 예고가 있다(흰 ! · 빨간 !)" % k)
		check(int(mv["startup"]) >= 7, "적 동작 %s 준비 %d ≥ 7 (흰 ! 를 볼 틈)" % [k, mv["startup"]])


## 못 막는(쳐내기 · 막기가 안 되는) 동작은 빨간 ! 이고 READ_MIN 프레임 앞에 보인다 — 거꾸로 빨간 ! 는 못 막는다
func test_p1_unblockable_readable() -> void:
	for k in _enemy_ids():
		var mv := Moves.get_move(k)
		var unblock: bool = not mv["parryable"] or mv["guard_break"]
		check(unblock == (str(mv["telegraph"]) == "unblock"), "%s — 못 막으면 빨간 !, 빨간 ! 면 못 막는다" % k)
		if unblock:
			check(int(mv["startup"]) >= READ_MIN, "%s 빨간 ! 준비 %d ≥ %d" % [k, mv["startup"], READ_MIN])
		if mv["knockdown"]:
			check(int(mv["startup"]) >= READ_MIN, "%s 넘어뜨리는 동작은 읽을 틈 %d" % [k, mv["startup"]])


## 김혁주(p1:003/045-051): 잭나이프 첫 베기는 잽(빠르고 가볍다), 두 번째가 진짜 — 치켜든 채 반 박자 멈칫(feints) 뒤 무겁게
func test_hyeokju_jab_then_real() -> void:
	var prof: Dictionary = EnemyAI.PROFILES["hyeokju"]
	var two: Array = prof["patterns"]["two"]
	check(two.size() >= 2, "두 번 베기 패턴")
	var first := Moves.get_move(str(two[0][0]))
	var second := Moves.get_move(str(two[1][0]))
	check(float(first["damage"]) < float(second["damage"]) and int(first["startup"]) < int(second["startup"]),
		"첫 베기는 잽(가볍고 빠름) · 두 번째가 진짜 %s %s" % [first["name"], second["name"]])
	check(not second["feints"].is_empty() and first["feints"].is_empty(), "진짜 베기에 멈칫(속임) — 일찍 누르면 빗나간다")
	check(str(first["shape"]) != str(second["shape"]), "두 자루 — 다른 손 · 다른 쪽 베기")


## 2차(phase2_at)가 있는 보스는 2차 무게 표 · 2차 배율이 따로 — 김대건 '피떡이 돼야 시동'(015/042-048) · 윤덕수(020)
func test_p1_boss_phase2_tables() -> void:
	for pair in [["kimdaegeon", "daegeon"], ["yundeoksu", "deoksu"]]:
		var role: Dictionary = Hoeam.ROLES[pair[0]]
		var prof: Dictionary = EnemyAI.PROFILES[pair[1]]
		check(float(role.get("phase2_at", 0.0)) > 0.0, "%s 2차 있음" % pair[0])
		check(prof["weights"].size() == 2 and prof.has("phase2"), "%s 2차 표 · 배율" % pair[1])
		check(float(prof["phase2"].get("cd_k", 1.0)) < 1.0, "%s 2차는 더 몰아친다(쉬는 틈이 짧다)" % pair[1])
	# 김대건 2차에만: 프로 연타 · 날아 무릎(016/001-005)
	var dg: Dictionary = EnemyAI.PROFILES["daegeon"]
	check(not _phase_moves(dg, 1).has("dg_knee") and _phase_moves(dg, 2).has("dg_knee"), "날아 무릎은 2차부터")
	check(_phase_moves(dg, 2).count("dg_jab") >= 2, "2차 프로 연타(잽 여럿)")
	check(_phase_moves(dg, 1).has("dg_tackle") and _phase_moves(dg, 1).has("dg_spin") and _phase_moves(dg, 1).has("dg_highkick"),
		"1차: 베어허그 태클 · 뒷발 돌려차기 · 페인트 하이킥")
	# 윤덕수: 얼굴 잡아 메치기는 2차에 더 자주
	var yd: Dictionary = EnemyAI.PROFILES["deoksu"]
	check(_phase_moves(yd, 2).count("yd_grab") > _phase_moves(yd, 1).count("yd_grab"), "얼굴 잡아 메치기는 2차에 더 자주")


## 보스의 큰 동작 — 못 막는 태클 · 메치기는 막기도 뚫고 넘어뜨린다, 헛치면 크게 빈다
func test_p1_signature_moves() -> void:
	for k in ["dg_tackle", "yd_grab"]:
		var mv := Moves.get_move(k)
		check(not mv["parryable"] and mv["guard_break"] and mv["knockdown"] and int(mv["whiff"]) > 0, "%s 못 막고 넘어뜨림 · 헛치면 빈다" % k)
		check(mv["skill"], "%s 는 이름이 뜬다" % k)
	check(not Moves.get_move("dg_highkick")["feints"].is_empty(), "김대건 페인트 주먹 → 하이킥(015/012-016)")
	check(Moves.get_move("sj_kick")["knockdown"] and float(Moves.get_move("sj_kick")["knockback"]) > float(Moves.get_move("sj_coat")["knockback"]) * 3.0,
		"김성준 부츠 발차기 — 멀리 날려 넘어뜨린다(008/004-007 승합차)")
	check(not Moves.get_move("mj_body")["stun_3d"].is_empty(), "강만재 보디블로는 숨이 막힌다(기절, 005/019-020)")
	var dg: Dictionary = EnemyAI.PROFILES["daegeon"]
	check(dg.has("counter") and int(Moves.get_move(str(dg["counter"][0]))["startup"]) <= 8, "김대건 크로스 카운터는 빠르다")
	check(float(EnemyAI.PROFILES["manjae"].get("guard_add", 0.0)) > 0.0, "강만재 하이가드(006/009-011) — 더 자주 막는다")


## 김신 맨손(1부 처음): 잽 → 주먹 → 턱 쳐 올리기, 날아 차기 · 받아넘기며 치기 · 처박기. 0 · 1장 같은 동작 묶음
func test_kim_bare_moveset() -> void:
	check(Prologue.ROLES["kimshin"]["moveset"] == Hoeam.ROLES["kimshin"]["moveset"], "0 · 1장 김신 동작 묶음이 같다")
	var ms: Dictionary = Hoeam.ROLES["kimshin"]["moveset"]
	check(str(Moves.get_move(ms["combo"])["next"]) == "kf_jab2" and str(Moves.get_move("kf_jab2")["next"]) == "kf_upper", "연타 차례")
	check(str(ms["finisher"]).ends_with("finisher") and str(ms["counter"]) == "kf_counter", "제압 · 반격 이름(world 가 이름 끝으로 제압을 안다)")
	check(int(Moves.get_move("kf_counter")["startup"]) <= 3, "받아넘기며 치기는 곧바로")
	for k in ["kf_jab", "kf_jab2", "kf_upper", "kf_dash", "kf_counter", "kf_finisher"]:
		check(str(Moves.get_move(k)["telegraph"]) == "", "김신 동작 %s 에 예고 없음" % k)
	# 서진태(아군): 빠른 주먹 둘 → 하이킥(006/008-009)
	check(str(Moves.get_move("j_jab")["next"]) == "j_jab2" and str(Moves.get_move("j_jab2")["next"]) == "j_kick", "서진태 연타 → 하이킥")
	check(int(Moves.get_move("j_jab")["startup"]) <= int(Moves.get_move("kf_jab")["startup"]), "서진태 주먹은 김신만큼 빠르다(속도 92)")


## 1부 처음 김신(내성 중위)은 한참 아랫급의 보통 공격에 움찔하지 않는다(common shrugs_off) — 그래서 보스의 큰 동작은
## 넘어뜨리거나(knockdown) 숨을 막아(기절) 멈춰 세운다
func test_p1_big_moves_stop_kim() -> void:
	for case in [["m_punch", "건달급", "idle"], ["dg_tackle", "경호대급", "down"], ["yd_grab", "전국구", "down"], ["sj_kick", "네임드", "down"],
			["mj_body", "네임드", "stun"]]:
		var d := _close(0.75)
		var h = d["hero"]
		var b = d["boss"]
		h.rank = "내성 중위"
		b.rank = str(case[1])
		b.start_move(str(case[0]))
		var hit := false
		for i in 60:
			_tick(d)
			hit = hit or not _events(d, "hit").is_empty()
			d["world"].events.clear()
			if hit:
				break
		_run(d, 1)
		var want: String = case[2]
		var ok: bool = (h.state in ["idle", "move"]) if want == "idle" else h.state == want
		check(hit and ok, "%s(%s) 맞은 김신 %s — 기대 %s" % [case[0], case[1], h.state, want])
