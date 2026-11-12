extends RefCounted
## 장면 연출(컷신) — 방 표 scene(싸움 앞) · triggers 의 scene(싸움 중 · 끝)이 주는 단계 목록을 차례로 돈다(2026-11-12 사용자 —
## 2장 '이슬과 대가리 정하기' 앞뒤 대화 · 대표실 김재훈 창문 · 3장 피우진 특급훈련 끝 · 프롤로그 주점 청부).
## 순수 로직(노드 없음 · 60프레임 고정 · 같은 판이면 같은 결과). 도는 동안은 사람 입력 · AI 를 받지 않고(모두 멈춤) 단계가
## 시키는 사람만 움직인다. 장면 속 동작(use)은 판정이 없다(fighter.scripted — world.gd 가 맞힘을 안 본다). 싸움 시간도 멈춘다.
## 그림 · 말풍선은 신호로만(main.gd · event_fx.gd): ["bubble", 사람, 말, 초] · ["toss", 사람, 처음 자리, 끝 자리, 초] ·
##   ["prop_fx", 종류, 자리] · ["sfx", 이름] · ["leave", 사람] · ["scene", true/false](터치 버튼 숨김 · 화면 위아래 띠)
##
## 단계(사전 하나 — 칸 하나가 종류를 정한다. who 는 인물 id 또는 방 표 tag):
##   {"say": [who, "말"], (secs)}       말풍선. secs 가 없으면 글 길이로(SAY_MIN ~ SAY_MAX)
##   {"says": [[who, "말"], ..]}         말풍선 여럿을 차례로(각 줄 say 와 같다)
##   {"walk": who, "to": Vector2, (run)} 그 자리까지 걷는다(run — 달린다). 다른 사람(at)으로 줘도 된다: "to_who": id, "gap": m
##   {"face": who, "at": who2 | [x, y]}  그쪽을 본다(바로)
##   {"use": who, "move": 동작 이름}      동작 하나(판정 없음) — 끝날 때까지 기다린다(nowait: true 면 걸어 두고 바로 다음)
##   {"freeze": true | false}             판을 그 순간에 세운다 / 다시 돌린다(말풍선은 그대로 — 3장 크리샤 빨간 !)
##   {"wait": 초}
##   {"leave": who, (dir: -1 | 1)}       맵 가장자리 밖으로 걸어 나가 사라진다(dir 없으면 가까운 옆). slow: true — 천천히 걷는다,
##                                       nowait: true — 걸어 나가게 두고 바로 다음 단계(나가는 동안 남은 사람이 말한다 · 카메라는 남은 쪽)
##   {"stand": who}                      쓰러진 사람을 일으킨다(체력 1 — 장면 속에서만)
##   {"down": who}                       그 자리에 쓰러뜨린다
##   {"carry": who, "target": who2, "to": Vector2, (push_to: Vector2)}  who 가 who2 를 앞에 붙잡고(멱살) 그 자리까지 끈다.
##                                       push_to 가 있으면 그쪽을 보고 밀고 가 who2 가 to 에 닿는다(2장 대표실 창 — 2026-11-12 사용자 "창문쪽으로
##                                       끌고가야되는데, 오히려 안쪽(아래쪽)으로 끌고와버려")
##   {"toss": who, "to": Vector2, "secs": 초}        날아가 사라진다(창 밖 — 맵 밖도 된다. 판에서 빠진다)
##   {"fx": 종류, "at": Vector2}          무대 연출(glass — 유리 깨짐 · shot — 총소리 · 섬광 · smash — 부서짐)
##   {"place": who, "at": Vector2}       바로 그 자리에(장면 시작 전 세우기)
##   {"pose": who, "name": "sit"}         장면 자세(그림만 — poses.gd SCENE: sit · lean · arms · hands_up · kneel · lie_up, "" = 보통)
##   {"end": "fight" | "clear" | "win"}  장면을 끝낸다 — fight 싸움 계속(기본), clear 방을 깸, win 판을 이김(끝 방이 아니어도)

const SAY_MIN := 1.6
const SAY_MAX := 4.2
const SAY_PER_CHAR := 0.085
const WALK_TIMEOUT := 12.0           # 절뚝이며 걷는 의뢰인(0장 주점) 6m 도 닿게
const LEAVE_PAD := 1.4             # 가장자리 밖 이만큼 나가면 사라진다
const CARRY_GAP := 0.55
const LEAVE_SLOW := 0.42           # 천천히 퇴장(걷기 입력 크기 — 2026-11-12 사용자 "김신과 김대건은 천천히 퇴장해")
const LEAVE_TIMEOUT := 14.0        # 나가는 사람(nowait)이 이만큼 지나도 가장자리에 못 닿으면 치운다


