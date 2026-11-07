extends Node3D
## 3D 초안 본체 — 흐름(처음 화면 → 데모 · 판 → 결과) · 입력 · 무대 · 인형 바꿔 끼우기만 한다(S2 에서 쪼갬 — 소리 src/view/sound.gd ·
## 신호 → 연출 src/view/event_fx.gd · 대사 data/story/lines.json). 판정 · AI 는 순수 로직(src/combat/), 그림은 그 상태를 읽어서
## 그린다(src/view/) — 그림을 GLB 캐릭터로 바꿔도 판정은 그대로.
## 장(src/data/campaign.gd)마다 판 하나: duel = 6장 인천항 김신 대 백도찬(combat/duel.gd) · stage = 방을 지나는 여러 사람 판
## (combat/stage.gd + 장 표 — 11장 호텔 캐슬). 처음 화면 = 이어하기 + 장 카드(src/ui/title_menu.gd), 깬 장은 세이브(src/data/save.gd
## — user://save.json. 창 없는 실행은 --save 경로를 줄 때만 읽고 쓴다: 점검이 사람 세이브를 건드리지 않고 늘 같은 결과).
##
## 실행 인자(-- 뒤에): --autoplay 봇이 김신(끝나면 다음 시드로 다시) · --mode 장 id(ch0 · ch1 · ch6 · ch11 — 옛 이름 duel · stage 도 됨, 기본 ch6)
##   --seconds N N초(게임 시간) 뒤 결과를 찍고 끝 · --seed S · --shots 폴더:프레임,프레임 그 프레임 화면을 PNG 로
##   --touch PC 에서도 터치 버튼 · --room N stage 를 N번 방부터 · --crowd N 28층에 경호원 N명 더(성능 점검)
##   --art puppet|a|b 그림(김신 · 신겐만 — a = GLB 툰 모델(기본 · #9 결정) · b = 도트 빌보드). 처음 화면 '그림' 버튼 · 3 키로도 바꾼다
##   --save 경로 세이브 파일(창 없는 실행에서 세이브를 시험할 때 — 없으면 창 없는 실행은 세이브를 안 쓴다)
##   --safe L,T,R,B 안전 영역 여백(기준 화면 단위 — 노치 · 제스처 바 흉내) · --trace 흐름 줄(MODE · PAUSE)을 창 없이도 찍는다
##   --save-replay 경로 --seconds 로 끝날 때 마지막 판의 입력 기록을 저장 · --replay 경로 기록을 창 없이 다시 돌려 해시를 견주고 끝
##     (combat/replay.gd — 판이 끝날 때마다 user://replay_last.json 에도 남긴다: 폰에서 생긴 버그를 그대로 재현)
##   --events 프레임:동작,… 그 프레임에 동작을 흉내 — back(뒤로 버튼) · press(아무 버튼) · pause · resume(일시정지 버튼) ·
##            hide · show(앱이 내려감 · 돌아옴) · swap(교대) · art(처음 화면 그림 버튼). scripts/verify.py '흐름' · '세이브' 단계가 쓴다
## 창 없이 점검: <godot> --headless --fixed-fps 60 --path . -- --autoplay --seconds 90 [--mode stage]
## 첫 화면에서 6초 동안 아무것도 안 누르면 데모(봇) — 6장 · 11장을 번갈아. 에뮬레이터 스크린샷도 이것을 찍는다.

const Duel = preload("res://src/combat/duel.gd")
const Stage = preload("res://src/combat/stage.gd")
const Replay = preload("res://src/combat/replay.gd")
const Campaign = preload("res://src/data/campaign.gd")
const Save = preload("res://src/data/save.gd")
const Lines = preload("res://src/data/lines.gd")
const Puppet = preload("res://src/view/puppet3d.gd")
const PuppetGlb = preload("res://src/view/puppet_glb.gd")
const PuppetDot = preload("res://src/view/puppet_dot.gd")
const ART_NAMES := {"puppet": "관절 인형", "a": "A · GLB 툰 모델", "b": "B · 도트 빌보드"}
const Arena = preload("res://src/view/arena3d.gd")
const Hotel3d = preload("res://src/view/hotel3d.gd")
const Town3d = preload("res://src/view/town3d.gd")
const Haseong3d = preload("res://src/view/haseong3d.gd")
const Moves = preload("res://src/data/moves.gd")
## 장 무대 그림(campaign.gd CHAPTERS view) → 그림 클래스 — 모두 build(theme, bounds, detail) 를 갖는다(LSP)
const VIEWS := {"hotel": Hotel3d, "town": Town3d, "haseong": Haseong3d}
const Fx = preload("res://src/view/fx3d.gd")
const Cam = preload("res://src/view/camera_rig.gd")
const Sound = preload("res://src/view/sound.gd")
const EventFx = preload("res://src/view/event_fx.gd")
const Looks = preload("res://src/view/looks.gd")
const Hud = preload("res://src/ui/hud.gd")
const Touch = preload("res://src/ui/touch_ui.gd")
const Nav = preload("res://src/ui/nav.gd")
const TitleMenu = preload("res://src/ui/title_menu.gd")
const StageMenu = preload("res://src/ui/stage_menu.gd")
const SafeArea = preload("res://src/ui/safe_area.gd")

