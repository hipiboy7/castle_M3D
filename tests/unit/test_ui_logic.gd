extends "res://tests/helpers.gd"
## 화면 쪽 순수 함수 — 안전 영역 여백 환산(src/ui/safe_area.gd) · 뒤로 버튼 · 앱 내려감 처리(src/ui/nav.gd) · 처음 화면 카드 자리(title_menu.gd).

const SafeArea = preload("res://src/ui/safe_area.gd")
const Nav = preload("res://src/ui/nav.gd")
const TitleMenu = preload("res://src/ui/title_menu.gd")
const StageMenu = preload("res://src/ui/stage_menu.gd")


func test_safe_insets_scale_to_view() -> void:
	# 폴드 4 커버 화면 2316x904 가로 · 왼쪽 펀치홀 80px · 아래 제스처 바 40px, 기준 화면 1280 폭(expand → 1280x500)
	var ins := SafeArea.insets_from(Vector2(1280, 500), Vector2i(2316, 904), Vector2i.ZERO, Rect2i(80, 0, 2236, 864))
	var k := 1280.0 / 2316.0
	check(ins.is_equal_approx(Vector4(80 * k, 0, 0, 40 * k)), "여백을 기준 화면 단위로 (%s)" % ins)
	check(SafeArea.insets_from(Vector2(1280, 720), Vector2i(1280, 720), Vector2i.ZERO, Rect2i(0, 0, 1280, 720)) == Vector4.ZERO,
		"전체가 안전하면 0")
	check(SafeArea.insets_from(Vector2(1280, 720), Vector2i.ZERO, Vector2i.ZERO, Rect2i()) == Vector4.ZERO, "값이 없으면 0")


func test_back_button_flow() -> void:
	check(Nav.on_back("fight", false) == "pause", "결투 중 뒤로 = 일시정지")
	check(Nav.on_back("fight", true) == "title", "일시정지에서 뒤로 = 처음 화면")
	check(Nav.on_back("demo", false) == "title", "데모에서 뒤로 = 처음 화면")
	check(Nav.on_back("result", false) == "title", "결과에서 뒤로 = 처음 화면")
	check(Nav.on_back("title", false) == "quit", "처음 화면에서 뒤로 = 끝내기")
	check(Nav.on_back("fight", true, true) == "close_menu", "메뉴가 열려 있으면 뒤로 = 메뉴 닫고 계속")


func test_app_hidden_pauses_only_fight() -> void:
	check(Nav.pause_on_hide("fight", false), "결투 중 앱이 내려가면 일시정지")
	check(not Nav.pause_on_hide("fight", true), "이미 멈췄으면 그대로")
	check(not Nav.pause_on_hide("demo", false) and not Nav.pause_on_hide("title", false), "데모 · 처음 화면은 멈추지 않는다(소리만 끈다)")


