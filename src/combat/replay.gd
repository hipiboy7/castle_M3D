extends RefCounted
## 입력 리플레이 · 상태 해시 — 멀티 ④(호스트 권위 · 어긋남 찾기)와 버그 재현의 바탕. 순수 로직(노드 없음).
## 판(duel.gd · stage.gd)은 60프레임 고정 · 시드 하나라, 같은 시드 + 같은 입력 열이면 같은 판이 된다. 그래서 기록은
## {v, kind, seed, opts, inputs, checks, hash} 뿐이다:
##   inputs — step 한 번마다 사람 입력 하나(encode — 정수 6개) 또는 null(그 프레임은 봇 — 데모)
##   checks — CHECK_EVERY 프레임마다 state_hash(어긋난 첫 자리를 찾는다 — first_mismatch) · hash — 끝 상태
## 사람 입력은 먼저 quantize 한다(막대 각도를 1/127 칸으로) — 게임(main.gd)도 양자화한 입력으로 판을 돌려서 실제 판 == 재생.
## 해시는 판정에 쓰는 상태(자리 · 체력 · 체간 · 게이지 · 상태 · 프레임 · 방)를 1/1000 로 반올림해 글자로 이어 hash().
## 한계: 같은 기계 · 같은 빌드의 결정성만 시험한다 — arm64(폰) 대 x86_64 의 실수 차이는 멀티 실기에서 본다(S6).

const Duel = preload("res://src/combat/duel.gd")
const Stage = preload("res://src/combat/stage.gd")

const VERSION := 1                       # 기록 형식 버전 — 칸 뜻이 바뀌면 올린다(옛 기록은 돌리지 않는다)
const CHECK_EVERY := 60                  # 중간 해시 간격(1초)
const AXIS := 127                        # 막대 한 축의 칸 수
const BITS := ["attack", "parry", "parry_held", "roll", "skill", "skill_next", "swap", "dash", "jump", "crouch"]   # 순서 = 비트 자리(바꾸면 VERSION — 끝에 더하는 것은 옛 기록과 같다)


## 사람 입력 → 양자화한 입력(빠진 단추는 false, 막대 길이는 1 까지)
static func quantize(it: Dictionary) -> Dictionary:
	return decode(_enc(it))


static func encode(it: Dictionary) -> Array:
	return _enc(it)


static func _enc(it: Dictionary) -> Array:
	var mv: Vector2 = it.get("move", Vector2.ZERO)
	mv = mv.limit_length(1.0)
	var fc: Vector2 = it.get("face", Vector2.ZERO)
	fc = fc.limit_length(1.0)
	var bits := 0
	for i in BITS.size():
		if it.get(BITS[i], false):
			bits |= 1 << i
	return [roundi(mv.x * AXIS), roundi(mv.y * AXIS), roundi(fc.x * AXIS), roundi(fc.y * AXIS), bits,
		int(it.get("skill_pick", -1))]


## 정수 6개 → 입력(JSON 을 거쳐 실수로 와도 된다)
static func decode(a: Array) -> Dictionary:
	var it := {"move": Vector2(float(int(a[0])) / AXIS, float(int(a[1])) / AXIS),
		"face": Vector2(float(int(a[2])) / AXIS, float(int(a[3])) / AXIS)}
	var bits := int(a[4])
	for i in BITS.size():
		it[BITS[i]] = (bits & (1 << i)) != 0
	if a.size() > 5 and int(a[5]) >= 0:
		it["skill_pick"] = int(a[5])
	return it


static func _q(x: float) -> String:
	return str(roundi(x * 1000.0))


## 판 상태 해시 — 판정에 쓰는 값만(그림 · 연출 값은 뺀다)
static func state_hash(d: Dictionary) -> int:
	var w = d["world"]
	var parts: PackedStringArray = [str(d.get("kind", "duel")), str(w.frame), str(w.hitstop), str(w.slowmo), str(w.phase),
		w.over, str(w.pending.size())]
	if d.get("kind", "") == "stage":
		parts.append_array([str(d["room_i"]), str(d["stage"]), str(d["ctrl"]), str(d["t"])])
	for f in w.fighters:
		parts.append_array([f.char_id, str(f.team), f.state, str(f.t), str(f.attack_id), _q(f.pos.x), _q(f.pos.y),
			_q(f.facing.x), _q(f.facing.y), _q(f.vel.x), _q(f.vel.y), _q(f.hp), _q(f.posture), _q(f.gauge),
			str(f.skill_idx), str(f.phase), str(f.inert)])
	return "|".join(parts).hash()


static func start(kind: String, seed_value: int, opts := {}) -> Dictionary:
	return {"v": VERSION, "kind": kind, "seed": seed_value, "opts": opts.duplicate(), "inputs": [], "checks": [], "hash": 0}


## 한 프레임 기록 — step 바로 앞에 부른다(it 는 quantize 한 입력 또는 null)
static func add(rec: Dictionary, d: Dictionary, it) -> void:
	_check(rec["checks"], rec["inputs"].size(), d)
	rec["inputs"].append(null if it == null else encode(it))


static func finish(rec: Dictionary, d: Dictionary) -> void:
	_check(rec["checks"], rec["inputs"].size(), d)
	rec["hash"] = state_hash(d)


static func _check(checks: Array, n: int, d: Dictionary) -> void:
	if n > 0 and n % CHECK_EVERY == 0:
		checks.append(state_hash(d))


static func make(rec: Dictionary) -> Dictionary:
	var opts: Dictionary = rec.get("opts", {})
	if str(rec["kind"]) == "stage":
		return Stage.make(int(rec["seed"]), opts)
	return Duel.make(int(rec["seed"]), opts)


static func step(d: Dictionary, it) -> void:
	if str(d.get("kind", "duel")) == "stage":
		Stage.step(d, it)
	else:
		Duel.step(d, it)


## 기록을 처음부터 다시 돌린다 → {ok, hash, checks, frames, error}. ok = 끝 해시와 중간 해시가 기록과 같다
static func play(rec: Dictionary) -> Dictionary:
	if int(rec.get("v", 0)) != VERSION:
		return {"ok": false, "error": "기록 형식 v%s — 이 판은 v%d" % [str(rec.get("v")), VERSION], "hash": 0, "checks": [], "frames": 0}
	var d := make(rec)
	var checks: Array = []
	var inputs: Array = rec["inputs"]
	for n in inputs.size():
		_check(checks, n, d)
		step(d, null if inputs[n] == null else decode(inputs[n]))
		d["world"].events.clear()
	_check(checks, inputs.size(), d)
	var h := state_hash(d)
	var want: Array = []
	for c in rec.get("checks", []):
		want.append(int(c))
	var same: bool = h == int(rec.get("hash", 0)) and checks == want
	return {"ok": same, "hash": h, "checks": checks, "frames": inputs.size(),
		"error": "" if same else "어긋남 — 첫 중간 해시 %d번" % first_mismatch(want, checks)}


## 두 중간 해시 열에서 처음 다른 자리(다 같으면 -1, 길이만 다르면 짧은 쪽 길이)
static func first_mismatch(a: Array, b: Array) -> int:
	for i in mini(a.size(), b.size()):
		if int(a[i]) != int(b[i]):
			return i
	return -1 if a.size() == b.size() else mini(a.size(), b.size())
