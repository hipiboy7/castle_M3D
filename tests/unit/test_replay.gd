extends "res://tests/helpers.gd"
## 입력 리플레이 · 상태 해시(A 등급 — src/combat/replay.gd). 멀티 ④(호스트 권위 · 어긋남 찾기)의 바탕:
## 같은 시드 + 같은 입력 기록이면 같은 해시, 입력 한 프레임이 다르면 다른 해시. 기록은 JSON 으로 오가도 같다.

const Replay = preload("res://src/combat/replay.gd")
const Stage = preload("res://src/combat/stage.gd")
const Bot = preload("res://src/combat/bot.gd")


func test_quantize_and_encode_roundtrip() -> void:
	var it := {"move": Vector2(0.7071, -0.7071), "face": Vector2(1, 0), "attack": true, "parry_held": true, "swap": true}
	var q := Replay.quantize(it)
	check(Replay.quantize(q) == q, "양자화는 두 번 해도 같다 %s" % q)
	check(Replay.decode(Replay.encode(q)) == q, "encode → decode 가 같은 입력 %s" % q)
	check(absf(q["move"].x - 0.7071) < 0.01 and q["attack"] and not q["roll"], "값이 거의 그대로 %s" % q)
	check(Replay.encode(Replay.quantize({})) == [0, 0, 0, 0, 0, -1], "빈 입력은 0 다섯 개 + 고르기 없음 -1")
	check(Replay.decode(Replay.encode(Replay.quantize({"skill_pick": 2})))["skill_pick"] == 2, "기술 번호 고르기(봇)도 입력")
	check(Replay.quantize({"move": Vector2(3, 0)})["move"].x <= 1.0, "막대 길이는 1 까지")


func test_hash_same_seed_same_state() -> void:
	check(Replay.state_hash(Duel.make(5)) == Replay.state_hash(Duel.make(5)), "같은 시드로 만든 판은 같은 해시")
	var a := Duel.make(5)
	var b := Duel.make(5)
	Duel.step(a, Replay.quantize({"move": Vector2(1, 0)}))
	Duel.step(b, Replay.quantize({"move": Vector2(-1, 0)}))
	check(Replay.state_hash(a) != Replay.state_hash(b), "다른 입력 한 프레임이면 다른 해시")
	check(Replay.state_hash(Stage.make(2)) != Replay.state_hash(Duel.make(2)), "11장 · 6장은 다른 해시")


## 봇이 고른 입력을 사람 입력처럼(양자화해서) 넣으며 기록 → 다시 돌리면 같은 해시 · 같은 중간 점검.
## 입력을 만드는 봇은 판 밖의 것(판 안 봇의 난수를 건드리면 재생 때와 달라진다 — 사람 손과 같은 자리)
func _record(kind: String, seed_value: int, frames: int, poke := -1) -> Dictionary:
	var d: Dictionary = Stage.make(seed_value) if kind == "stage" else Duel.make(seed_value)
	var rec := Replay.start(kind, seed_value)
	var drivers := {}
	for n in frames:
		var h = d["hero"]
		if not drivers.has(h):
			var r := RandomNumberGenerator.new()
			r.seed = seed_value * 31 + drivers.size()
			drivers[h] = Bot.new(h, d["boss"] if kind == "duel" else null, r)
		var bot = drivers[h]
		if kind == "stage":
			Stage._targets(d)
			bot.foe = h.target()
			bot.foes = Stage._foes_of(d, h)
		var it := {} if d["world"].hitstop > 0 or h.target() == null else Replay.quantize(bot.decide())
		it = Replay.quantize(it)
		if poke >= 0 and n >= poke and n < poke + 30:
			it = Replay.quantize({"move": Vector2(0, 1)})        # 30프레임 동안 손이 딴 데로(한 프레임은 역경직에 묻힐 수 있다)
		if kind == "stage" and n == 300:
			it["swap"] = true
		Replay.add(rec, d, it)
		if kind == "stage":
			Stage.step(d, it)
		else:
			Duel.step(d, it)
		d["world"].events.clear()
	Replay.finish(rec, d)
	return rec


func test_duel_replay_same_hash() -> void:
	var rec := _record("duel", 3, 900)
	var out := Replay.play(rec)
	check(out["ok"], "6장 리플레이가 같은 해시 %s" % out)
	check(rec["checks"].size() == 15 and out["checks"] == rec["checks"], "60프레임마다 중간 해시가 같다")
	var other := _record("duel", 3, 900, 120)
	check(other["hash"] != rec["hash"], "120프레임부터 입력을 바꾸면 끝 해시가 다르다")
	check(Replay.first_mismatch(rec["checks"], other["checks"]) == 2, "어긋난 첫 점검은 120프레임 쪽(2번)")


func test_stage_replay_same_hash_with_swap() -> void:
	var rec := _record("stage", 1, 900)
	var out := Replay.play(rec)
	check(out["ok"], "11장 리플레이(교대 포함)가 같은 해시 %s" % out)


func test_replay_through_json() -> void:
	var rec := _record("duel", 4, 400)
	rec["inputs"][10] = null                     # null 프레임 = 그 프레임은 봇(데모)
	rec = _rehash(rec)
	var back = JSON.parse_string(JSON.stringify(rec))
	var out := Replay.play(back)
	check(out["ok"], "JSON 으로 오간 기록도 같은 해시 %s" % out)


func test_replay_format_version() -> void:
	var rec := _record("duel", 1, 10)
	rec["v"] = 99
	var out := Replay.play(rec)
	check(not out["ok"] and str(out["error"]).contains("v"), "형식 버전이 다르면 돌리지 않는다 %s" % out)
	check(Replay.first_mismatch([1, 2], [1, 2]) == -1, "다 같으면 -1")


## null 을 넣은 기록의 해시를 다시 잡는다(기록 → 재생 결과를 정답으로)
func _rehash(rec: Dictionary) -> Dictionary:
	var out := Replay.play(rec)
	rec["hash"] = out["hash"]
	rec["checks"] = out["checks"]
	return rec