const DEMO_AFTER := 360
const SHOT_WARMUP := 3          # --shots: 찍을 프레임 바로 앞 몇 프레임만 그린다
const MINI_Y := 2.45            # 적 머리 위 작은 막대 높이(m, 몸 크기만큼 더)
const REPLAY_LAST := "user://replay_last.json"
const SAVE_PATH := "user://save.json"
const BASE_TICKS := 60          # project.godot physics_ticks_per_second — 로직 한 칸 = 1/60 초(게임 속도 ×1)

var args := {"autoplay": false, "seconds": 0.0, "seed": 1, "shots": [], "shot_dir": "", "touch": false, "trace": false,
	"events": {}, "mode": "ch6", "room": 0, "crowd": 0, "art": "", "replay": "", "save_replay": "", "save": ""}
var paused := false
var _fake_press := false
var _fake_swap := false
var _esc_hint := false
var _switch_to: Array = []                 # 메뉴로 고른 [장, 방] — mode "switch" 가 SWITCH_WAIT 프레임 뒤 판을 바꾼다
const SWITCH_WAIT := 2
const RESULT_AUTO := 600        # 이긴 결과 화면: 안 눌러도 10초 뒤 처음 화면(rc.2 폰: 2장 끝 화면이 굳은 것처럼 보였다 — 끝 방 글과 결과 글이 같아서)
var _mouse_was := false
var _fake_art := false
var headless := false
var mode := "title"
var kind := "duel"              # 지금 판 종류 (duel · stage — campaign.gd kind)
var chapter := "ch6"            # 지금 장 id
var save := {}                  # 세이브(src/data/save.gd) — save_path 가 ""이면 기억만 하고 파일은 안 쓴다
var save_path := ""
var last_win := false           # 결과 화면: 이겼으면 누르면 처음 화면(이어하기가 다음 장), 졌으면 다시
var menu: Control
var smenu: Control              # 싸움 중 메뉴 — 스테이지 고르기(src/ui/stage_menu.gd)
var menu_open := false
var menu_ch := ""               # 메뉴에서 고른 장(아래 줄 스테이지가 이 장의 것)
var run_room := 0               # 이 판을 시작한 방(0 이 아니면 — 메뉴로 중간부터 — 깬 장으로 안 친다)
var _fake_menu := ""
var demos := 0
var d: Dictionary = {}
var rec: Dictionary = {}        # 지금 판의 입력 기록(combat/replay.gd)
var seed_now := 1
var frames := 0
var fps_log_ms := 0
var mode_t := 0
var fights := 0
var results: Array = []
var pup := {}                   # Fighter → 인형
var arena: Node3D
var fx: Node3D
var cam: Camera3D
var hud: CanvasLayer
var touch: Control
var snd: Node
var evfx


func _ready() -> void:
	headless = DisplayServer.get_name() == "headless"
	process_mode = Node.PROCESS_MODE_ALWAYS        # 일시정지(get_tree().paused) 중에도 본체 · 화면 표시 · 터치는 돈다 — 무대 · 인형 · 연출 · 소리는 멈춘다
	_parse_args()
	if str(args["replay"]) != "":
		_play_replay(str(args["replay"]))
		return
	_setup_input()
	fx = Fx.new()
	fx.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(fx)
	cam = Cam.new()
	cam.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(cam)
	cam.current = true
	hud = Hud.new()
	add_child(hud)
	hud.setup()
	menu = TitleMenu.new()
	hud.root.add_child(menu)
	menu.visible = false
	touch = Touch.new()
	hud.root.add_child(touch)
	smenu = StageMenu.new()
	hud.root.add_child(smenu)                       # 터치 버튼 위에 덮는다(열리면 싸움 버튼은 숨김)
	smenu.visible = false
	touch.visible = args["touch"] or DisplayServer.is_touchscreen_available()
	snd = Sound.new()
	add_child(snd)
	snd.setup(headless)
	evfx = EventFx.new()
	evfx.fx = fx
	evfx.cam = cam
	evfx.hud = hud
	evfx.snd = snd
	evfx.pup = pup
	seed_now = int(args["seed"])
	fps_log_ms = Time.get_ticks_msec()
	_load_save()
	if args["autoplay"]:
		var ch := Campaign.from_mode(str(args["mode"]))
		_new_run(ch if ch != "" else "ch6")
		_start("demo")
	else:
		_new_run(Save.next_chapter(save))
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
				SafeArea.test_insets = Vector4(float(v[0]), float(v[1]), float(v[2]), float(v[3]))
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


func _setup_input() -> void:
	var keys := {
		"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "up": [KEY_W, KEY_UP], "down": [KEY_S, KEY_DOWN],
		"attack": [KEY_J, KEY_Z], "parry": [KEY_K, KEY_X], "roll": [KEY_SPACE, KEY_C], "dash": [KEY_L, KEY_SHIFT],
		"skill": [KEY_U, KEY_V], "skill_next": [KEY_I, KEY_B], "pause": [KEY_ESCAPE, KEY_P], "swap": [KEY_TAB, KEY_Q],
		"pick_1": [KEY_1], "pick_2": [KEY_2], "art": [KEY_3], "bench": [KEY_4], "accept": [KEY_ENTER, KEY_KP_ENTER],
		"speed": [KEY_F], "menu": [KEY_M],
	}
	for act in keys:
		if not InputMap.has_action(act):
			InputMap.add_action(act)
		for k in keys[act]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(act, ev)


