extends Node3D
## 3D 초안 본체 — 무대 · 두 인형 · 카메라 · 화면 표시 · 터치 · 소리를 만들고 60프레임 고정으로 결투(combat/duel.gd)를 돌린다.
## 판정 · AI 는 순수 로직(src/combat/), 그림은 그 상태를 읽어서 그린다(src/view/) — 그림을 GLB 캐릭터로 바꿔도 판정은 그대로.
##
## 실행 인자(-- 뒤에): --autoplay 봇이 김신(끝나면 다음 시드로 다시) · --seconds N N초(게임 시간) 뒤 결과를 찍고 끝
##   --seed S · --shots 폴더:프레임,프레임 그 프레임 화면을 PNG 로 · --touch PC 에서도 터치 버튼
## 창 없이 점검: <godot> --headless --fixed-fps 60 --path . -- --autoplay --seconds 90
## 첫 화면에서 6초 동안 아무것도 안 누르면 데모(봇 대 백도찬) — 에뮬레이터 스크린샷도 이것을 찍는다.

const Duel = preload("res://src/combat/duel.gd")
const Puppet = preload("res://src/view/puppet3d.gd")
const Arena = preload("res://src/view/arena3d.gd")
const Fx = preload("res://src/view/fx3d.gd")
const Cam = preload("res://src/view/camera_rig.gd")
const Hud = preload("res://src/ui/hud.gd")
const Touch = preload("res://src/ui/touch_ui.gd")

# 외형: castle_M `castle_m/data/looks.py` 의 kimshin · 백도찬 색을 3D 조명에 맞게 조금 밝힘(검정이 밤에 묻히지 않게)
const LOOKS := {
	"kim": {"suit": Color(0.16, 0.16, 0.2), "pants": Color(0.13, 0.13, 0.17), "shirt": Color(0.93, 0.93, 0.94),
		"tie": Color(0.09, 0.09, 0.12), "skin": Color(0.91, 0.77, 0.65), "hair": Color(0.11, 0.11, 0.15),
		"hair_style": "short", "glasses": false, "big": false, "weapon_r": "gerber", "weapon_l": "gerber",
		"guard": "kim"},
	"baek": {"suit": Color(0.23, 0.23, 0.27), "pants": Color(0.19, 0.19, 0.23), "shirt": Color(0.9, 0.9, 0.93),
		"tie": Color(0.17, 0.17, 0.22), "skin": Color(0.89, 0.75, 0.63), "hair": Color(0.1, 0.1, 0.12),
		"hair_style": "parted", "glasses": true, "big": true, "weapon_r": "sashimi", "weapon_l": "",
		"guard": "baek"},
}
const SFX := ["knife", "swing", "slash", "hit", "hit_heavy", "kick", "guard", "counter", "miss", "ko", "wind", "step",
	"shine", "fall"]
const DEMO_AFTER := 360
const SHOT_WARMUP := 3          # --shots: 찍을 프레임 바로 앞 몇 프레임만 그린다

var args := {"autoplay": false, "seconds": 0.0, "seed": 1, "shots": [], "shot_dir": "", "touch": false}
var headless := false
var mode := "title"
var d: Dictionary = {}
var seed_now := 1
var frames := 0
var fps_log_ms := 0
var mode_t := 0
var fights := 0
var results: Array = []
var hero_p: Node3D
var boss_p: Node3D
var arena: Node3D
var fx: Node3D
var cam: Camera3D
var hud: CanvasLayer
var touch: Control
var sfx := {}
var players: Array = []
var music: AudioStreamPlayer


func _ready() -> void:
	headless = DisplayServer.get_name() == "headless"
	_parse_args()
	_setup_input()
	arena = Arena.new()
	add_child(arena)
	arena.build(not headless)
	fx = Fx.new()
	add_child(fx)
	cam = Cam.new()
	add_child(cam)
	cam.current = true
	hud = Hud.new()
	add_child(hud)
	hud.setup()
	touch = Touch.new()
	hud.root.add_child(touch)
	touch.visible = args["touch"] or DisplayServer.is_touchscreen_available()
	_setup_audio()
	seed_now = int(args["seed"])
	fps_log_ms = Time.get_ticks_msec()
	_new_duel()
	if args["autoplay"]:
		_start("demo")
	else:
		_enter_title()


