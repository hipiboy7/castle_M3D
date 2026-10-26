extends RefCounted
## 싸우는 사람 하나의 상태 기계 — 순수 로직(노드 없음, 60프레임 고정, 같은 입력이면 같은 결과).
## castle_M `castle_m/action/fighter.py` 의 규칙을 초안에 필요한 만큼 줄여 옮겼다(구르기 무적 · 쳐내기 창 · 버퍼 ·
## 휘청 · 빈틈). 판정은 world.gd, 그림은 src/view/puppet3d.gd 가 이 상태를 읽어서 그린다.
## 좌표: pos 는 바닥 평면 (x, z) 미터. z 는 화면 아래(카메라 쪽)로 커진다.

const Moves = preload("res://src/data/moves.gd")
const Skills = preload("res://src/data/skills.gd")

const ROLL_T := 20
const ROLL_IFRAMES := Vector2i(2, 14)
const ROLL_DIST := 2.2
const PARRY_WINDOW := 7          # 누른 뒤 이 프레임 안에 칼을 받으면 '칼날 쳐내기' (늦게 누른 것은 world.gd LATE_PARRY)
const PARRY_MIN := 12            # 짧게 눌러도 이만큼은 막는 자세
const PARRY_END := 8             # 막기를 풀고 돌아오는 동안은 빈틈
const PARRY_SPAM := 24           # 막기를 푼 뒤 이 안에 다시 누르면 판정 창이 줄어든다
const PARRY_BUFFER := 3
const ATTACK_BUFFER := 8
const ROLL_BUFFER := 5
const COUNTER_T := 24            # 쳐내기 성공 뒤 반격 베기를 낼 수 있는 프레임
const DOWN_T := 70               # 제압당해 넘어진 뒤 일어나기까지
const RUN_AFTER := 10            # 스틱을 끝까지 이만큼 밀면 달리기 → 공격은 돌진 찌르기
const BODY_R := 0.3
const POSTURE_REGEN := 0.22      # 체간 회복(프레임당), 마지막 체간 피해 뒤 REGEN_AFTER 부터
const REGEN_AFTER := 90

var name := ""
var team := 0
var is_boss := false
var pos := Vector2.ZERO
var facing := Vector2(0, -1)
var vel := Vector2.ZERO          # 넉백 속도 (m/초)
var state := "idle"
var t := 0
var clock := 0
var move: Dictionary = {}
var attack_id := 0               # 기술을 낼 때마다 1씩 — AI 가 같은 공격에 두 번 반응하지 않게
var hit_ids := {}
var moveset := {}
var _target: WeakRef = null      # 마주 보는 상대 (서로 붙잡으면 순환 참조라 약한 참조)

var hp := 100.0
var hp_max := 100.0
var posture := 0.0
var posture_max := 100.0
var last_posture_hit := -999
var poise := 0.0                 # 체간 피해가 이보다 작은 공격에는 움찔하지 않는다 (보스)
var dmg_k := 1.0
var parry_extra := 0
var stagger_len := 50
var walk_speed := 2.1
var run_speed := 4.6

var intent := {}
var buf_attack := 0
var buf_parry := 0
var parry_side := "R"            # 쳐내는 동작 방향 (L 왼팔 · R 오른팔, 그림용) — 판정과 관계없다
var buf_roll := 0
var parry_bonus := 0
var last_parry_end := -999
var hold_t := 0                  # 휘청 · 움찔이 이어지는 프레임
var counter_ready := 0
var flick_t := 0                 # 쳐내기 성공 동작(그림용)
var roll_dir := Vector2.ZERO
var running_t := 0
var speed_now := 0.0             # 지난 프레임 움직인 빠르기 (m/초, 그림용)
var move_vec := Vector2.ZERO     # 지난 프레임 움직인 방향 (그림용)
var flash := 0
var events: Array = []           # world 가 모아 가는 연출 신호

