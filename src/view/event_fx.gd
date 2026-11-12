extends RefCounted
## 판정 신호 → 연출 · 소리 · 알림 (main.gd 에서 뺌 — S2, CLAUDE.md 2-1절 SRP). 판정(world.gd · stage.gd)이 매 프레임 쌓은
## world.events 를 읽기만 한다 — 결투(duel)와 11장 판(stage)이 같은 신호를 쓴다. 그림은 pup(Fighter → 인형)으로 찾는다.

const Lines = preload("res://src/data/lines.gd")
const SLAMS := ["stomp", "two_hand_slam", "overhead_chop", "throw_slam", "hammer_fist"]   # 위에서 내려찍는 모양(2026-11-10 각법 axe 에서 갈라 나온 것)

var fx
var cam
var hud
var snd
var pup := {}
var bubbles                              # 말풍선(src/ui/bubbles.gd — main.gd 가 붙인다)
var arena                                # 무대(부서지는 소품 break_at — main.gd 가 방마다 바꿔 준다)
var _quote := RegEx.create_from_string("^([^:—]{1,12}): (.+?)(?: — (.+))?$")
var later_msg: Array = []                # 조금 뒤에 띄울 가운데 알림 [제목, 부제, 초]
var later_t := 0.0


func _msg(key: String, secs: float, delay := 0.0) -> void:
	var v: Array = Lines.at(key)
	hud.message(str(v[0]), str(v[1]), secs, delay)


## 맞은 사람을 친 사람 — 삼연타 충격 고리의 방향(가장 가까운 다른 편)
func _attacker(w, victim):
	var best = null
	var bd := INF
	for f in w.fighters:
		if f.team != victim.team and f.state == "attack":
			var dd: float = f.dist_to(victim)
			if dd < bd:
				bd = dd
				best = f
	return best


func tick_later(dt: float) -> void:
	if later_t > 0.0:
		later_t -= dt
		if later_t <= 0.0 and not later_msg.is_empty():
			hud.message(later_msg[0], later_msg[1], later_msg[2])
			later_msg = []