# ----------------------------------------------------------------------
# 판 · 무대 · 인형
## 판 만들기 — room: 시작 방(-1 = 실행 인자 --room, 메뉴의 스테이지 고르기는 그 방 번호)
func _new_run(ch: String, room := -1) -> void:
	chapter = ch
	kind = Campaign.kind(ch)
	run_room = int(args["room"]) if room < 0 else room
	_trace("STAGE %s room=%d frame=%d" % [ch, run_room, frames])
	var opts := {}
	if kind == "stage":
		opts = {"chapter": ch, "room": run_room, "crowd": int(args["crowd"])}
		d = Stage.make(seed_now, opts)
	else:
		d = Duel.make(seed_now)
	rec = Replay.start(kind, seed_now, opts)
	hud.clear_messages()
	evfx.later_msg = []
	evfx.later_t = 0.0
	_build_stage_view()
	d["world"].events = d["world"].events.filter(func(e): return e[0] != "room")   # 첫 방은 위에서 이미 그렸다


## 무대 + 인형을 지금 판(방)에 맞게 다시 만든다 — 11장은 방을 넘을 때마다(신호 "room")
func _build_stage_view() -> void:
	if arena != null:
		arena.queue_free()
	for f in pup:
		pup[f].queue_free()
	pup.clear()
	if kind == "stage":
		arena = VIEWS[Campaign.view(chapter)].new()
		arena.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(arena)
		arena.build(str(d["room"]["theme"]), d["room"]["bounds"], not headless)
	else:
		arena = Arena.new()
		arena.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(arena)
		arena.build(not headless)
	for f in d["world"].fighters:
		var lname := _look_of(f)
		var art := str(args["art"])
		var p
		if art != "puppet" and Looks.has_art(lname):
			p = PuppetGlb.new() if art == "a" else PuppetDot.new()   # 그림 바꿔 끼우기 — 판정은 그대로(LSP)
			lname += "_" + art
		else:
			p = Puppet.new()
		p.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(p)
		p.setup(Looks.look(lname))
		p.update_from(f, 0.0, false)
		pup[f] = p
	_markers()
	var hb = d["hero"]
	var bb = d["boss"] if d["boss"] != null else hb
	cam.snap(pup[hb].position, pup[bb].position)


## 발밑 고리(11장): 조작하는 사람 하늘색 · 짝 흐린 파랑 · 아군 초록. 결투는 없음
func _markers() -> void:
	for f in pup:
		var col = null
		if kind == "stage" and f.alive():
			if f == d["hero"]:
				col = Color(0.35, 0.85, 1.0, 0.9)
			elif d["heroes"].has(f):
				col = Color(0.35, 0.55, 1.0, 0.45)
			elif d["allies"].has(f):
				col = Color(0.4, 0.9, 0.5, 0.5)
		pup[f].set_marker(col)


## 공격 버튼 글: 연타 첫 동작이 칼(베기 · 찌르기 모양)이면 '베기', 주먹 · 발이면 '치기'(0 · 1장 맨손 김신 · 11장 피우진)
func _attack_label(h) -> String:
	var combo := str(h.moveset.get("combo", ""))
	if combo == "":
		return "베기"
	var shape := str(Moves.get_move(combo)["shape"])
	return "베기" if shape.begins_with("slash") or shape.begins_with("thrust") else "치기"


## 따돌리기 방(2장 남궁혁): 남은 초를 아래 알림 줄에 — 방을 넘으면 지운다
func _escape_hint() -> void:
	var left := Stage.escape_left(d) if kind == "stage" else -1.0
	if left >= 0.0:
		hud.set_hint(str(Lines.at(d["tbl"].LINES + ".escape_hint")) % ceili(left))
		_esc_hint = true
	elif _esc_hint:
		hud.set_hint("")
		_esc_hint = false


## 교대 버튼 · 짝 막대: 지금 방에 조작하는 사람이 둘 이상인 여러 사람 판만(0 · 1장은 김신 혼자 · 2장은 방마다 한 사람)
func _can_swap() -> bool:
	return kind == "stage" and Stage.can_swap(d)


func _look_of(f) -> String:
	if kind == "duel":
		return "kim" if f == d["hero"] else "baek"
	return str(d.get("look_of", {}).get(f, d["tbl"].ROLES[f.char_id]["look"]))


func _enter_title() -> void:
	mode = "title"
	mode_t = 0
	touch.show_pause = false
	touch.show_swap = false
	touch.show_art = true
	touch.show_fight = false
	var t = Lines.at("title")
	hud.message(str(t["text"]), str(t["sub"]), 9999.0)
	_fill_menu()
	menu.visible = true
	_apply_speed()
	hud.set_hint(str(t["hint"]) + " · 그림: " + ART_NAMES[str(args["art"])])
	_trace("MODE title frame=%d" % frames)
	snd.song("boss")


