extends "res://tests/helpers.gd"
## 3 ~ 13장 1층 대체(A 등급 — src/data/addendum.gd character · canon_fallback): castle_common 인물 표에 없는 이름 있는 적(바실리 ·
## 구스타프 …)은 이름을 looks.json, 등급을 ranks.json 강함표(조건 없는 줄이 먼저)에서, 기술 능력치는 등급으로 채운다.
## 공통 표에 이름만 있고 등급이 빈 인물(표영 · 리천 · 마학영)도 강함표 등급으로 채운다.

const Addendum = preload("res://src/data/addendum.gd")


func test_fallback_name_rank_from_common_layer2() -> void:
	var v := Addendum.character("vasily")
	check(str(v["name"]) == "바실리" and str(v["rank"]) == "전국구", "바실리 — looks.json 이름 · 강함표 전국구 (%s %s)" % [v.get("name"), v.get("rank")])
	var g := Addendum.character("gustav")
	check(str(g["rank"]) == "내성 상위", "구스타프 — 내성 상위 (%s)" % g.get("rank"))
	check(int(g["stats"]["기술"]) == 40 + 3 * Common.ranks().find("내성 상위"), "기술 능력치는 등급으로 (%s)" % g["stats"])
	check(Addendum.character("nobody_xyz").is_empty(), "모르는 id 는 빈 표")


func test_fallback_prefers_unconditional_line() -> void:
	# 류지학: (마준영+경호대 전투 이후) 내성 상위 · (교류회 이후) 내성 중위 · (1부) 내성 하위 — 조건 없는 줄이 없으면 첫 줄
	check(str(Addendum.canon_fallback("ryujihak")["rank"]) == "내성 상위", "조건 줄만 있으면 첫 줄")
	# 마학영: 조건 없는 톱
	check(str(Addendum.character("mahakyoung")["rank"]) == "톱", "공통 표에 등급이 비어 있으면 강함표 (%s)" % Addendum.character("mahakyoung").get("rank"))
	check(Addendum.character("pyoyoung")["stats"] is Dictionary, "공통 표의 빈 능력치는 빈 표로")


func test_common_values_win() -> void:
	var k := Addendum.character("kimshin")
	check(str(k["rank"]) == str(Common.character("kimshin")["rank"]), "공통 표에 등급이 있으면 그대로")
	check(str(Addendum.character("iseul")["rank"]) == "전국구", "이슬 — 공통 전국구")