## 장면 시작 — 지금 판의 모든 사람을 멈추고 단계 목록을 건다(end_mode: 단계에 end 가 없을 때 끝나면 할 일)
static func start(d: Dictionary, steps: Array, end_mode := "fight") -> void:
	if steps.is_empty():
		return
	d["scene"] = {"steps": steps, "i": 0, "t": 0, "end": end_mode, "carry": null, "started": false}
	for f in d["world"].fighters:
		f.scripted = true
		f.intent = {}
		if f.state == "attack" or f.state == "parry" or f.state == "roll":
			f.set_state("idle")
	d["world"].pending.clear()
	d["world"].events.append(["scene", true])


static func active(d: Dictionary) -> bool:
	return d.has("scene")


## 멈춤 단계(freeze) 중 — 판 한 칸을 안 돌린다(그 순간 자세 · 빨간 ! 그대로, 말풍선만)
static func frozen(d: Dictionary) -> bool:
	return d.has("scene") and bool(d["scene"].get("frozen", false))


## 넘기기(사람이 공격 버튼): 지금 말풍선 하나를 끝낸다 — 걷기 · 동작은 그대로(장면이 꼬이지 않게)
static func skip(d: Dictionary) -> void:
	var sc: Dictionary = d["scene"]
	if int(sc["t"]) > 12:                       # 막 뜬 풍선은 안 넘긴다(두 번 눌림)
		sc["skip"] = true


## 판 한 칸(world.tick) 뒤: 끌려가는 사람을 다시 앞에(자리 밀어내기 · 가장자리 막기 뒤)
static func after_tick(d: Dictionary) -> void:
	if d.has("scene"):
		_hold_carry(d, d["scene"])


## 한 프레임: 모두의 입력을 비우고 지금 단계를 한 칸. 단계가 끝나면 다음으로(같은 프레임에 즉시 끝나는 단계는 이어서)
static func tick(d: Dictionary) -> void:
	var sc: Dictionary = d["scene"]
	for f in d["world"].fighters:
		f.intent = {}
	_tick_leaving(d, sc)
	var guard := 0
	while d.has("scene") and guard < 16:
		guard += 1
		if int(sc["i"]) >= (sc["steps"] as Array).size():
			_finish(d, str(sc["end"]))
			return
		var st: Dictionary = sc["steps"][sc["i"]]
		if not _run(d, sc, st):
			break
		sc["i"] = int(sc["i"]) + 1
		sc["t"] = 0
		sc["started"] = false
	if d.has("scene"):
		sc["t"] = int(sc["t"]) + 1
	_hold_carry(d, sc)