func _start(m: String) -> void:
	mode = m
	mode_t = 0
	fights += 1
	touch.show_pause = m == "fight"
	touch.show_swap = m == "fight" and _can_swap()
	touch.show_art = false
	touch.show_fight = true
	menu.visible = false
	_apply_speed()
	_trace("MODE %s frame=%d" % [m, frames])      # 에뮬레이터 점검(scripts/emu_check.sh)이 logcat 에서 데모 시작을 기다린다
	if m == "demo":
		var dm: Array = Lines.at("ch6.demo")
		hud.message(dm[0], dm[1], 2.5)
		hud.set_hint(str(Lines.at("ch6.demo")[0]) + " · 누르면 직접 싸우기")
	elif kind == "duel":
		var fm: Array = Lines.at("ch6.fight")
		hud.message(fm[0], fm[1], 2.5)
		hud.set_hint("" if touch.visible else "이동 WASD · 베기 J · 쳐내기 K(누르고) · 구르기 Space · 대시 L · 기술 U · 기술 바꾸기 I · 속도 F")
	else:
		hud.set_hint("" if touch.visible else "이동 WASD · 베기 J · 쳐내기 · 막기 K · 구르기 Space · 대시 L · 기술 U · 바꾸기 I · 교대 Tab · 속도 F")
	if not snd.song_playing():
		snd.song("boss")


func _trace(line: String) -> void:
	if not headless or args["trace"]:
		print(line)


## 일시정지 — 로직(step)을 멈추고 무대 · 인형 · 연출 · 소리(PAUSABLE)를 세운다. 화면 표시 · 터치는 돈다
func _set_paused(on: bool) -> void:
	if on == paused:
		return
	paused = on
	get_tree().paused = on
	_trace("PAUSE %s frame=%d" % ["on" if on else "off", frames])
	hud.set_dim(on)
	if on:
		hud.message("일시정지", "누르면 계속 · 뒤로 버튼 = 처음 화면", 9999.0)
	else:
		hud.message("계속", "", 0.6)


## Android 뒤로 버튼(project.godot quit_on_go_back=false) · 흐름은 src/ui/nav.gd
func _back() -> void:
	match Nav.on_back(mode, paused, menu_open):
		"close_menu":
			_set_menu(false)
		"pause":
			_set_paused(true)
		"title":
			_set_paused(false)
			_new_run(Save.next_chapter(save))
			_enter_title()
		"quit":
			get_tree().quit(0)


## 앱이 내려가면(홈 · 전화 · 화면 끔) 소리를 끄고, 사람이 싸우는 중이면 멈춘다. 돌아오면 소리만 켠다(멈춤은 사람이 푼다)
func _app_hidden(hidden: bool) -> void:
	_trace("APP %s mode=%s paused=%s menu=%s screen=%s frame=%d" % ["hide" if hidden else "show", mode, paused, menu_open,
		str(get_viewport().get_visible_rect().size), frames])     # 폰 · 에뮬레이터 logcat — 화면 끄고 켠 뒤 검은 화면(rc.2) 조사
	AudioServer.set_bus_mute(0, hidden)
	if hidden and not menu_open and Nav.pause_on_hide(mode, paused):      # 메뉴가 열려 있으면 이미 멈춰 있다
		_set_paused(true)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_WM_GO_BACK_REQUEST:
			_back()
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			if not headless and args["events"].is_empty():
				_app_hidden(true)
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN:
			if not headless and args["events"].is_empty():
				_app_hidden(false)


## --events: 그 프레임의 흉내 동작
func _scripted() -> void:
	if not args["events"].has(frames):
		return
	_trace("EVENT %s frame=%d" % [args["events"][frames], frames])
	match args["events"][frames]:
		"back":
			_back()
		"press":
			_fake_press = true
		"pause":
			_set_paused(true)
		"resume":
			_set_paused(false)
		"hide":
			_app_hidden(true)
		"show":
			_app_hidden(false)
		"swap":
			_fake_swap = true
		"art":
			_fake_art = true
		"speed":
			save["speed"] = Save.next_speed(float(save["speed"]))
			_apply_speed()
		"menu":
			if mode == "fight":
				_set_menu(true)
		var act:
			if str(act).begins_with("menupick_"):           # menupick_ch11 · menupick_room3 · menupick_resume · menupick_title
				_fake_menu = str(act).substr(9)


func _pressed_anything() -> bool:
	if _fake_press:
		_fake_press = false
		return true
	return Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("roll") \
		or Input.is_action_just_pressed("parry") or not touch.take_edges().is_empty() \
		or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)


