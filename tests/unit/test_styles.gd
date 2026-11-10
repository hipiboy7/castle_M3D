extends "res://tests/helpers.gd"
## 인물별 기본기(A 등급 — src/data/moves.gd M 의 base 칸 · src/combat/enemy_ai.gd STYLE): 2026-11-10 폰 리뷰 "캐릭들 공격 모션이 다
## 비슷하던데". 같은 묶음(ny_ · w_ · x_ …)을 나눠 쓰던 인물마다 다른 모양의 연타를 주되 손맛 · 균형은 바탕 동작 그대로인지 —
## 프레임 · 피해 · 체간 · 예고 · 거리가 바탕의 ±10% 안 · 판정 모양(둘레 spin · 선 shot)이 같다 · 연타 차례가 제 묶음 안에서 돈다 ·
## 이름 있는 인물끼리 연타(자세 모양 차례)가 겹치지 않는다.

const EnemyAI = preload("res://src/combat/enemy_ai.gd")
const Campaign = preload("res://src/data/campaign.gd")
const Addendum = preload("res://src/data/addendum.gd")
const Stage = preload("res://src/combat/stage.gd")
const P = preload("res://src/view/poses.gd")

const SAME := ["startup", "active", "recovery", "reach", "radius", "knockback", "hitstop", "whiff", "lunge", "arc"]
const FLAGS := ["telegraph", "parryable", "guard_break", "knockdown", "iframes", "lethal", "skill_id", "fx"]
const HIT_SHAPES := ["spin", "shot", "draw_shot", "toss"]      # 판정이 달라지는 모양(world.gd) — 다른 모양과 바꿔 끼우지 않는다


static func _near(a: float, b: float) -> bool:
	return absf(a - b) <= absf(b) * 0.1 + 0.0001


static func _variants() -> Array:
	return Moves.M.keys().filter(func(k): return Moves.M[k].has("base"))


func test_variants_keep_base_values() -> void:
	var vs := _variants()
	check(vs.size() >= 150, "인물별 변형 %d 개" % vs.size())
	for k in vs:
		var base := str(Moves.M[k]["base"])
		check(Moves.has(base) and not Moves.M.get(base, {}).has("base"), "%s 바탕 %s 이 원래 동작" % [k, base])
		var v := Moves.get_move(k)
		var b := Moves.get_move(base)
		for f in SAME:
			check(_near(float(v[f]), float(b[f])), "%s %s %s ≈ 바탕 %s" % [k, f, v[f], b[f]])
		for f in ["damage", "posture"]:
			check(_near(float(v[f]) * int(v["hits"]), float(b[f]) * int(b["hits"])), "%s %s × 대 수 ≈ 바탕" % [k, f])
		for f in FLAGS:
			check(v[f] == b[f], "%s %s 가 바탕과 같다" % [k, f])
		check((str(v["shape"]) in HIT_SHAPES) == (str(b["shape"]) in HIT_SHAPES), "%s 판정 모양(둘레 · 선) 그대로" % k)
		check(preload("res://tests/unit/test_p1_moves.gd").shape_ok(str(v["shape"])), "%s 자세 %s" % [k, v["shape"]])
		var seq: Array = v["seq"]
		check(seq.is_empty() or seq.size() == int(v["hits"]), "%s seq = hits" % k)
		for sh in seq:
			check(preload("res://tests/unit/test_p1_moves.gd").shape_ok(str(sh)), "%s 대마다 모양 %s" % [k, sh])
		if str(b["next"]) != "":
			check(Moves.M[k].has("next"), "%s 연타 차례를 제 묶음으로(바탕 %s 로 새지 않게)" % [k, b["next"]])
		var nx := str(v["next"])
		check(nx == "" or (Moves.M.has(nx) and Moves.M[nx].has("base")), "%s 다음 %s 도 변형" % [k, nx])
		check(str(v["label"]) != "", "%s 이름" % k)


func test_style_maps() -> void:
	for cid in EnemyAI.STYLE:
		check(Addendum.character(cid).has("name"), "STYLE %s 인물" % cid)
		var m: Dictionary = EnemyAI.STYLE[cid]
		for b in m:
			var vid := str(m[b])
			check(Moves.M.has(vid) and str(Moves.M[vid].get("base", "")) == b, "%s %s → %s (바탕이 원형 동작)" % [cid, b, vid])
	var f = Fighter.new("모승규", 1)
	f.char_id = "moseunggyu"
	var ai = EnemyAI.new(f, "x_brawler", RandomNumberGenerator.new())
	check(ai._mv("x_jab") == "mo_jab" and ai._mv("x_straight") == "x_straight", "모승규 잽 → 손등 치기, 바꾸지 않은 동작은 그대로")
	var g = Fighter.new("엑스트라", 1)
	g.char_id = "street_thug"
	check(EnemyAI.new(g, "x_brawler", RandomNumberGenerator.new())._mv("x_jab") == "x_jab", "엑스트라는 원형 그대로")


## 자세 모양 이름(왼손 판은 _L) — 인형이 고르는 모양(puppet_pose shape_key)과 같은 뜻
static func _sig(mv_id: String) -> String:
	var mv := Moves.get_move(mv_id)
	var sh := str(mv["shape"])
	if (P.MIRROR.has(sh) or sh == "slash_back") and str(mv["hand"]) == "L":
		sh += "_L"
	return sh


## 연타(첫 동작에서 next 를 따라) · 대시의 모양 차례
static func _combo_sig(ms: Dictionary) -> String:
	var out: Array = []
	var m := str(ms.get("combo", ""))
	while m != "" and out.size() < 6:
		out.append(_sig(m))
		m = str(Moves.get_move(m)["next"])
	return " → ".join(out) + " / " + _sig(str(ms.get("dash", ms.get("combo", ""))))


func test_named_people_have_own_basics() -> void:
	var hero_sig := {}           # 모양 차례 → 인물
	var foe_sig := {}
	for id in Campaign.playable_ids():
		if Campaign.kind(id) != "stage":
			continue
		var T = Campaign.table(id)
		for rid in T.ROLES:
			var role: Dictionary = T.ROLES[rid]
			var c := Addendum.character(str(rid))
			if c.is_empty() or Stage._extra(c) or not c.has("name"):
				continue                                   # 엑스트라 · 역할 줄(kimshin_bare · majunyeong2 …)은 같은 원형을 나눠 써도 된다
			if role.has("moveset"):
				var s := _combo_sig(role["moveset"])
				check(str(hero_sig.get(s, rid)) == str(rid), "%s 연타 %s 가 %s 와 같다" % [rid, s, hero_sig.get(s)])
				hero_sig[s] = rid
			var ai := str(role.get("ai", ""))
			if ai.begins_with("x_"):
				var st: Dictionary = EnemyAI.STYLE.get(str(rid), {})
				var shapes: Array = EnemyAI.moves_of(ai).map(func(mv): return _sig(str(st.get(mv, mv))))
				var s2 := ai + ":" + ",".join(shapes)
				check(str(foe_sig.get(s2, rid)) == str(rid), "적 %s 기본기 %s 가 %s 와 같다" % [rid, s2, foe_sig.get(s2)])
				foe_sig[s2] = rid
	check(hero_sig.size() >= 25 and foe_sig.size() >= 35, "인물마다 다른 연타 — 사람 %d · 적 %d" % [hero_sig.size(), foe_sig.size()])
