extends RefCounted
## 결투 판정 — 공격 판정 · 구르기 무적 · 칼날 쳐내기 · 막기 · 체간 · 빈틈 · 제압 · 역경직 · 페이즈.
## castle_M `castle_m/action/combat.py` 와 P2 설계서 8.3절(보스 규칙)의 수치를 초안 크기로 옮겼다.
## 순수 로직이라 테스트(tests/test_combat.gd)와 자동 플레이(--autoplay)가 그림 없이 돌린다.

const Fighter = preload("res://src/combat/fighter.gd")

const PARRY_HITSTOP := 9
const PARRY_SHAKE := 4
const BLOCK_DMG_K := 0.2
const BLOCK_POSTURE_K := 0.8
const FINISHER_CAP_BOSS := 0.08          # 보스에게 제압 피해는 최대 체력의 8%
const PHASE2_AT := 0.55                  # 1차 체력 바닥 — 여기서 2차로
const PHASE2_FREEZE := 50                # 2차로 넘어가는 동안 멈춤(컷인)

var fighters: Array = []
var frame := 0
var hitstop := 0
var shake := 0
var events: Array = []                   # [종류, ...] — 그림 · 소리가 매 프레임 가져가고 비운다
var bounds := Rect2(-6.6, -3.6, 13.2, 7.4)
var over := ""                           # "" / win / lose
var phase := 1
var stats := {"hits": 0, "parries": 0, "boss_parries": 0, "dodges": 0, "blocks": 0, "staggers": 0}


func add(f) -> void:
	fighters.append(f)


func hero():
	for f in fighters:
		if not f.is_boss:
			return f
	return null


func boss():
	for f in fighters:
		if f.is_boss:
			return f
	return null


func tick() -> void:
	frame += 1
	if shake > 0:
		shake -= 1
	if hitstop > 0:
		hitstop -= 1
		for f in fighters:
			f.buffer_inputs()
		return
	if over != "":
		return
	for f in fighters:
		f.tick()
		for e in f.events:
			events.append(e)
		f.events.clear()
	_separate()
	for f in fighters:
		f.pos.x = clampf(f.pos.x, bounds.position.x, bounds.end.x)
		f.pos.y = clampf(f.pos.y, bounds.position.y, bounds.end.y)
	_hits()


func _separate() -> void:
	for i in fighters.size():
		for j in range(i + 1, fighters.size()):
			var a = fighters[i]
			var b = fighters[j]
			if a.state == "roll" or b.state == "roll" or not a.alive() or not b.alive():
				continue
			var d: Vector2 = b.pos - a.pos
			var n := d.length()
			var need: float = Fighter.BODY_R * 2.0
			if n < need:
				var push := (d / n if n > 0.0001 else Vector2(1, 0)) * (need - n) * 0.5
				a.pos -= push
				b.pos += push


func _in_hit(a, d) -> bool:
	var mv: Dictionary = a.move
	var reach: float = mv["reach"]
	var radius: float = mv["radius"]
	var body: float = Fighter.BODY_R
	if str(mv["shape"]) == "spin":
		return a.pos.distance_to(d.pos) <= radius + body
	var center: Vector2 = a.pos + a.facing * reach
	if center.distance_to(d.pos) <= radius + body:
		return true
	# 호를 그리는 베기는 정면에서 호 반각 안 · 사거리 안이면 맞는다
	var arc: float = mv["arc"]
	if arc > 0.0:
		var to: Vector2 = d.pos - a.pos
		if to.length() <= reach + radius + body and to.length() > 0.0001:
			return absf(rad_to_deg(a.facing.angle_to(to))) <= arc * 0.5
	return false


func _faces(d, a) -> bool:
	return d.facing.dot(d.dir_to(a)) > 0.3


func _hits() -> void:
	for a in fighters:
		if not a.is_active():
			continue
		for d in fighters:
			if d == a or d.team == a.team or not d.alive():
				continue
			if a.hit_ids.has(d.get_instance_id()):
				continue
			if not _in_hit(a, d):
				continue
			a.hit_ids[d.get_instance_id()] = true
			_resolve(a, d)