## 처음 화면 고르기 → 장 id · "bench" · ""(아직). 장 카드 · 이어하기를 누름(터치 · 마우스), 1 · 2 키 = 할 수 있는 장 차례,
## Enter · 베기 · 구르기 · 쳐내기 키 = 이어하기. 빈 곳을 누르면 아무것도 안 한다(카드를 빗맞혀 시작하지 않게)
func _title_pick() -> String:
	if Input.is_action_just_pressed("art") or touch.peek_edge("art") or _fake_art:
		_fake_art = false
		touch.take_edges()
		var order := ["puppet", "a", "b"]
		args["art"] = order[(order.find(str(args["art"])) + 1) % order.size()]
		save["art"] = args["art"]
		_write_save()
		_build_stage_view()
		hud.set_hint(str(Lines.at("title")["hint"]) + " · 그림: " + ART_NAMES[str(args["art"])])
		mode_t = 0
		return ""
	if Input.is_action_just_pressed("bench") or touch.peek_edge("bench"):
		touch.take_edges()
		return "bench"
	var ids := Campaign.playable_ids()
	for k in 2:
		if Input.is_action_just_pressed("pick_%d" % (k + 1)) and k < ids.size():
			return str(ids[k])
	var at := Vector2(-1, -1)
	var e: Dictionary = touch.take_edges()
	if e.has("tap"):
		at = touch.last_tap
	elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not _mouse_was:
		at = get_viewport().get_mouse_position()
	_mouse_was = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	if at.x >= 0.0:
		return _menu_choice(menu.hit(at))
	if _fake_press or Input.is_action_just_pressed("accept") or Input.is_action_just_pressed("attack") \
			or Input.is_action_just_pressed("roll") or Input.is_action_just_pressed("parry"):
		_fake_press = false
		return Save.next_chapter(save)
	return ""


## 누른 카드 → 시작할 장(준비 중 · 잠김이면 알림만)
func _menu_choice(id: String) -> String:
	if id == "":
		return ""
	if id == "continue":
		return Save.next_chapter(save)
	if Save.unlocked(save, id):
		return id
	var t = Lines.at("title")
	hud.message(str(Campaign.title(id)[0]), str(t["soon"] if not Campaign.playable(id) else t["locked"]), 1.6)
	hud.message(str(t["text"]), str(t["sub"]), 9999.0, 1.6)
	mode_t = 0
	return ""


func _fill_menu() -> void:
	var t = Lines.at("title")
	var nx := Save.next_chapter(save)
	menu.cont = {"id": "continue", "title": str(t["continue"]), "sub": str(Campaign.title(nx)[0])}
	menu.items = []
	for id in Campaign.ids():
		var ct = Campaign.title(id)
		var st := "open" if Save.unlocked(save, id) else ("soon" if not Campaign.playable(id) else "locked")
		var mark := ""
		if Save.cleared(save, id):
			mark = str(t["cleared"]) % int(save["cleared"][id]["count"])
		elif st != "open":
			mark = str(t[st])
		menu.items.append({"id": id, "title": str(ct[0]), "sub": str(ct[1]), "state": st, "mark": mark})
	menu.refresh()


## 세이브 읽기 — 창 없는 실행은 --save 를 줄 때만 파일(점검이 사람 세이브를 건드리지 않게)
func _load_save() -> void:
	save_path = str(args["save"]) if str(args["save"]) != "" else ("" if headless else SAVE_PATH)
	var text := ""
	if save_path != "" and FileAccess.file_exists(save_path):
		text = FileAccess.get_file_as_string(save_path)
	var p := Save.parse(text)
	save = p["save"]
	match str(p["state"]):
		"broken":
			DirAccess.rename_absolute(save_path, save_path + ".bak")       # 깨진 파일은 남겨 두고 새로
			print("SAVE broken → %s.bak" % save_path)
		"newer":
			print("SAVE newer format — read only")
			save_path = ""                                                 # 다음 판이 쓴 세이브는 덮어쓰지 않는다
	if str(args["art"]) == "":
		args["art"] = str(save["art"])
	_trace("SAVE %s art=%s cleared=%s" % [p["state"], save["art"], ",".join(save["cleared"].keys())])


## 싸움 중 메뉴(스테이지 고르기) 열기 · 닫기 — 열린 동안 판은 멈춘다(무대 · 인형 · 연출 · 소리 PAUSABLE), 싸움 버튼은 숨긴다
func _set_menu(on: bool) -> void:
	if on == menu_open:
		return
	menu_open = on
	get_tree().paused = on
	touch.take_edges()
	touch.show_fight = not on
	touch.show_pause = not on
	touch.show_swap = not on and _can_swap()
	if on:
		menu_ch = chapter
		hud.message("", "", 0.0)                    # 가운데 알림(시작 글 등)이 메뉴 카드 밑으로 비치지 않게
		_fill_stage_menu()
	smenu.visible = on
	_trace("MENU %s frame=%d" % ["on" if on else "off", frames])


func _fill_stage_menu() -> void:
	var ml = Lines.at("menu")
	smenu.heading = str(ml["heading"])
	smenu.buttons = {"resume": str(ml["resume"]), "title": str(ml["title"])}
	smenu.chapters = []
	for id in Campaign.ids():
		smenu.chapters.append({"id": id, "title": str(Campaign.title(id)[0]), "open": Save.unlocked(save, id)})
	smenu.picked = menu_ch
	var now := int(d.get("room_i", 0)) if kind == "stage" else 0
	smenu.stages = []
	for st in Campaign.stages(menu_ch):
		st["now"] = menu_ch == chapter and int(st["room"]) == now
		smenu.stages.append(st)
	smenu.refresh()