func _parse_args() -> void:
	var a := OS.get_cmdline_user_args()
	var i := 0
	while i < a.size():
		match a[i]:
			"--autoplay":
				args["autoplay"] = true
			"--touch":
				args["touch"] = true
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


func _setup_input() -> void:
	var keys := {
		"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN],
		"attack": [KEY_J, KEY_Z], "parry": [KEY_K, KEY_X], "roll": [KEY_SPACE, KEY_L, KEY_C],
		"skill": [KEY_U, KEY_V], "skill_next": [KEY_I, KEY_B],
	}
	for act in keys:
		if not InputMap.has_action(act):
			InputMap.add_action(act)
		for k in keys[act]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(act, ev)


func _setup_audio() -> void:
	for n in SFX:
		sfx[n] = load("res://assets/sfx/%s.wav" % n)
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	music = AudioStreamPlayer.new()
	music.volume_db = -9.0
	add_child(music)


func _play(n: String, db := 0.0, pitch := 1.0) -> void:
	if headless or not sfx.has(n):
		return                                   # 창 없는 점검에서는 소리를 내지 않는다 (가짜 오디오가 끝날 때 재생 객체를 붙잡는다)
	for p in players:
		if not p.playing:
			p.stream = sfx[n]
			p.volume_db = db
			p.pitch_scale = pitch
			p.play()
			return


func _music(n: String, loop := true) -> void:
	if headless:
		return
	var s = load("res://assets/music/%s.ogg" % n)
	s.loop = loop
	music.stream = s
	music.play()


func _new_duel() -> void:
	if hero_p != null:
		hero_p.queue_free()
		boss_p.queue_free()
	d = Duel.make(seed_now)
	hero_p = Puppet.new()
	add_child(hero_p)
	hero_p.setup(LOOKS["kim"])
	boss_p = Puppet.new()
	add_child(boss_p)
	boss_p.setup(LOOKS["baek"])
	hero_p.update_from(d["hero"], 0.0, false)
	boss_p.update_from(d["boss"], 0.0, false)
	cam.snap(hero_p.position, boss_p.position)


func _enter_title() -> void:
	mode = "title"
	mode_t = 0
	hud.message("캐슬 M · 3D 초안", "인천항 제3부두. 백도찬, 기다려라.", 9999.0)
	hud.set_hint("화면을 누르면 시작 · 가만히 두면 데모")
	_music("boss")


func _start(m: String) -> void:
	mode = m
	mode_t = 0
	fights += 1
	if not headless:
		print("MODE %s frame=%d" % [m, frames])    # 에뮬레이터 점검(scripts/emu_check.sh)이 logcat 에서 데모 시작을 기다린다
	if m == "demo":
		hud.message("데모", "봇이 예고만 보고 싸운다 — 누르면 직접", 2.5)
		hud.set_hint("데모 · 누르면 직접 싸우기")
	else:
		hud.message("결투", "흰 ! = 쳐내기 · 빨간 ! = 구르기 · 빈틈 = 베기", 2.5)
		hud.set_hint("" if touch.visible else "이동 WASD · 베기 J · 쳐내기 K(누르고) · 구르기 Space · 기술 U · 기술 바꾸기 I")
	if not music.playing:
		_music("boss")


func _pressed_anything() -> bool:
	return Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("roll") \
		or Input.is_action_just_pressed("parry") or not touch.take_edges().is_empty() \
		or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)