func _resolve(a, d) -> void:
	var mv: Dictionary = a.move
	var at: Vector3 = _contact(a, d)
	var push: Vector2 = a.dir_to(d)
	if d.iframes():
		stats["dodges"] += 1
		events.append(["dodge", d, at])
		return
	var parryable: bool = mv["parryable"]
	if parryable and d.parry_open() and _faces(d, a):
		_parry(a, d, at)
		return
	if parryable and d.state == "parry" and _faces(d, a):
		stats["blocks"] += 1
		d.hp -= float(mv["damage"]) * a.dmg_k * BLOCK_DMG_K
		d.take_posture(float(mv["posture"]) * BLOCK_POSTURE_K)
		d.vel = push * float(mv["knockback"]) * 0.6
		hitstop = maxi(hitstop, 4)
		events.append(["block", d, at])
		if d.posture >= d.posture_max:
			_stagger(d)
		_check_hp(d)
		return
	# 맞음
	var dmg: float = float(mv["damage"]) * a.dmg_k
	if str(mv["name"]).ends_with("finisher") and d.state == "stagger":
		if d.is_boss:
			dmg = minf(dmg, d.hp_max * FINISHER_CAP_BOSS)
		d.hp -= dmg
		d.posture = 0.0
		d.get_down()
		d.vel = push * float(mv["knockback"])
		d.flash = 10
		hitstop = maxi(hitstop, int(mv["hitstop"]))
		shake = maxi(shake, int(mv["shake"]))
		stats["hits"] += 1
		events.append(["finish", d, at, a])
		_check_hp(d)
		return
	d.hp -= dmg
	d.take_posture(float(mv["posture"]))
	d.get_hit(mv, push)
	stats["hits"] += 1
	hitstop = maxi(hitstop, int(mv["hitstop"]))
	shake = maxi(shake, int(mv["shake"]))
	events.append(["hit", d, at, mv])
	if d.posture >= d.posture_max and d.state != "stagger" and d.state != "down":
		_stagger(d)
	_check_hp(d)


func _parry(a, d, at: Vector3) -> void:
	var mv: Dictionary = a.move
	# 보스가 김신을 쳐내면 휘청이 짧다 (맞받아 베기를 다시 쳐낼 수 있게) — castle_M P2 설계서 8.3
	var k := 0.35 if d.is_boss else 2.2
	var bonus := 0.0 if d.is_boss else 22.0
	var frames := 12 if d.is_boss else 28
	a.take_posture(float(mv["posture"]) * k + bonus)
	a.get_recoil(frames, d.dir_to(a))
	d.counter_ready = Fighter.COUNTER_T
	d.flick_t = 10
	d.set_state("idle")
	hitstop = maxi(hitstop, PARRY_HITSTOP)
	shake = maxi(shake, PARRY_SHAKE)
	if d.is_boss:
		stats["boss_parries"] += 1
	else:
		stats["parries"] += 1
	events.append(["parry", d, at, a])
	if a.posture >= a.posture_max:
		_stagger(a)


func _stagger(f) -> void:
	f.get_stagger()
	stats["staggers"] += 1
	events.append(["stagger", f])


func _check_hp(d) -> void:
	if d.is_boss and phase == 1 and d.hp <= d.hp_max * PHASE2_AT:
		d.hp = d.hp_max * PHASE2_AT
		phase = 2
		hitstop = maxi(hitstop, PHASE2_FREEZE)
		events.append(["phase2", d])
		return
	if d.hp <= 0.0:
		d.die()
		events.append(["ko", d])
		over = "lose" if not d.is_boss else "win"
		hitstop = maxi(hitstop, 30)


## 맞은 자리 (3D: x, 높이, z) — 불꽃 · 번쩍임이 여기서 난다
func _contact(a, d) -> Vector3:
	var p: Vector2 = a.pos.lerp(d.pos, 0.6)
	var h := 1.15
	var shape := str(a.move["shape"])
	if shape == "sidekick":
		h = 0.95
	elif shape == "thrust_low":
		h = 0.9
	return Vector3(p.x, h, p.y)
