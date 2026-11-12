extends RefCounted
## 실행 인자 · 키 — main.gd 에서 뗐다(2026-11-09 큰 파일 나누기). parse 는 순수 함수(시험 tests/unit/test_ui_logic.gd):
## 글 목록 → 인자 사전(기본값은 defaults). --safe 는 "safe" 칸(Vector4)으로 돌려주고 main.gd 가 SafeArea 에 넣는다.
## 인자 뜻은 src/main.gd 머리 주석.

## 개발 편의 키(Android 전용 판 — 키보드는 개발용, CLAUDE.md 0절)
const KEYS := {
	"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN],
	"attack": [KEY_J, KEY_Z], "parry": [KEY_K, KEY_X], "roll": [KEY_SPACE, KEY_C], "dash": [KEY_L, KEY_SHIFT],
	"skill": [KEY_U, KEY_V], "skill_next": [KEY_I, KEY_B], "pause": [KEY_ESCAPE, KEY_P], "swap": [KEY_TAB, KEY_Q],
	"pick_1": [KEY_1], "pick_2": [KEY_2], "art": [KEY_3], "bench": [KEY_4], "difficulty": [KEY_5], "accept": [KEY_ENTER, KEY_KP_ENTER],
	"speed": [KEY_F], "menu": [KEY_M], "jump": [KEY_E, KEY_R], "crouch": [KEY_G, KEY_CTRL],
}


static func defaults() -> Dictionary:
	return {"autoplay": false, "seconds": 0.0, "seed": 1, "shots": [], "shot_dir": "", "touch": false, "trace": false,
		"events": {}, "mode": "ch6", "room": 0, "crowd": 0, "art": "", "replay": "", "save_replay": "", "save": ""}


static func parse(a: PackedStringArray) -> Dictionary:
	var args := defaults()
	var i := 0
	while i < a.size():
		match a[i]:
			"--autoplay":
				args["autoplay"] = true
			"--touch":
				args["touch"] = true
			"--trace":
				args["trace"] = true
			"--mode":
				i += 1
				args["mode"] = a[i]
			"--room":
				i += 1
				args["room"] = int(a[i])
			"--crowd":
				i += 1
				args["crowd"] = int(a[i])
			"--art":
				i += 1
				args["art"] = a[i]
			"--safe":
				i += 1
				var v := a[i].split(",")
				args["safe"] = Vector4(float(v[0]), float(v[1]), float(v[2]), float(v[3]))
			"--events":
				i += 1
				for ev in a[i].split(","):
					var kv := ev.split(":")
					args["events"][int(kv[0])] = kv[1]
			"--replay":
				i += 1
				args["replay"] = a[i]
			"--save-replay":
				i += 1
				args["save_replay"] = a[i]
			"--save":
				i += 1
				args["save"] = a[i]
			"--seconds":
				i += 1
				args["seconds"] = float(a[i])
			"--seed":
				i += 1
				args["seed"] = int(a[i])
			"--shots":
				i += 1
				var spec: String = a[i]
				var cut := spec.rfind(":")
				args["shot_dir"] = spec.substr(0, cut)
				for s in spec.substr(cut + 1).split(","):
					args["shots"].append(int(s))
		i += 1
	return args


static func setup_input() -> void:
	for act in KEYS:
		if not InputMap.has_action(act):
			InputMap.add_action(act)
		for k in KEYS[act]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(act, ev)