# 기술(스킬) — src/data/skills.gd. 게이지는 점수(한 칸 = Skills.BAR), 보스는 게이지 없이 패턴으로 쓴다(gauge_max 0)
var rank := 0
var skills: Array = []
var skill_idx := 0
var gauge := 0.0
var gauge_max := 0.0
var gauge_rate := 1.0
var buf_skill := 0
var skill_paid := 0.0            # 마지막 기술에 쓴 칸 수 (엇엇박 피해가 비례)
var hp_floor := 0.0              # 체력이 최대 체력의 이 비율 아래로 내려가지 않는다 (백도찬 첫 엇박 장면)


func set_target(f) -> void:
	_target = weakref(f) if f != null else null


func target():
	return _target.get_ref() if _target != null else null


func _init(nm := "", tm := 0) -> void:
	name = nm
	team = tm


func can_act() -> bool:
	return state == "idle" or state == "move"


func alive() -> bool:
	return state != "dead"


func set_state(s: String) -> void:
	state = s
	t = 0


func start_move(nm: String) -> void:
	move = Moves.get_move(nm)
	attack_id += 1
	hit_ids.clear()
	buf_attack = 0
	running_t = 0
	set_state("attack")


func is_active() -> bool:
	if state != "attack":
		return false
	var s := int(move["startup"])
	return t > s and t <= s + int(move["active"])


func in_recovery() -> bool:
	return state == "attack" and t > int(move["startup"]) + int(move["active"])


func iframes() -> bool:
	return state == "roll" and t >= ROLL_IFRAMES.x and t <= ROLL_IFRAMES.y


func parry_open() -> bool:
	return state == "parry" and t <= PARRY_WINDOW + parry_bonus + parry_extra


## 예고: [종류, 판정까지 남은 프레임] — 종류 parry(흰 !) · unblock(빨간 !). 예고가 없으면 [].
func telegraph() -> Array:
	if state != "attack" or str(move["telegraph"]) == "":
		return []
	var left := int(move["startup"]) - t
	if left < 0:
		return []
	return [str(move["telegraph"]), left]


func dir_to(other) -> Vector2:
	var d: Vector2 = other.pos - pos
	return d.normalized() if d.length() > 0.0001 else facing


func dist_to(other) -> float:
	return pos.distance_to(other.pos)


## 공격 · 막기 · 구르기 버튼은 '누른 프레임'만 true 로 온다. 역경직 중에도 받아 둔다(씹히지 않게).
func buffer_inputs() -> void:
	if intent.get("attack", false):
		buf_attack = ATTACK_BUFFER
	if intent.get("parry", false):
		buf_parry = PARRY_BUFFER
	if intent.get("roll", false):
		buf_roll = ROLL_BUFFER
	if intent.get("skill", false):
		buf_skill = ATTACK_BUFFER
	if intent.get("skill_next", false) and not skills.is_empty():
		skill_idx = (skill_idx + 1) % skills.size()


func _decay_buffers() -> void:
	buf_skill = ATTACK_BUFFER if intent.get("skill", false) else maxi(0, buf_skill - 1)
	buf_attack = ATTACK_BUFFER if intent.get("attack", false) else maxi(0, buf_attack - 1)
	buf_parry = PARRY_BUFFER if intent.get("parry", false) else maxi(0, buf_parry - 1)
	buf_roll = ROLL_BUFFER if intent.get("roll", false) else maxi(0, buf_roll - 1)


func tick() -> void:
	clock += 1
	t += 1
	var before := pos
	if flash > 0:
		flash -= 1
	if counter_ready > 0:
		counter_ready -= 1
	if flick_t > 0:
		flick_t -= 1
	if intent.get("skill_next", false) and not skills.is_empty():
		skill_idx = (skill_idx + 1) % skills.size()
	_decay_buffers()
	# 빈틈 · 움찔 중에도 쓰는 기술 (백도찬식 찌르기 — Move.any_state)
	var use: String = intent.get("use", "")
	if use != "" and (state == "stagger" or state == "hitstun") and Moves.get_move(use)["any_state"]:
		start_move(use)
	match state:
		"idle", "move":
			_tick_free()
		"attack":
			_tick_attack()
		"parry":
			if t >= PARRY_MIN and not intent.get("parry_held", false):
				last_parry_end = clock
				set_state("parry_end")
		"parry_end":
			if t >= PARRY_END:
				set_state("idle")
		"roll":
			_tick_roll()
		"hitstun", "recoil", "stun":
			if t >= hold_t:
				set_state("idle")
		"stagger":
			if t >= stagger_len:
				posture = 0.0
				set_state("idle")
		"down":
			if t >= DOWN_T:
				posture = 0.0
				set_state("idle")
	if vel.length() > 0.05:
		pos += vel / 60.0
		vel *= 0.86
	else:
		vel = Vector2.ZERO
	if clock - last_posture_hit > REGEN_AFTER and state != "stagger" and state != "down":
		posture = maxf(0.0, posture - POSTURE_REGEN)
	move_vec = pos - before
	speed_now = move_vec.length() * 60.0