## 한 프레임 판정 뒤: 공격 시작 궤적 · 예고 소리 · 신호(맞음 · 쳐내기 · 막기 · 제압 · 2차 · 쓰러짐) → 연출 · 소리
func apply(d: Dictionary) -> void:
	var w = d["world"]
	for f in w.fighters:
		if f.state == "attack" and pup.has(f):
			var mv: Dictionary = f.move
			if f.t == int(mv["startup"]) + 1:
				var p: Node3D = pup[f]
				fx.swing(f, p.yaw, str(mv["hand"]) == "L")
				snd.play(str(mv["sfx"]), -4.0, randf_range(0.95, 1.05))
			if bool(mv.get("aim_line", false)) and f.t <= int(mv["startup"]) and f.t % 2 == 0:
				# 저격 조준선(헤론 — 054/032): 겨누는 동안 붉은 선이 사거리 끝까지, 쏘기 직전일수록 짙다(앞 60% 는 따라오고 뒤는 굳는다 — 그때 비킨다)
				var k := float(f.t) / maxf(1.0, float(mv["startup"]))
				fx.spike(Vector3(f.pos.x, 0, f.pos.y), pup[f].yaw, 0.7, float(mv["reach"]), 1.38, 0.05 + 0.05 * k,
					Color(1.0, 0.08, 0.05, 0.6 + 0.4 * k), 0.06)
			var tg: Array = f.telegraph()
			if not tg.is_empty() and int(tg[1]) == 6:
				snd.play("shine", -10.0 if tg[0] == "parry" else -6.0, 1.3 if tg[0] == "parry" else 0.8)
	for e in w.events:
		match e[0]:
			"hit":
				var mv2: Dictionary = e[3]
				var heavy := str(mv2["hit_sfx"]) == "hit_heavy"
				fx.hit(e[2], heavy)
				snd.play(str(mv2["hit_sfx"]), -2.0)
				var no := int(mv2.get("hit_no", 0))
				if str(mv2["shape"]) == "axe" or (heavy and str(mv2["shape"]) in SLAMS):
					cam.punch_zoom(0.88)                 # 각법 · 내려찍기 · 메치기: 내려찍힌 쪽으로 화면이 눌린다
				if no > 0:
					# 리천식 삼연타: 한 대마다 번호 · 충격 고리, 셋째는 크게
					var last := no >= int(mv2["hits"])
					var ap: Node3D = pup.get(_attacker(w, e[1]), pup.get(d["hero"]))
					fx.impact(e[2], ap.yaw, last)
					var word := "쾅!" if str(mv2["fx"]) == "amur3" else "%d%s" % [no, "!" if last else ""]    # 아무르 티그로 3연타 '쾅, 쾅, 쾅'
					fx.pop(e[2] + Vector3(0, 0.25 + no * 0.1, 0) + cam.global_basis.x * (no - 2) * 0.3, word,
						Color(1.0, 0.8, 0.45) if last else Color(1.0, 0.95, 0.8), 80 if last else 56, 0.6)
					if last:
						cam.punch_zoom(0.9)
			"skill":
				var sk: Dictionary = e[2]
				fx.pop(Vector3(e[1].pos.x, 2.95, e[1].pos.y), str(sk["name"]), Color(0.75, 0.9, 1.0), 48, 0.8)     # 머리 위 기절 · 빈틈 글자(2.22)보다 위
				snd.play("shine", -6.0, 1.0)
			"no_gauge":
				fx.pop(Vector3(e[1].pos.x, 2.35, e[1].pos.y), "게이지 부족", Color(0.75, 0.78, 0.85), 44, 0.7)
			"lethal":
				var kind_name: String = {"offbeat2": "엇엇박", "offbeat_rev": "반대발 엇박"}.get(str(e[4]), "엇박")
				fx.pop(e[2] + Vector3(0, 0.3, 0) - cam.global_basis.x * 1.4, "%s — %d%%" % [kind_name, roundi(float(e[3]) * 100.0)],   # 머리 위 '기절'(2.22)과 겹치지 않게 옆으로(rc.2 리뷰 5)
					Color(0.75, 0.9, 1.0), 72, 1.2)
				cam.punch_zoom(0.8 if str(e[4]) == "offbeat2" else 0.85)
			"brake":
				fx.strain(e[1])
				snd.play("wind", -2.0, 0.55)
				snd.play("swing", -8.0, 0.6)
				cam.punch_zoom(0.95)
			"whiff":
				fx.pop(Vector3(e[1].pos.x, 2.3, e[1].pos.y), "헛침", Color(0.72, 0.75, 0.82), 48, 0.8)
				snd.play("miss", -4.0, 0.8)
			"clash":
				# 엇박이 엇엇박에 부딪힘 — 브레이크로 박자를 흘려 엇엇박이 이긴다
				fx.spark(e[2], Color(0.7, 0.85, 1.0), 26, 6.0, 0.35)
				fx.pop(e[2] + Vector3(0, 0.6, 0), "엇엇박 — 박자를 뺏었다", Color(1.0, 0.6, 0.45), 52, 1.1)
				snd.play("guard", -2.0, 0.7)
				cam.punch_zoom(0.9)
			"self_cost":
				fx.pop(Vector3(e[1].pos.x, 1.5, e[1].pos.y) - cam.global_basis.x * 0.5, "-%d" % roundi(float(e[2])), Color(1.0, 0.47, 0.43), 52, 0.9)
			"first_offbeat":
				_msg("ch6.first_offbeat", 2.2, 1.2)   # 엇박 % · 기절 글자가 사라진 뒤(rc.2 리뷰 5)
			"learn":
				_msg("ch6.learn", 3.0, 1.2)   # '엇박 — %'(1.2초)가 사라진 뒤
				fx.pop(Vector3(e[1].pos.x, 2.7, e[1].pos.y), str(e[2]), Color(0.75, 0.9, 1.0), 44, 2.0)
				snd.play("shine", -2.0, 0.7)
				snd.play("wind", -6.0, 1.2)
			"oneshot":
				fx.pop(e[2] + Vector3(0, 0.55, 0) - cam.global_basis.x * 0.6, "한 방!", Color(1.0, 0.85, 0.5), 56, 0.8)
			"counter_catch":
				fx.parry(e[2])
				fx.pop(e[2] + Vector3(0, 0.5, 0), "카운터!", Color(1.0, 0.7, 0.4), 64, 0.9)
				snd.play("counter", -2.0, 0.9)
				cam.punch_zoom(0.9)
			"dash":
				snd.play("wind", -10.0, 1.5)
			"pierce":
				fx.pop(e[2] + Vector3(0, 0.45, 0), "가드 관통!", Color(1.0, 0.78, 0.47), 60, 0.9)
			"stun":
				fx.pop(e[2] + Vector3(0, -0.35, 0) + cam.global_basis.x * 0.6, "기절!", Color(1.0, 0.9, 0.47), 60, 1.0)   # 삼연타 번호 · 엇박 % 와 겹치지 않게 옆 아래
			"parry":
				fx.parry(e[2])
				snd.play("guard", 0.0, 1.15)
				snd.play("counter", -6.0, 1.4)
				cam.punch_zoom(0.94)
			"block":
				fx.block(e[2])
				snd.play("guard", -4.0, 0.9)
			"finish":
				fx.finish(e[2])
				snd.play("hit_heavy", 2.0, 0.8)
				snd.play("slash", -2.0)
				cam.punch_zoom(0.8)
				hud.message("제압", "", 1.0)
			"stagger":
				snd.play("fall", -4.0, 1.2)
			"crit":
				snd.play("hit_heavy", -2.0, 0.85)
				fx.pop(Vector3(e[1].pos.x, 2.55, e[1].pos.y), "부동심", Color(1.0, 0.78, 0.3), 52, 0.7)   # 크리티컬(rank_power crit_p — 2배)
			"dodge":
				snd.play("miss", -6.0)
				fx.pop(Vector3(e[1].pos.x, 2.3, e[1].pos.y), "회피", Color(0.8, 0.95, 0.85), 40, 0.5)   # 등급 회피 · 구르기(rank_power — 아랫급 공격을 비켜 낸다)
			"feint":
				snd.play("swing", -12.0, 0.7)
				if pup.has(e[1]):
					fx.feint(e[1], pup[e[1]].yaw)
			"phase2":
				if pup.has(e[1]):
					pup[e[1]].remove_glasses()
				snd.play("wind", -2.0, 0.8)
				cam.punch_zoom(0.85)
				if d.get("kind", "duel") == "duel":
					var l2: Array = Lines.at("ch6.phase2")
					var msg2 := [l2[0], l2[1], 2.4]
					if w.events.any(func(x): return x[0] == "lethal"):
						later_msg = msg2                     # 엇박 % 글자와 겹치지 않게 조금 뒤에 (run #10)
						later_t = 1.1
					else:
						hud.message(msg2[0], msg2[1], msg2[2])
			"ko":
				snd.play("ko", 0.0)
			# 11장 판(stage.gd) 신호
			"line":
				# 엇박 % · 기절 글자와 같은 순간이면 조금 뒤에(rc.2 리뷰 5 와 같은 까닭)
				var busy: bool = w.events.any(func(x): return x[0] == "lethal" or x[0] == "stun")
				var late: float = float(e[4]) if e.size() > 4 else 0.0     # 장 첫 글 뒤의 첫 방 글(stage.gd _enter)
				_line(w, str(e[1]), str(e[2]), float(e[3]), maxf(late, 1.2 if busy else 0.0))
			"bubble":
				if bubbles != null:
					bubbles.say(e[1], str(e[2]), float(e[3]), "" if e[1] != null else _speaker_name(w, str(e[4]) if e.size() > 4 else ""))
			"jump", "evade":
				snd.play("step" if e[0] == "jump" else "wind", -8.0, 1.2)
			"wall_step":
				snd.play("kick", -6.0, 1.3)
				fx.pop(Vector3(e[1].pos.x, 1.0 + e[1].air, e[1].pos.y), "탁", Color(0.95, 0.9, 0.8), 40, 0.4)
			"bubble_later":
				if bubbles != null:
					bubbles.say_later(e[1], str(e[2]), float(e[3]), float(e[4]))
			"bubble_cut":
				if bubbles != null:
					bubbles.cut_oldest()
			"prop_fx":
				_prop_fx(str(e[1]), e[2])
			"swap":
				fx.pop(Vector3(e[1].pos.x, 2.5, e[1].pos.y), "%s · %s" % [str(Lines.at("ch11.swap")), e[1].name],
					Color(0.6, 0.9, 1.0), 48, 0.9)
				snd.play("shine", -6.0, 1.2)
			"yield":
				if pup.has(e[1]):
					pup[e[1]].victory = true             # 칼을 거두고 선다
				snd.play("wind", -4.0, 0.7)
				cam.punch_zoom(0.9)