## 메뉴가 열린 동안의 입력: 카드 · 버튼 누름(터치 · 마우스), 1 · 2 키 = 첫째 · 둘째 스테이지, M · Esc = 계속, --events menupick_*
func _menu_input() -> void:
	var pick := ""
	if _fake_menu != "":
		var f := _fake_menu
		_fake_menu = ""
		pick = ("room:" + f.substr(4)) if f.begins_with("room") else ("ch:" + f if f.begins_with("ch") else f)
	elif Input.is_action_just_pressed("menu") or Input.is_action_just_pressed("pause"):
		pick = "resume"
	else:
		for k in 2:
			if Input.is_action_just_pressed("pick_%d" % (k + 1)):
				pick = "room:%d" % k
		var e: Dictionary = touch.take_edges()
		var at := Vector2(-1, -1)
		if e.has("tap"):
			at = touch.last_tap
		elif Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not _mouse_was:
			at = get_viewport().get_mouse_position()
		_mouse_was = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		if at.x >= 0.0:
			pick = smenu.hit(at)
	if pick.begins_with("ch:"):
		var id := pick.substr(3)
		if Save.unlocked(save, id):
			menu_ch = id
			_fill_stage_menu()
	elif pick.begins_with("room:"):
		# 메뉴를 닫고 판은 두 프레임 뒤에 바꾼다(mode "switch") — 처음 화면 카드처럼 멈춤이 풀린 뒤 무대 · 인형을 다시 만든다.
		# (v0.5.0-rc.1 폰: 싸움 중 메뉴로 6장 부두에 가면 화면이 굳고 터치도 안 됨 — 사용자 2026-11-06. 여기 서버에서는 재현 안 됨)
		_set_menu(false)
		_switch_to = [menu_ch, int(pick.substr(5))]
		mode = "switch"
		mode_t = 0
		touch.show_fight = false
	elif pick == "resume":
		_set_menu(false)
	elif pick == "title":
		_set_menu(false)
		_new_run(Save.next_chapter(save))
		_enter_title()


## 게임 속도: 싸우는 동안(데모 포함)만 — 물리 틱(= 로직 프레임 한 번, 판정은 60Hz 고정 한 칸)을 1초에 60 · 90 · 120 번으로 하고
## (Engine.time_scale 만으로는 틱 수가 안 늘어난다 — delta 만 커진다), time_scale 도 같이 올려 그림 · 연출 시간을 맞춘다.
## 판정 · 리플레이 · 시드 결과는 그대로(같은 로직 프레임 열 — verify '흐름'). 처음 화면 · 결과는 ×1
func _apply_speed() -> void:
	var on := mode == "fight" or mode == "demo"
	var k: float = float(save["speed"]) if on else 1.0
	Engine.physics_ticks_per_second = roundi(BASE_TICKS * k)
	Engine.time_scale = k
	touch.set_speed_label(Save.speed_label(float(save["speed"])))


func _write_save() -> void:
	if save_path == "":
		return
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f == null:
		print("SAVE error %d %s" % [FileAccess.get_open_error(), save_path])
		return
	f.store_string(Save.dump(save))
	f.close()


