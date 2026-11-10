extends "res://tests/helpers.gd"
## 인물 기술 묶음(A 등급 — src/data/skill_kit.gd): 사용자 2026-11-10 "castle_common 에 있는 캐릭터별 기술을 캐릭터에 적용 —
## 재앙 모든 기술 · 톱 7 · 내성 5 · 외성 4 · 외성 미만 3"

const Kit = preload("res://src/data/skill_kit.gd")


func test_count_by_rank() -> void:
	check(Kit.count_for("재앙") == Kit.ALL, "재앙 = 모든 기술")
	check(Kit.count_for("톱") == 7, "톱 7")
	for r in ["내성 상위", "내성 중위", "내성 하위"]:
		check(Kit.count_for(r) == 5, "%s 5" % r)
	for r in ["외성 상위", "외성 중위", "외성 하위"]:
		check(Kit.count_for(r) == 4, "%s 4" % r)
	for r in ["준10강", "이스크라 평 킬러급", "전국구", "경호대급", "네임드", "조장급", "건달급", ""]:
		check(Kit.count_for(r) == 3, "%s 3(외성 미만)" % r)


func test_kit_size_and_moves() -> void:
	# 원작 기술이 많은 인물: 등급 수만큼, 동작은 모두 동작 표에 있다
	var g := Kit.npc_kit("gustav", "내성 상위", "x_master", [])
	check(g.size() == 5, "구스타프(내성 상위) 5개 — %d" % g.size())
	var r := Kit.npc_kit("richeon", "톱", "x_master", [])
	check(r.size() == 7, "리천(톱) 7개 — 원작 기술이 모자라면 원형 동작으로 채운다 %s" % [r.map(func(e): return e["name"])])
	var w := Kit.npc_kit("douchen", "외성 하위", "x_kicker", [])
	check(w.size() == 4, "도우첸(외성 하위) 4개 — %d" % w.size())
	var low := Kit.npc_kit("scaledanjang", "준10강", "x_brawler", [])
	check(low.size() == 3, "스케일단장(준10강) 3개 — %d" % low.size())
	for e in g + r + w + low:
		check(Moves.M.has(str(e["move"])) and str(e["name"]) != "", "동작 표에 있는 동작 · 이름 %s" % e)
	var names := {}
	for e in r:
		names[e["name"]] = true
	check(names.size() == r.size(), "한 사람 안에서 이름이 겹치지 않는다 %s" % [r.map(func(e): return e["name"])])
	# 원작 기술이 없는 사람도 등급 수만큼(원형 동작 이름)
	var none := Kit.npc_kit("dohaksu", "전국구", "x_brawler", [])
	check(none.size() == 3, "원작 기술이 없으면 원형 동작으로 3개 %s" % [none])


func test_known_first_and_no_progression_skip() -> void:
	# 1층 기술(동작 있음)이 먼저, 공통 기술(skills.json)은 원작 표에서 다시 넣지 않는다 — 진행(얻는 차례)을 건너뛰지 않게
	var known := [{"id": "kickarts", "name": "각법", "move": "s_kick", "cost": 1.0}]
	var k := Kit.hero_kit("kimshin", "내성 중위", known)
	check(k.size() == 5 and k[0]["id"] == "kickarts", "김신(내성 중위) 5개 · 아는 기술이 먼저 %s" % [k.map(func(e): return e["id"])])
	for e in k:
		check(not (str(e["id"]) in ["offbeat", "offbeat2", "offbeat_rev", "triple"]), "아직 안 얻은 공통 기술은 원작 표로 넣지 않는다 %s" % e["id"])
		check(e.has("cost") and float(e["cost"]) > 0.0, "조작 인물 기술은 게이지 칸이 있다 %s" % e)
	var top := Kit.hero_kit("kimshin", "재앙", known)
	check(top.size() > 7, "재앙이면 모든 기술(%d)" % top.size())
	var cap := Kit.hero_kit("kimshin", "외성 하위", known + [{"id": "a", "name": "가", "move": "x_jab", "cost": 1.0},
		{"id": "b", "name": "나", "move": "x_jab", "cost": 1.0}, {"id": "c", "name": "다", "move": "x_jab", "cost": 1.0},
		{"id": "d", "name": "라", "move": "x_jab", "cost": 1.0}])
	check(cap.size() == 4 and cap[0]["id"] == "kickarts", "아는 기술이 많아도 등급 수까지(외성 4)")


func test_npc_moves_stay_in_profile() -> void:
	# 적의 기술 동작은 그 적이 원래 쓰는 동작 안에서 — 이름만 원작 기술(손맛은 원래 패턴과 같게)
	var allowed: Array = preload("res://src/combat/enemy_ai.gd").moves_of("x_master")
	check(allowed.has("x_grab") and allowed.has("x_straight") and not allowed.has("t_shot"), "x_master 동작 %s" % [allowed])
	var g := Kit.npc_kit("gustav", "내성 상위", "x_master", [], allowed)
	check(g.size() == 5, "구스타프 5개")
	for e in g:
		check(allowed.has(str(e["move"])), "구스타프 기술 동작이 원형 안에 %s" % e)
