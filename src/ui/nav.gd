extends RefCounted
## 화면 흐름의 작은 규칙 — Android 뒤로 버튼 · 앱이 내려갈 때(홈 · 전화 · 화면 끔). main.gd 가 부르고, 시험은
## tests/unit/test_ui_logic.gd. 개발 규격 게임개발규격 5절(뒤로 버튼 · 수명주기).


## 뒤로 버튼: 결투 중이면 멈추고, 멈춘 화면 · 데모 · 결과에서는 처음 화면, 처음 화면에서는 끝낸다
## 돌려주는 값: "pause" · "title" · "quit"
static func on_back(mode: String, paused: bool) -> String:
	if mode == "fight" and not paused:
		return "pause"
	if mode == "title":
		return "quit"
	return "title"


## 앱이 내려갈 때 멈출지 — 사람이 싸우는 중일 때만(데모 · 처음 화면은 소리만 끈다)
static func pause_on_hide(mode: String, paused: bool) -> bool:
	return mode == "fight" and not paused