func _physics_process(_dt: float) -> void:
	frames += 1
	mode_t += 1
	match mode:
		"title":
			if _pressed_anything():
				_start("fight")
			elif mode_t > DEMO_AFTER:
				_start("demo")
		"demo", "fight":
			if mode == "demo" and not args["autoplay"] and mode_t > 30 and (_pressed_anything() or touch.any_touch()):
				_new_duel()
				_start("fight")
				return
			var hero_it = null if mode == "demo" else _player_intent()
			Duel.step(d, hero_it)
			_after_tick()
		"result":
			if mode_t > 300 or (mode_t > 60 and not args["autoplay"] and _pressed_anything()):
				seed_now += 1
				_new_duel()
				_start("demo" if args["autoplay"] else "fight")
	_shots()
	if not headless and Time.get_ticks_msec() - fps_log_ms >= 10000:
		# 실제 시간 10초마다 로그(안드로이드는 logcat) — 에뮬레이터 · 실기 FPS 를 CI 가 모은다 (castle_M 보류 결정 #7 · #9).
		# frame = 지금까지 로직 프레임 수(느린 기기에서는 한 화면에 로직 4프레임까지만 돌아 게임이 느려진다)
		fps_log_ms = Time.get_ticks_msec()
		print("FPS_LOG fps=%d process_ms=%.1f frame=%d mode=%s screen=%s" % [Engine.get_frames_per_second(),
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, frames, mode,
			str(get_viewport().get_visible_rect().size)])
	if float(args["seconds"]) > 0.0 and frames >= int(float(args["seconds"]) * 60.0):
		_finish_run()


func _player_intent() -> Dictionary:
	var mv := Input.get_vector("left", "right", "up", "down")
	if touch.stick.length() > 0.12:
		mv = touch.stick.limit_length(1.0)
	var e: Dictionary = touch.take_edges()
	return {
		"move": mv, "face": d["hero"].dir_to(d["boss"]),
		"attack": Input.is_action_just_pressed("attack") or e.has("attack"),
		"parry": Input.is_action_just_pressed("parry") or e.has("parry"),
		"parry_held": Input.is_action_pressed("parry") or touch.held("parry"),
		"roll": Input.is_action_just_pressed("roll") or e.has("roll"),
		"skill": Input.is_action_just_pressed("skill") or e.has("skill"),
		"skill_next": Input.is_action_just_pressed("skill_next") or e.has("skill_next"),
	}


## 한 프레임 판정 뒤: 공격 시작 궤적 · 예고 소리 · 신호(맞음 · 쳐내기 · 막기 · 제압 · 2차 · 쓰러짐) → 연출 · 소리
func _after_tick() -> void:
	var w = d["world"]
	for f in [d["hero"], d["boss"]]:
		if f.state == "attack":
			var mv: Dictionary = f.move
			if f.t == int(mv["startup"]) + 1:
				var p: Node3D = hero_p if f == d["hero"] else boss_p
				fx.swing(f, p.yaw, str(mv["hand"]) == "L")
				_play(str(mv["sfx"]), -4.0, randf_range(0.95, 1.05))
			var tg: Array = f.telegraph()
			if not tg.is_empty() and int(tg[1]) == 6:
				_play("shine", -10.0 if tg[0] == "parry" else -6.0, 1.3 if tg[0] == "parry" else 0.8)
	for e in w.events:
		match e[0]:
			"hit":
				var mv2: Dictionary = e[3]
				var heavy := str(mv2["hit_sfx"]) == "hit_heavy"
				fx.hit(e[2], heavy)
				_play(str(mv2["hit_sfx"]), -2.0)
				var no := int(mv2.get("hit_no", 0))
				if no > 0:
					# 리천식 삼연타: 한 대마다 번호, 셋째는 크게
					var last := no >= int(mv2["hits"])
					fx.pop(e[2] + Vector3(0, 0.25 + no * 0.1, 0) + cam.global_basis.x * (no - 2) * 0.3, "%d%s" % [no, "!" if last else ""],
						Color(1.0, 0.8, 0.45) if last else Color(1.0, 0.95, 0.8), 80 if last else 56, 0.6)
					if last:
						cam.punch_zoom(0.9)
			"skill":
				var sk: Dictionary = e[2]
				fx.pop(Vector3(e[1].pos.x, 2.5, e[1].pos.y), str(sk["name"]), Color(0.75, 0.9, 1.0), 48, 0.8)
				_play("shine", -6.0, 1.0)
			"no_gauge":
				fx.pop(Vector3(e[1].pos.x, 2.35, e[1].pos.y), "게이지 부족", Color(0.75, 0.78, 0.85), 44, 0.7)
			"lethal":
				fx.pop(e[2] + Vector3(0, 0.75, 0), "엇박 — %d%%" % roundi(float(e[3]) * 100.0), Color(0.75, 0.9, 1.0), 72, 1.2)
				cam.punch_zoom(0.85)
			"pierce":
				fx.pop(e[2] + Vector3(0, 0.45, 0), "가드 관통!", Color(1.0, 0.78, 0.47), 60, 0.9)
			"stun":
				fx.pop(e[2] + Vector3(0, 0.6, 0), "기절!", Color(1.0, 0.9, 0.47), 72, 1.0)
			"parry":
				fx.parry(e[2])
				_play("guard", 0.0, 1.15)
				_play("counter", -6.0, 1.4)
				cam.punch_zoom(0.94)
			"block":
				fx.block(e[2])
				_play("guard", -4.0, 0.9)
			"finish":
				fx.finish(e[2])
				_play("hit_heavy", 2.0, 0.8)
				_play("slash", -2.0)
				cam.punch_zoom(0.8)
				hud.message("제압", "", 1.0)
			"stagger":
				_play("fall", -4.0, 1.2)
			"dodge":
				_play("miss", -6.0)
			"feint":
				_play("swing", -12.0, 0.7)
				fx.feint(e[1], (hero_p if e[1] == d["hero"] else boss_p).yaw)
			"phase2":
				boss_p.remove_glasses()
				_play("wind", -2.0, 0.8)
				cam.punch_zoom(0.85)
				hud.message("안경을 벗는다", "백도찬 2차 · 전력 — 엇박이 섞인다", 2.4)
			"ko":
				_play("ko", 0.0)
	w.events.clear()
	if w.over != "":
		_end_fight(w.over)


