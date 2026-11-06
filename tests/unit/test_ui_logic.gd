extends "res://tests/helpers.gd"
## 화면 쪽 순수 함수 — 안전 영역 여백 환산(src/ui/safe_area.gd) · 뒤로 버튼 · 앱 내려감 처리(src/ui/nav.gd).

const SafeArea = preload("res://src/ui/safe_area.gd")
const Nav = preload("res://src/ui/nav.gd")


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


func test_app_hidden_pauses_only_fight() -> void:
	check(Nav.pause_on_hide("fight", false), "결투 중 앱이 내려가면 일시정지")
	check(not Nav.pause_on_hide("fight", true), "이미 멈췄으면 그대로")
	check(not Nav.pause_on_hide("demo", false) and not Nav.pause_on_hide("title", false), "데모 · 처음 화면은 멈추지 않는다(소리만 끈다)")