## 알림 글 — 작은 글이 '이름: 말 — 덧말' 이고 그 이름의 사람이 판에 있으면 말은 그 사람 머리 위 말풍선으로(2026-11-12 사용자
## "캐릭터들의 말과 대화는 … 말풍선으로"), 제목과 덧말은 가운데 알림. 아니면 예전처럼 가운데 알림 하나
func _line(w, title: String, small: String, secs: float, delay: float) -> void:
	var m := _quote.search(small)
	if m != null and bubbles != null:
		var who = _by_name(w, m.get_string(1).strip_edges())
		if who != null:
			hud.message(title, m.get_string(3), secs, delay)
			if delay > 0.0:
				bubbles.say_later(who, m.get_string(2), secs, delay)
			else:
				bubbles.say(who, m.get_string(2), secs)
			return
	# 제목이 사람 이름이고 작은 글이 그 사람 말이면([김신, "윤덕수, 넌 여기까지다."]) — 말풍선만
	if bubbles != null and title != "" and small != "" and not small.contains(" — "):
		var sp = _by_name(w, title)
		if sp != null:
			if delay > 0.0:
				bubbles.say_later(sp, small, secs, delay)
			else:
				bubbles.say(sp, small, secs)
			return
	hud.message(title, small, secs, delay)


func _by_name(w, nm: String):
	for f in w.fighters:
		if f.name == nm and f.alive():
			return f
	for f in w.fighters:
		if f.name == nm or (nm.length() >= 2 and f.name.ends_with(nm)):
			return f
	return null