## 처음 화면 카드: 기준 화면 · 폴드 4 커버(가로로 긴 화면 · 펀치홀 여백) · 펼친 화면(6:5)에서 안 겹치고 안전 영역 안
func test_title_menu_layout() -> void:
	for sa in [Rect2(0, 0, 1280, 720), Rect2(44, 0, 1800, 700), Rect2(0, 0, 1280, 1067)]:
		var L := TitleMenu.layout(sa, 4)
		var cards: Array = L["cards"]
		check(cards.size() == 4, "카드 넷")
		check(sa.encloses(L["cont"]), "이어하기가 안전 영역 안 %s" % sa)
		for i in cards.size():
			check(sa.encloses(cards[i]), "카드 %d 가 안전 영역 안 %s %s" % [i, sa, cards[i]])
			check(not cards[i].intersects(L["cont"]), "카드 %d 와 이어하기가 안 겹친다" % i)
			if i > 0:
				check(cards[i].position.x >= cards[i - 1].end.x, "카드 %d 가 앞 카드와 안 겹친다" % i)
	check(TitleMenu.layout(Rect2(0, 0, 1280, 720), 0)["cards"].is_empty(), "카드가 없으면 빈 줄")
	# 장 15개(3 ~ 13장 — 2026-11-08): 여러 줄 · 안전 영역 안 · 서로 · 이어하기와 안 겹침
	for sa in [Rect2(0, 0, 1280, 720), Rect2(44, 0, 1800, 700), Rect2(0, 0, 1280, 1067)]:
		var L := TitleMenu.layout(sa, 15)
		var cards: Array = L["cards"]
		check(cards.size() == 15 and cards[14].position.y > cards[0].position.y, "열다섯 장은 여러 줄")
		check(sa.encloses(L["cont"]), "이어하기가 안전 영역 안(여러 줄) %s" % sa)
		for i in cards.size():
			check(sa.encloses(cards[i]) and not cards[i].intersects(L["cont"]), "카드 %d 안전 영역 안 · 이어하기와 안 겹침 %s" % [i, sa])
			for j in i:
				check(not cards[i].intersects(cards[j]), "카드 %d · %d 안 겹침" % [i, j])
		# 안내 글(hud hint 30px 높이 · 1000 폭) — 이어하기 · 카드와 안 겹치고 안전 영역 안, 제목(가운데 - 150 ~ - 80) 아래(2026-11-09)
		var hy := TitleMenu.hint_y_of(sa, 15)
		var hr := Rect2(sa.get_center().x - 500.0, hy, 1000.0, 30.0)
		check(hy >= sa.position.y and not hr.intersects(L["cont"]) and cards.all(func(c): return not hr.intersects(c)),
			"안내 글이 이어하기 · 카드와 안 겹친다 %s" % sa)
		check(hy >= sa.get_center().y - 80.0, "안내 글이 제목 아래 %s %.0f" % [sa, hy])


## 싸움 중 메뉴(스테이지 고르기): 장 줄 · 스테이지 줄 · 계속 · 처음 화면 — 커버 · 펼친 화면에서 안전 영역 안 · 안 겹침
func test_stage_menu_layout() -> void:
	for sa in [Rect2(0, 0, 1280, 720), Rect2(44, 0, 1800, 700), Rect2(0, 0, 1280, 1067)]:
		for nn in [[4, 5], [15, 8]]:                  # 장 15개(3 ~ 13장)면 장 줄이 두 줄 · 방 8개(2장)
			var L := StageMenu.layout(sa, nn[0], nn[1])
			var all: Array = L["chapters"] + L["stages"] + [L["resume"], L["title"], L["difficulty"]]
			check(L["chapters"].size() == nn[0] and L["stages"].size() == nn[1], "장 %d · 스테이지 %d" % nn)
			for i in all.size():
				check(sa.encloses(all[i]), "자리 %d 가 안전 영역 안 %s %s" % [i, sa, all[i]])
				for k in range(i + 1, all.size()):
					check(not all[i].intersects(all[k]), "자리 %d · %d 가 안 겹친다 %s" % [i, k, sa])



## 실행 인자(src/launch.gd — main.gd 에서 뗌 2026-11-09): 기본값 · 각 인자 · --events · --shots · --safe
func test_launch_args() -> void:
	const Launch = preload("res://src/launch.gd")
	check(Launch.parse(PackedStringArray([])) == Launch.defaults(), "인자 없으면 기본값")
	var a := Launch.parse(PackedStringArray(["--autoplay", "--mode", "ch4", "--room", "3", "--seed", "7", "--seconds", "2.5",
		"--events", "30:press,120:menupick_difficulty", "--shots", "/tmp/x:60,120", "--safe", "90,0,0,40", "--art", "b"]))
	check(a["autoplay"] and a["mode"] == "ch4" and a["room"] == 3 and a["seed"] == 7 and a["seconds"] == 2.5 and a["art"] == "b", "값 인자")
	check(a["events"] == {30: "press", 120: "menupick_difficulty"}, "--events 프레임:일")
	check(a["shot_dir"] == "/tmp/x" and a["shots"] == [60, 120], "--shots 폴더:프레임들")
	check(a["safe"] == Vector4(90, 0, 0, 40), "--safe 는 safe 칸으로")
	check(Launch.KEYS.has("difficulty") and Launch.KEYS.has("menu"), "키 표")