func _end_fight(result: String) -> void:
	mode = "result"
	mode_t = 0
	results.append(Duel.summary(d, d["world"].frame))
	if result == "win":
		hero_p.victory = true
		hud.message("승리", "백도찬을 쓰러뜨렸다", 9999.0)
		_music("victory", false)
	else:
		boss_p.victory = true
		hud.message("패배", "다시 — 흰 ! 가 커지며 깜빡일 때 쳐내기", 9999.0)
		_music("gameover", false)
	hud.set_hint("" if args["autoplay"] else "누르면 다시")


func _process(dt: float) -> void:
	if d.is_empty():
		return
	var frozen: bool = d["world"].hitstop > 0 and (mode == "fight" or mode == "demo")
	hero_p.update_from(d["hero"], dt, frozen)
	boss_p.update_from(d["boss"], dt, frozen)
	cam.follow(hero_p.position, boss_p.position, dt, d["world"].shake)
	hud.update_bars(d["hero"], d["boss"], d["world"].phase, dt)


func _shots() -> void:
	if headless or args["shots"].is_empty():
		return
	# 찍을 프레임 바로 앞 몇 프레임만 그리고 나머지는 로직만 돌린다 — CI 가상 화면(소프트웨어 OpenGL)은 한 장 그리는 데
	# 약 0.44초라 전부 그리면 30분이 넘는다(run #1). 불꽃은 CPUParticles3D(로직 쪽에서 움직임)라 그대로 찍힌다
	var near := false
	for s in args["shots"]:
		if frames >= s - SHOT_WARMUP and frames < s:
			near = true
	RenderingServer.render_loop_enabled = near
	if frames in args["shots"]:
		var dir: String = args["shot_dir"]
		DirAccess.make_dir_recursive_absolute(dir)
		var img := get_viewport().get_texture().get_image()
		var path := "%s/shot_%05d.png" % [dir, frames]
		var err := img.save_png(path)
		print("SHOT %s %s" % [path, "ok" if err == OK else "error %d" % err])


func _finish_run() -> void:
	results.append(Duel.summary(d, d["world"].frame))
	var wins := 0
	for r in results:
		if r["over"] == "win":
			wins += 1
	print("RESULT ", JSON.stringify({"frames": frames, "fights": fights, "wins": wins, "last": results[-1]}))
	set_physics_process(false)
	get_tree().quit(0)