func _physics_process(_dt: float) -> void:
	frames += 1
	_scripted()
	if menu_open:
		_menu_input()
		_shots()
		_check_seconds()
		return
	if paused:
		# 멈춤: 아무 버튼(또는 일시정지 버튼 · Esc)이면 계속. 로직 · mode_t 는 세지 않는다(멈춘 앞뒤가 같은 판 — verify '흐름')
		var e: Dictionary = touch.take_edges()
		if not e.is_empty() or _pressed_anything() or Input.is_action_just_pressed("pause"):   # 새로 누른 것만(멈춤 버튼을 누르고 있는 손은 아님)
			_set_paused(false)
		_shots()
		_check_seconds()
		return
	if mode == "fight" and (Input.is_action_just_pressed("pause") or touch.peek_edge("pause")):
		touch.take_edges()
		_set_paused(true)
		return
	if mode == "fight" and (Input.is_action_just_pressed("menu") or touch.take_edge("menu")):
		_set_menu(true)
		return
	if mode == "fight" and (Input.is_action_just_pressed("speed") or touch.take_edge("speed")):
		save["speed"] = Save.next_speed(float(save["speed"]))
		_write_save()
		_apply_speed()
		hud.message(str(Lines.at("speed")) % Save.speed_label(float(save["speed"])), "", 0.8)
	mode_t += 1
	match mode:
		"switch":
			if mode_t >= SWITCH_WAIT:
				_new_run(str(_switch_to[0]), int(_switch_to[1]))
				_start("fight")
		"title":
			var pick := _title_pick()
			if pick == "bench":
				# 성능 점검(#9 기준 '적 30명'): 28층에 경호원 30명을 더 세우고 봇 데모 — 오른쪽 위 FPS 를 본다
				args["crowd"] = 30
				_new_run("ch11")
				args["crowd"] = 0
				_start("demo")
				hud.message("성능 점검", "28층 · 적 %d명 — 오른쪽 위 FPS" % d["enemies"].size(), 4.0)
			elif pick != "":
				_new_run(pick)
				_start("fight")
			elif mode_t > DEMO_AFTER:
				demos += 1
				var ids := Campaign.playable_ids()
				_new_run(str(ids[demos % ids.size()]))                # 데모는 할 수 있는 장을 번갈아(11장부터)
				_start("demo")
		"demo", "fight":
			if mode == "demo" and not args["autoplay"] and mode_t > 30 and (_pressed_anything() or touch.any_touch()):
				_new_run(chapter)
				_start("fight")
				return
			# 슬로모션(백도찬 첫 엇박): 로직을 두 화면에 한 번만 돌린다
			if d["world"].slowmo <= 0 or frames % 2 == 1:
				var it = null if mode == "demo" else Replay.quantize(_player_intent())   # 양자화한 입력으로 돌려야 재생이 같다
				Replay.add(rec, d, it)
				if kind == "stage":
					Stage.step(d, it)
				else:
					Duel.step(d, it)
				_after_tick()
		"result":
			if args["autoplay"] and mode_t > 300:
				seed_now += 1
				_new_run(chapter)
				_start("demo")
			elif not args["autoplay"] and mode_t > 60 and (_pressed_anything() or (last_win and mode_t > RESULT_AUTO)):
				seed_now += 1
				if last_win:
					_new_run(Save.next_chapter(save))      # 이겼으면 처음 화면 — 이어하기가 다음 장
					_enter_title()
				else:
					_new_run(chapter)
					_start("fight")
	_shots()
	if not headless and Time.get_ticks_msec() - fps_log_ms >= 10000:
		# 실제 시간 10초마다 로그(안드로이드는 logcat) — 에뮬레이터 · 실기 FPS 를 CI 가 모은다 (castle_M 보류 결정 #7 · #9).
		# frame = 지금까지 로직 프레임 수(느린 기기에서는 한 화면에 로직 4프레임까지만 돌아 게임이 느려진다)
		fps_log_ms = Time.get_ticks_msec()
		print("FPS_LOG fps=%d process_ms=%.1f frame=%d mode=%s kind=%s fighters=%d screen=%s" % [Engine.get_frames_per_second(),
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, frames, mode, chapter, d["world"].fighters.size(),
			str(get_viewport().get_visible_rect().size)])
	_check_seconds()


func _check_seconds() -> void:
	if float(args["seconds"]) > 0.0 and frames >= int(float(args["seconds"]) * 60.0):
		_finish_run()


func _player_intent() -> Dictionary:
	var mv := Input.get_vector("left", "right", "up", "down")
	if touch.stick.length() > 0.12:
		mv = touch.stick.limit_length(1.0)
	var e: Dictionary = touch.take_edges()
	var h = d["hero"]
	var tg = h.target()
	var swap := Input.is_action_just_pressed("swap") or e.has("swap") or _fake_swap
	_fake_swap = false
	return {
		"move": mv, "face": h.dir_to(tg) if tg != null else Vector2.ZERO,
		"attack": Input.is_action_just_pressed("attack") or e.has("attack"),
		"parry": Input.is_action_just_pressed("parry") or e.has("parry"),
		"parry_held": Input.is_action_pressed("parry") or touch.held("parry"),
		"roll": Input.is_action_just_pressed("roll") or e.has("roll"),
		"dash": Input.is_action_just_pressed("dash") or e.has("dash"),
		"skill": Input.is_action_just_pressed("skill") or e.has("skill"),
		"skill_next": Input.is_action_just_pressed("skill_next") or e.has("skill_next"),
		"swap": swap,
	}


## 한 프레임 판정 뒤: 방이 바뀌었으면 무대 · 인형을 다시 만들고, 신호를 연출 · 소리로(event_fx.gd), 판이 끝났으면 결과
func _after_tick() -> void:
	var w = d["world"]
	if w.events.any(func(e): return e[0] == "room"):
		_build_stage_view()
		touch.show_swap = mode == "fight" and _can_swap()     # 2장: 방마다 조작 인물이 바뀐다
	var swapped: bool = w.events.any(func(e): return e[0] == "swap" or e[0] == "ko")
	evfx.apply(d)
	w.events.clear()
	if swapped:
		_markers()
	if w.over != "":
		_end_fight(w.over)