func _tick_free() -> void:
	var mv: Vector2 = intent.get("move", Vector2.ZERO)
	if buf_roll > 0:
		_start_roll(mv.normalized() if mv.length() > 0.2 else -facing)
		return
	if buf_parry > 0:
		_start_parry()
		return
	if buf_skill > 0 and _try_skill():
		return
	var use: String = intent.get("use", "")
	if use != "":
		start_move(use)
		if move["skill"]:
			events.append(["skill", self, {"id": use, "name": move["label"]}])     # 보스 기술 (게이지 없이 패턴으로)
		return
	if buf_attack > 0:
		var nm := _pick_attack()
		if nm != "":
			start_move(nm)
			return
	var face: Vector2 = intent.get("face", Vector2.ZERO)
	if mv.length() > 0.1:
		running_t = running_t + 1 if mv.length() > 0.85 else 0
		var running := running_t >= RUN_AFTER
		var spd := run_speed if running else walk_speed * clampf(mv.length() * 1.3, 0.35, 1.0)
		pos += mv.normalized() * spd / 60.0
		if running or face == Vector2.ZERO:
			facing = mv.normalized()
		else:
			facing = face.normalized()
		state = "move"
	else:
		running_t = 0
		if face != Vector2.ZERO:
			facing = face.normalized()
		state = "idle"


## 반격 베기(쳐내기 직후) · 제압(상대가 빈틈) — 연타 중이어도 이것이 먼저다
func _special_attack() -> String:
	if counter_ready > 0 and moveset.has("counter"):
		return moveset["counter"]
	var tg = target()
	if tg != null and tg.state == "stagger" and dist_to(tg) < 1.6 and moveset.has("finisher"):
		return moveset["finisher"]
	return ""


func _pick_attack() -> String:
	var special := _special_attack()
	if special != "":
		return special
	if running_t >= RUN_AFTER and moveset.has("dash"):
		return moveset["dash"]
	return moveset.get("combo", "")


func _tick_attack() -> void:
	var s := int(move["startup"])
	var a := int(move["active"])
	# 준비 앞부분 동안은 상대 쪽으로 몸을 튼다 (보스는 길게 — 예고를 보고 옆으로 돌아도 따라온다)
	var track := int(s * 0.6) if is_boss else 2
	var tg = target()
	if tg != null and t <= track:
		facing = dir_to(tg)
	var lunge: float = move["lunge"]
	if lunge > 0.0 and t <= s + a:
		pos += facing * lunge / float(s + a)
	var side: float = move["side"]
	if side != 0.0 and t <= s:
		pos += Vector2(-facing.y, facing.x) * side / float(s)
	if int(move["hits"]) > 1 and is_active():
		var step := maxi(1, a / int(move["hits"]))
		if (t - s - 1) % step == 0:
			hit_ids.clear()
	for fr in move["feints"]:
		if t == int(fr):
			events.append(["feint", self])
	# 연타 중에도 기술로 끊을 수 있다(기술 동작에서 다른 기술로는 안 된다)
	if buf_skill > 0 and t >= Moves.cancel_at(move) and not move["skill"] and _try_skill():
		return
	if buf_attack > 0 and t >= Moves.cancel_at(move) and not is_boss:
		var special := _special_attack()
		if special != "" and special != str(move["name"]):
			start_move(special)
			return
		if str(move["next"]) != "":
			start_move(str(move["next"]))
			return
	# 회수 뒤쪽은 구르기로 끊을 수 있다
	if buf_roll > 0 and t > s + a + 4:
		var mv: Vector2 = intent.get("move", Vector2.ZERO)
		_start_roll(mv.normalized() if mv.length() > 0.2 else -facing)
		return
	if t >= Moves.total(move):
		set_state("idle")