## 단계 하나를 이 프레임에 돈다 — 끝났으면 true
static func _run(d: Dictionary, sc: Dictionary, st: Dictionary) -> bool:
	var w = d["world"]
	var t: int = sc["t"]
	var first: bool = not sc["started"]
	sc["started"] = true
	var skip: bool = sc.get("skip", false)
	sc["skip"] = false
	if st.has("say"):
		if skip and not first:
			w.events.append(["bubble_cut"])
			return true
		var sid := str(st["say"][0])
		var who = who_of(d, sid, true)
		if who == null and sid != "@" and not sid.begins_with("?"):
			return true                              # 그 사람이 판에 없다(쓰러져 치워짐 · 안 나옴) — 건너뛴다
		var secs := float(st.get("secs", say_secs(str(st["say"][1]))))
		if first:
			if who != null:
				who.facing = _face_to_talk(d, who)
				sc["speaker"] = who
			w.events.append(["bubble", who, str(st["say"][1]), secs - 0.15, str(st["say"][0])])
		return t >= int(secs * 60.0)
	if st.has("says"):
		var lines: Array = st["says"]
		var k: int = int(sc.get("sub", 0)) if not first else 0
		if first:
			sc["sub"] = 0
			sc["sub_t"] = 0
		var ln: Array = lines[k]
		var secs2 := say_secs(str(ln[1]))
		if int(sc["sub_t"]) == 0:
			var who2 = who_of(d, str(ln[0]), true)
			if who2 != null:
				who2.facing = _face_to_talk(d, who2)
			w.events.append(["bubble", who2, str(ln[1]), secs2 - 0.15, str(ln[0])])
		sc["sub_t"] = int(sc["sub_t"]) + 1
		if skip and int(sc["sub_t"]) > 1:
			w.events.append(["bubble_cut"])
			sc["sub_t"] = int(secs2 * 60.0)
		if int(sc["sub_t"]) >= int(secs2 * 60.0):
			sc["sub"] = k + 1
			sc["sub_t"] = 0
			return k + 1 >= lines.size()
		return false
	if st.has("wait"):
		return t >= int(float(st["wait"]) * 60.0)
	if st.has("place"):
		var pf = who_of(d, str(st["place"]))
		if pf != null:
			pf.pos = v2(st["at"])
		return true
	if st.has("freeze"):
		sc["frozen"] = bool(st["freeze"])
		return true
	if st.has("pose"):
		var pp = who_of(d, str(st["pose"]), true)
		if pp != null:
			pp.pose = str(st.get("name", ""))
		return true
	if st.has("face"):
		var a = who_of(d, str(st["face"]), true)
		var to = v2(st["at"]) if (st["at"] is Array or st["at"] is Vector2) else null
		if to == null:
			var b = who_of(d, str(st["at"]), true)
			to = b.pos if b != null else null
		if a != null and to != null and a.pos.distance_to(to) > 0.01:
			a.facing = (to - a.pos).normalized()
		return true
	if st.has("walk"):
		var f = who_of(d, str(st["walk"]))
		if f == null:
			return true
		var goal: Vector2 = v2(st.get("to", f.pos))
		if st.has("to_who"):
			var o = who_of(d, str(st["to_who"]))
			if o != null:
				var gap := float(st.get("gap", 0.9))
				goal = o.pos + (f.pos - o.pos).normalized() * gap
		return _walk(f, goal, bool(st.get("run", false)), t)
	if st.has("use"):
		var u = who_of(d, str(st["use"]))
		if u == null:
			return true
		if first:
			u.set_state("idle")
			u.intent = {"use": str(st["move"])}
			return false
		if st.get("nowait", false):
			return true                              # 동작을 걸어 두고 바로 다음 단계(3장 크리샤 빨간 ! 순간 멈춤)
		return u.state != "attack" or t > 240
	if st.has("leave"):
		var ids: Array = st["leave"] if st["leave"] is Array else [st["leave"]]
		var b2: Rect2 = w.bounds
		var left := 0
		var k := LEAVE_SLOW if st.get("slow", false) else 1.0
		for id in ids:
			var l = who_of(d, str(id))
			if l == null or not w.fighters.has(l):
				continue
			var dir := float(st.get("dir", 0.0))
			if dir == 0.0:
				dir = -1.0 if l.pos.x - b2.position.x < b2.end.x - l.pos.x else 1.0
			if st.get("nowait", false):
				if first:
					var lv: Array = sc.get("leaving", [])
					lv.append([l, dir * k, int(d["n"])])
					sc["leaving"] = lv
					l.intent = {"move": Vector2(dir * k, 0.0)}
				continue
			l.intent = {"move": Vector2(dir * k, 0.0)}
			var gone: bool = l.pos.x <= b2.position.x + 0.05 or l.pos.x >= b2.end.x - 0.05
			if gone or t > int(WALK_TIMEOUT * 60.0):
				_remove(d, l)
			else:
				left += 1
		return left == 0
	if st.has("stand"):
		var s = who_of(d, str(st["stand"]), true)
		if s != null:
			s.hp = maxf(s.hp, 1.0)
			s.set_state("idle")
			s.vel = Vector2.ZERO
		return true
	if st.has("down"):
		var dn = who_of(d, str(st["down"]), true)
		if dn != null:
			dn.set_state("down")
			dn.t = -100000                      # 장면이 끝날 때까지 누워 있다(fighter DOWN_T 를 넘지 않게)
		return true
	if st.has("carry"):
		var c = who_of(d, str(st["carry"]))
		var tg = who_of(d, str(st["target"]), true)
		if c == null:
			return true
		sc["carry"] = [c, tg]
		var goal: Vector2 = v2(st["to"])
		if st.has("push_to"):
			var fd: Vector2 = (v2(st["push_to"]) - c.pos).normalized()
			sc["carry_face"] = fd
			goal -= fd * CARRY_GAP
		var done := _walk(c, goal, false, t)
		if done:
			sc["carry"] = null
			sc.erase("carry_face")
		return done
	if st.has("toss"):
		var tf = who_of(d, str(st["toss"]), true)
		if tf == null:
			return true
		if first:
			var secs3 := float(st.get("secs", 0.9))
			w.events.append(["toss", tf, tf.pos, v2(st["to"]), secs3])
			_remove(d, tf)
		return true
	if st.has("fx"):
		w.events.append(["prop_fx", str(st["fx"]), v2(st.get("at", Vector2.ZERO))])
		return true
	if st.has("end"):
		_finish(d, str(st["end"]))
		return true
	return true


static func _walk(f, goal: Vector2, run: bool, t: int) -> bool:
	var to: Vector2 = goal - f.pos
	if to.length() < 0.12 or t > int(WALK_TIMEOUT * 60.0):
		f.intent = {}
		return true
	f.intent = {"move": to.normalized() * (1.0 if run else 0.6)}
	return false