## 내레이션 · 화면 밖 사람의 이름(말풍선 대신 띠에 적는다)
func _speaker_name(w, id: String) -> String:
	if id == "" or id == "@":
		return ""
	if id.begins_with("?:"):
		return id.substr(2).split("(")[0].strip_edges()
	for f in w.fighters:
		if f.char_id == id:
			return f.name
	return ""


## 장면 연출의 무대 일(scene.gd fx): glass — 창 · 유리 깨짐, shot — 총소리 · 섬광, smash — 소품 부서짐
func _prop_fx(kind: String, at: Vector2) -> void:
	var p := Vector3(at.x, 1.3, at.y)
	match kind:
		"shot":
			snd.play("shot", 0.0)
			fx.pop(p, "탕!", Color(1.0, 0.9, 0.5), 64, 0.5)
			cam.punch_zoom(0.96)
		"glass":
			snd.play("hit_heavy", -2.0, 1.6)
			if arena != null and arena.has_method("break_at"):
				arena.break_at(at, 1.6, Vector2(0, -1), "glass")
			fx.pop(p, "쨍그랑", Color(0.8, 0.95, 1.0), 56, 0.8)
		"smash":
			snd.play("hit_heavy", 0.0, 0.8)
			if arena != null and arena.has_method("break_at"):
				arena.break_at(at, 1.2, Vector2.ZERO, "")