## 고른 기술을 낸다 — 게이지가 모자라면 아무것도 안 하고 false (버퍼는 남겨 두지 않는다)
func _try_skill() -> bool:
	if skills.is_empty():
		return false
	buf_skill = 0
	var sk: Dictionary = skills[skill_idx]
	if not can_pay(sk):
		events.append(["no_gauge", self])
		return false
	if float(sk["cost"]) < 0.0:
		skill_paid = gauge / Skills.BAR                 # 엇엇박: 게이지 전부
		gauge = 0.0
	else:
		skill_paid = float(sk["cost"])
		gauge -= skill_paid * Skills.BAR
	start_move(str(sk["move"]))
	events.append(["skill", self, sk])
	return true


func current_skill() -> Dictionary:
	return skills[skill_idx] if not skills.is_empty() else {}


## 이 기술을 쓸 만큼 게이지가 찼는지 (cost < 0 = 엇엇박: ALL_MIN_BARS 칸 이상)
func can_pay(sk: Dictionary) -> bool:
	var cost := float(sk["cost"])
	if cost < 0.0:
		return gauge + 0.001 >= Skills.ALL_MIN_BARS * Skills.BAR
	return gauge + 0.001 >= cost * Skills.BAR


## 기술 목록에서 id 의 자리 (없으면 -1)
func skill_index(id: String) -> int:
	for i in skills.size():
		if str(skills[i]["id"]) == id:
			return i
	return -1


## 기술 게이지 채우기 (kind: Skills.GAIN 의 종류)
func gain(kind: String, k := 1.0) -> void:
	if gauge_max > 0.0:
		gauge = clampf(gauge + float(Skills.GAIN.get(kind, 0.0)) * k * gauge_rate, 0.0, gauge_max)


func _start_parry() -> void:
	buf_parry = 0
	var tg = target()
	if tg != null and tg.state == "attack":
		parry_side = Moves.parry_side(tg.move)      # 상대가 내는 공격 쪽 팔을 세운다
	parry_bonus = -3 if clock - last_parry_end < PARRY_SPAM else 0
	set_state("parry")


func _start_roll(d: Vector2) -> void:
	buf_roll = 0
	roll_dir = d
	running_t = 0
	set_state("roll")


func _tick_roll() -> void:
	# 처음이 빠르고 끝이 느리다. 합하면 ROLL_DIST
	pos += roll_dir * ROLL_DIST * (1.0 - float(t) / ROLL_T) / 9.5
	if t >= ROLL_T:
		set_state("idle")


# ----------------------------------------------------------------------
# 맞기 · 쳐내기 당하기 (world.gd 가 부른다)
func take_posture(v: float) -> void:
	posture = minf(posture_max, posture + v)
	last_posture_hit = clock


func get_hit(mv: Dictionary, from_dir: Vector2) -> void:
	flash = 8
	vel = from_dir * float(mv["knockback"])
	if state == "stagger" or state == "down" or state == "dead":
		return
	if is_boss and float(mv["posture"]) < poise:
		return                                   # 버팀: 피해만 받고 움찔하지 않는다
	hold_t = int(mv["hitstun"])
	set_state("hitstun")


func get_recoil(frames: int, from_dir: Vector2) -> void:
	vel = from_dir * 1.8
	hold_t = frames
	set_state("recoil")


## 기절 (각법): 움직이지 못하고 머리 위에 '기절'
func get_stun(frames: int) -> void:
	if state == "stagger" or state == "down" or state == "dead":
		return
	hold_t = frames
	set_state("stun")


func get_stagger() -> void:
	posture = posture_max
	set_state("stagger")


func get_down() -> void:
	set_state("down")


func die() -> void:
	hp = 0.0
	set_state("dead")