## 끌려가는 사람: 끄는 사람 앞에 붙는다(멱살) — 판의 자리 밀어내기와 상관없이
static func _hold_carry(d: Dictionary, sc: Dictionary) -> void:
	var cr = sc.get("carry") if d.has("scene") else null
	if cr == null or cr[1] == null:
		return
	var c = cr[0]
	var tg = cr[1]
	if sc.has("carry_face"):
		c.facing = sc["carry_face"]                     # 미는 쪽(창)을 본 채로 — 걸음 방향이 몸을 돌리지 않게
	tg.pos = c.pos + c.facing * CARRY_GAP
	tg.facing = -c.facing
	if tg.state != "stun":
		tg.set_state("stun")
	tg.hold_t = 100000


## 판에서 뺀다(맵 밖으로 나감 · 창 밖으로 날아감)
## 걸어 나가는 사람(leave nowait): 그쪽으로 계속 걷다가 가장자리에 닿거나 LEAVE_TIMEOUT 이 지나면 치운다
static func _tick_leaving(d: Dictionary, sc: Dictionary) -> void:
	var lv: Array = sc.get("leaving", [])
	if lv.is_empty():
		return
	var w = d["world"]
	var b2: Rect2 = w.bounds
	for i in range(lv.size() - 1, -1, -1):
		var l = lv[i][0]
		if not w.fighters.has(l):
			lv.remove_at(i)
			continue
		var gone: bool = l.pos.x <= b2.position.x + 0.05 or l.pos.x >= b2.end.x - 0.05
		if gone or int(d["n"]) - int(lv[i][2]) > int(LEAVE_TIMEOUT * 60.0):
			_remove(d, l)
			lv.remove_at(i)
		else:
			l.intent = {"move": Vector2(float(lv[i][1]), 0.0)}


## 장면 카메라가 볼 사람: 지금 말하는 사람(없으면 null) — main.gd 가 따라간다. 걸어 나가는 사람은 화면에서 뺀다(leaving)
static func speaker(d: Dictionary):
	return d["scene"].get("speaker") if d.has("scene") else null


static func leaving(d: Dictionary) -> Array:
	return d["scene"].get("leaving", []).map(func(x): return x[0]) if d.has("scene") else []


static func _remove(d: Dictionary, f) -> void:
	var w = d["world"]
	w.fighters.erase(f)
	w.pending = w.pending.filter(func(p): return p[0] != f and p[1] != f)
	d["enemies"].erase(f)
	d["allies"].erase(f)
	d["standing"].erase(f)
	f.inert = true
	w.events.append(["leave", f])


static func _finish(d: Dictionary, mode: String) -> void:
	var sc: Dictionary = d["scene"]
	for lv in sc.get("leaving", []):
		if d["world"].fighters.has(lv[0]):
			_remove(d, lv[0])                    # 아직 덜 나간 사람도 장면이 끝나면 치운다
	d.erase("scene")
	for f in d["world"].fighters:
		f.scripted = false
		f.intent = {}
		if f.state == "stun" and f.hold_t > 10000:
			f.set_state("idle")
	d["world"].events.append(["scene", false])
	match mode:
		"clear":
			d["clear_at"] = int(d["n"])
		"win":
			d["world"].over = "win"


## 말하는 사람은 가장 가까운 다른 사람 쪽을 본다(혼잣말이면 그대로)
static func _face_to_talk(d: Dictionary, f) -> Vector2:
	var best = null
	var bd := INF
	for o in d["world"].fighters:
		if o == f:
			continue
		var dd: float = f.pos.distance_to(o.pos)
		if dd < bd:
			bd = dd
			best = o
	if best == null or bd < 0.01:
		return f.facing
	return (best.pos - f.pos).normalized()


## 단계의 자리 — Vector2 또는 lines.json 의 [x, y]
static func v2(v) -> Vector2:
	if v is Vector2:
		return v
	if v is Array and v.size() >= 2:
		return Vector2(float(v[0]), float(v[1]))
	return Vector2.ZERO


static func say_secs(text: String) -> float:
	return clampf(SAY_MIN * 0.6 + text.length() * SAY_PER_CHAR, SAY_MIN, SAY_MAX)


## id(인물 id) 또는 방 표 tag 로 사람 찾기 — 살아 있는 사람 먼저, any 면 쓰러진 사람도
static func who_of(d: Dictionary, id: String, any := false):
	var hit = null
	for f in d["world"].fighters:
		if f.char_id == id or str(d.get("tag_of", {}).get(f, "")) == id:
			if f.alive():
				return f
			if any and hit == null:
				hit = f
	return hit
