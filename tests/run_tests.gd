extends SceneTree
## 테스트 실행기 (창 없음): <godot> --headless --path . -s res://tests/run_tests.gd
## 각 묶음(tests/test_*.gd)의 test_ 로 시작하는 함수를 부르고, 하나라도 실패하면 종료 코드 1.

const SUITES := ["res://tests/test_combat.gd"]


func _initialize() -> void:
	var passed := 0
	var failed := 0
	for path in SUITES:
		var suite = load(path).new()
		for m in suite.get_method_list():
			var n: String = m["name"]
			if not n.begins_with("test_"):
				continue
			suite.failures = []
			suite.call(n)
			if suite.failures.is_empty():
				passed += 1
			else:
				failed += 1
				for f in suite.failures:
					print("FAIL %s %s: %s" % [path.get_file(), n, f])
		suite = null
	print("tests: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