func _end_fight(result: String) -> void:
	var played := mode == "fight"                       # 데모(봇)가 이긴 판은 세이브에 안 넣는다
	mode = "result"
	mode_t = 0
	_apply_speed()
	_save_replay(REPLAY_LAST)
	touch.show_swap = false
	touch.show_fight = false                            # 결과 화면은 싸움 버튼 없이 — 아무 데나 누르면 다음(버튼을 눌러도 같다)
	touch.show_pause = false
	results.append(_summary())
	var key: String = "ch6" if kind == "duel" else str(d["tbl"].LINES)
	last_win = result == "win" and played
	if last_win and run_room == 0:                     # 메뉴로 중간 스테이지부터 한 판은 깬 장으로 안 친다
		Save.record_clear(save, chapter, int(d["world"].frame))
		_write_save()
	if result == "win":
		if pup.has(d["hero"]):
			pup[d["hero"]].victory = true
		var wm = Lines.at("ch6.win")
		if kind == "stage":                             # 끝 방 글은 끝 방에서 이미 보였다 — 결과는 '깸' + 다음(같은 글이면 굳은 것처럼 보였다, rc.2)
			wm = [str(Lines.at("result")["win_title"]) % str(Campaign.title(chapter)[0]),
				str(Lines.at("result")["win_next"]) % str(Campaign.title(Save.next_chapter(save))[0])]
		hud.message(str(wm[0]), str(wm[1]), 9999.0)
		snd.song("victory", false)
	else:
		if d["boss"] != null and pup.has(d["boss"]):
			pup[d["boss"]].victory = true
		var lm: Array = d["lose_line"] if d.get("lose_line", []).size() >= 2 else Lines.at(key + ".lose")   # 따돌리기 시간 초과는 따로
		hud.message(lm[0], lm[1], 9999.0)
		snd.song("gameover", false)
	var rl = Lines.at("result")
	if args["autoplay"]:
		hud.set_hint("")
	elif last_win:
		hud.set_hint(str(rl["win_next"]) % str(Campaign.title(Save.next_chapter(save))[0]))
	else:
		hud.set_hint(str(rl["lose"]))


func _summary() -> Dictionary:
	return Stage.summary(d, d["world"].frame) if kind == "stage" else Duel.summary(d, d["world"].frame)


func _process(dt: float) -> void:
	if d.is_empty():
		return
	var partner = Stage.partner(d) if kind == "stage" else null
	var phase: int = d["boss"].phase if d["boss"] != null else 1
	if paused or menu_open:
		hud.update_bars(d["hero"], d["boss"], phase, 0.0, partner)     # 접기 · 펴기에 자리만 다시 잡는다
		return
	evfx.tick_later(dt)
	var frozen: bool = d["world"].hitstop > 0 and (mode == "fight" or mode == "demo")
	for f in pup:
		pup[f].update_from(f, dt, frozen)
	touch.set_label("attack", _attack_label(d["hero"]))
	var hp: Vector3 = pup[d["hero"]].position
	if kind == "stage":
		var pts: Array = []
		for f in pup:
			if f.alive() and not f.inert:
				pts.append(pup[f].position)
		cam.follow_group(hp, pts, dt, d["world"].shake)
	else:
		cam.follow(hp, pup[d["boss"]].position, dt, d["world"].shake)
	hud.update_bars(d["hero"], d["boss"], phase, dt, partner)
	_escape_hint()
	var minis: Array = []
	if kind == "stage":
		for e in d["enemies"]:
			if e.alive() and not e.inert and e != d["boss"] and pup.has(e):
				var at: Vector3 = pup[e].position + Vector3(0, MINI_Y, 0)
				if not cam.is_position_behind(at):
					minis.append([cam.unproject_position(at), e.hp / e.hp_max, Color(0.86, 0.3, 0.26)])
		for a in d["allies"]:
			if a.alive() and pup.has(a):
				minis.append([cam.unproject_position(pup[a].position + Vector3(0, MINI_Y, 0)), a.hp / a.hp_max,
					Color(0.4, 0.8, 0.5)])
	hud.set_minibars(minis)


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
	if str(args["save_replay"]) != "":
		_save_replay(str(args["save_replay"]))
	results.append(_summary())
	var wins := 0
	for r in results:
		if r["over"] == "win":
			wins += 1
	# draws = 화면 프레임 수(게임 속도 ×1.5 · ×2 면 같은 로직 프레임에 화면이 덜 돈다 — verify '흐름' 이 본다)
	print("RESULT ", JSON.stringify({"frames": frames, "fights": fights, "wins": wins, "last": results[-1],
		"draws": Engine.get_process_frames()}))
	set_physics_process(false)
	get_tree().quit(0)


func _save_replay(path: String) -> void:
	if rec.is_empty() or (rec["hash"] != 0 and path == REPLAY_LAST):
		return                                     # 이미 끝낸 기록(결과 화면에서 다시 부름)
	Replay.finish(rec, d)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		print("REPLAY_SAVE error %d %s" % [FileAccess.get_open_error(), path])
		return
	f.store_string(JSON.stringify(rec))
	f.close()
	print("REPLAY_SAVE %s frames=%d hash=%d" % [path, rec["inputs"].size(), rec["hash"]])


## --replay: 기록을 다시 돌려 끝 · 중간 해시를 견준다 → REPLAY ok=… 줄을 찍고 끝(같으면 0, 다르면 1)
func _play_replay(path: String) -> void:
	set_physics_process(false)
	set_process(false)
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	var out := {"ok": false, "error": "기록을 못 읽음 " + path, "frames": 0, "hash": 0}
	if data is Dictionary:
		out = Replay.play(data)
	print("REPLAY ok=%s frames=%d hash=%d %s" % [str(out["ok"]), out["frames"], out["hash"], out["error"]])
	get_tree().quit(0 if out["ok"] else 1)
