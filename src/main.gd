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
##   --touch PC 에서도 터치 버튼 · --room N stage 를 N번 방부터 · --crowd N 11장 첫 방에 경호원 N명 더(성능 점검)
##   --art puppet|a|b 그림(a = GLB 모델(기본 · #9 결정) · b = 도트 빌보드 — 개발만). 처음 화면 '그림' 버튼 · 3 키는 a ↔ puppet(Save.ARTS)
##   --save 경로 세이브 파일(창 없는 실행에서 세이브를 시험할 때 — 없으면 창 없는 실행은 세이브를 안 쓴다)
##   --safe L,T,R,B 안전 영역 여백(기준 화면 단위 — 노치 · 제스처 바 흉내) · --trace 흐름 줄(MODE · PAUSE)을 창 없이도 찍는다
##   --save-replay 경로 --seconds 로 끝날 때 마지막 판의 입력 기록을 저장 · --replay 경로 기록을 창 없이 다시 돌려 해시를 견주고 끝
##     (combat/replay.gd — 판이 끝날 때마다 user://replay_last.json 에도 남긴다: 폰에서 생긴 버그를 그대로 재현)
##   --events 프레임:동작,… 그 프레임에 동작을 흉내 — back(뒤로 버튼) · press(아무 버튼) · ff(장면 빨리 감기) · pause · resume(일시정지 버튼) ·
##            hide · show(앱이 내려감 · 돌아옴) · swap(교대) · art(처음 화면 그림 버튼). scripts/verify.py '흐름' · '세이브' 단계가 쓴다
## 창 없이 점검: <godot> --headless --fixed-fps 60 --path . -- --autoplay --seconds 90 [--mode stage]
## 첫 화면에서 6초 동안 아무것도 안 누르면 데모(봇) — 6장 · 11장을 번갈아. 에뮬레이터 스크린샷도 이것을 찍는다.

const Scene = preload("res://src/combat/scene.gd")
const Duel = preload("res://src/combat/duel.gd")
const Stage = preload("res://src/combat/stage.gd")
const Replay = preload("res://src/combat/replay.gd")
const Difficulty = preload("res://src/data/difficulty.gd")
const Launch = preload("res://src/launch.gd")
const Campaign = preload("res://src/data/campaign.gd")
const Save = preload("res://src/data/save.gd")
const Lines = preload("res://src/data/lines.gd")
const Puppet = preload("res://src/view/puppet3d.gd")
const PuppetGlb = preload("res://src/view/puppet_glb.gd")
const PuppetDot = preload("res://src/view/puppet_dot.gd")
const ART_NAMES := {"puppet": "관절 인형", "a": "A · 붓칠 먹선 모델", "b": "B · 도트 빌보드(개발)"}
const Arena = preload("res://src/view/arena3d.gd")
const Ink = preload("res://src/view/ink.gd")                 # 붓칠 · 먹선 화풍(2026-11-11 — 무대 재질 · 화면 마무리)
const Hotel3d = preload("res://src/view/hotel3d.gd")
const Town3d = preload("res://src/view/town3d.gd")
const Haseong3d = preload("res://src/view/haseong3d.gd")
const World3d = preload("res://src/view/world3d.gd")
const Moves = preload("res://src/data/moves.gd")
const Common = preload("res://src/data/common.gd")
## 장 무대 그림(campaign.gd CHAPTERS view) → 그림 클래스 — 모두 build(theme, bounds, detail) 를 갖는다(LSP)
const VIEWS := {"hotel": Hotel3d, "town": Town3d, "haseong": Haseong3d, "world": World3d}
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
const Bubbles = preload("res://src/ui/bubbles.gd")

const DEMO_AFTER := 360
const SHOT_WARMUP := 3          # --shots: 찍을 프레임 바로 앞 몇 프레임만 그린다
const MINI_Y := 2.45            # 적 머리 위 작은 막대 높이(m, 몸 크기만큼 더)
const REPLAY_LAST := "user://replay_last.json"
const SAVE_PATH := "user://save.json"
const BASE_TICKS := 60          # project.godot physics_ticks_per_second — 로직 한 칸 = 1/60 초(게임 속도 ×1)
const FF_SPEED := 3.0           # 장면 빨리 감기 속도(오른쪽 위 버튼 — _set_ff)

var args := Launch.defaults()
var paused := false
var _fake_press := false
var _fake_swap := false
var _esc_hint := false
var _faded := false                     # 방 끝 연출(stage fade)로 화면을 어둡게 했다
var _gone_t := {}                          # 쓰러진 적 → 쓰러져 있던 초(GONE_SECS 뒤 인형을 숨긴다)
const GONE_SECS := 4.0
var _logic_ticks := 0                      # 로직(Stage · Duel.step)이 돈 수 — 멈춤 지킴이(_watch_stall)
var _stall_seen := 0
var _stall_ms := 0                          # 마지막으로 돈 것을 본 실제 시각(ms)
var _stall_hits := 0                        # 잇따른 멈춤 수(두 번째면 판을 새로)
var _stall_last := 0
const STALL_SECS := 1.5
const STALL_FORGET_MS := 8000                # 이만큼 잘 돌면 멈춤 수를 잊는다
var _switch_to: Array = []                 # 메뉴로 고른 [장, 방] — mode "switch" 가 SWITCH_WAIT 프레임 뒤 판을 바꾼다
const SWITCH_WAIT := 2
const RESULT_AUTO := 600        # 이긴 결과 화면: 안 눌러도 10초 뒤 처음 화면(rc.2 폰: 2장 끝 화면이 굳은 것처럼 보였다 — 끝 방 글과 결과 글이 같아서)
var _mouse_was := false
var _fake_art := false
var _fake_difficulty := false
var _dev_win := false              # --events N:autowin — 그 뒤 싸움마다 적을 바로 쓰러뜨린다(verify '장 차례' — 0 ~ 13장을 깨며 다음 장이 열리나)
var _menu_diff0 := ""             # 싸움 중 메뉴를 열 때의 난이도 — 바뀌었으면 닫을 때 지금 스테이지를 다시
var headless := false
const LOD_CROWD := 16            # 인형이 이보다 많으면 화면 밖 인형은 자세를 덜 자주(_process)
const LOD_EVERY := 3
var _lod_tick := 0
var _lod_dt := {}
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
var run_room := 0               # 이 판을 시작한 방(0 이 아니면 — 메뉴로 중간부터 — 가장 짧은 판에 안 넣는다)
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
var bubbles: Control                       # 말풍선(src/ui/bubbles.gd — HUD 밑 칸, 터치 버튼 아래)
var _tossed: Array = []                    # 장면에서 날아가는 인형 [인형, 처음, 끝, 지난 초, 초](scene.gd toss)
var _in_scene := false
var _ff := false                 # 장면 빨리 감기 켜짐(_set_ff)
var _cam_last := Vector3.ZERO
var touch: Control
var snd: Node
var evfx


func _ready() -> void:
	headless = DisplayServer.get_name() == "headless"
	process_mode = Node.PROCESS_MODE_ALWAYS        # 일시정지(get_tree().paused) 중에도 본체 · 화면 표시 · 터치는 돈다 — 무대 · 인형 · 연출 · 소리는 멈춘다
	args = Launch.parse(OS.get_cmdline_user_args())
	if args.has("safe"):
		SafeArea.test_insets = args["safe"]
	if str(args["replay"]) != "":
		_play_replay(str(args["replay"]))
		return
	Launch.setup_input()
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
	if not headless:
		add_child(Ink.grade_layer())                # 3D 위 · HUD 밑 화면 마무리(채도 · 대비 · 비네트)
	bubbles = Bubbles.new()
	hud.root.add_child(bubbles)
	hud.root.move_child(bubbles, 2)                 # 덮개 · 작은 막대 위, 글자 · 메뉴 · 터치 아래
	bubbles.anchor_fn = _bubble_anchor
	menu = TitleMenu.new()
	hud.hint_y_fn = func() -> float: return menu.hint_y()
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
	evfx.bubbles = bubbles
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


# ----------------------------------------------------------------------
# 판 · 무대 · 인형
## 판 만들기 — room: 시작 방(-1 = 실행 인자 --room, 메뉴의 스테이지 고르기는 그 방 번호)
func _new_run(ch: String, room := -1) -> void:
	chapter = ch
	kind = Campaign.kind(ch)
	run_room = int(args["room"]) if room < 0 else room
	_trace("STAGE %s room=%d frame=%d" % [ch, run_room, frames])
	var opts := {"difficulty": str(save["difficulty"])}         # 난이도는 판 · 리플레이 기록에 같이(src/data/difficulty.gd)
	if kind == "stage":
		opts.merge({"chapter": ch, "room": run_room, "crowd": int(args["crowd"]), "talk": not headless})   # 원작 대사 장면(창 없는 점검은 건너뜀)
		d = Stage.make(seed_now, opts)
	else:
		d = Duel.make(seed_now, opts)
	rec = Replay.start(kind, seed_now, opts)
	hud.clear_messages()
	bubbles.clear()
	_set_scene(false)
	_undim()
	evfx.later_msg = []
	evfx.later_t = 0.0
	_build_stage_view()
	d["world"].events = d["world"].events.filter(func(e): return e[0] != "room")   # 첫 방은 위에서 이미 그렸다


## 부서지는 소품(2026-11-12 사용자 "싸우면서 주변 물건들도 박살나는 연출"): 맞고 날아가는 · 넘어지는 사람이 소품에 닿으면 무대가 부순다
## (src/view/breakables.gd — 그림만)
const SMASH_SPEED := 1.1          # 넉백 빠르기(m/초) 이상일 때만
func _smash_props(w) -> void:
	if arena == null or not arena.has_method("break_hit"):
		return
	for f in w.fighters:
		var flying: bool = f.vel.length() > SMASH_SPEED and f.state in ["hitstun", "recoil", "stagger", "down", "dead", "stun"]
		var fell: bool = (f.state == "down" or f.state == "dead") and f.t < 4
		if not (flying or fell):
			continue
		var dir: Vector2 = f.vel.normalized() if f.vel.length() > 0.01 else -f.facing
		if arena.break_hit(f.pos, dir):
			snd.play("hit_heavy", -3.0, randf_range(0.7, 0.9))
			cam.punch_zoom(0.97)


## 말풍선 자리: 그 사람 인형 머리 위(화면 좌표) — 인형이 없거나 카메라 뒤 · 화면 밖이면 [false, ..](띠로 그린다)
func _bubble_anchor(who) -> Array:
	if who == null or not pup.has(who) or cam == null:
		return [false, Vector2.ZERO]
	var p: Node3D = pup[who]
	var head: Vector3 = p.global_position + Vector3(0, float(p.tele_y) - 0.15, 0)
	if cam.is_position_behind(head):
		return [false, Vector2.ZERO]
	var sp: Vector2 = cam.unproject_position(head)
	var vr := get_viewport().get_visible_rect()
	if not vr.grow(-8.0).has_point(sp):
		return [false, Vector2.ZERO]
	return [true, sp]


## 장면 연출 중: 싸움 버튼을 숨기고(누르면 말풍선 넘기기 — 공격 버튼 · 화면 아무 곳) 안내 한 줄
func _set_scene(on: bool) -> void:
	if on == _in_scene:
		return
	_in_scene = on
	if mode == "fight" or mode == "demo":
		touch.show_fight = not on
	touch.show_ff = on and mode == "fight"
	if not on and _ff:                              # 장면이 끝나면 빨리 감기도 끈다(다음 장면은 ×1 부터)
		_set_ff(false)
	hud.set_hint("누르면 넘기기" if on else "")


## 장면 빨리 감기(오른쪽 위 버튼): 장면 동안 게임 속도를 FF_SPEED 로 — 말풍선 · 걷기가 모두 빨라진다(판정 · 리플레이는 그대로 — _apply_speed)
func _set_ff(on: bool) -> void:
	_ff = on
	touch.set_lit("ff", on)
	touch.set_label("ff", "×%d" % int(FF_SPEED) if on else "×1")
	_apply_speed()


## 창 밖으로 날아가는 인형: 포물선으로 날며 돌고, 끝에 닿으면 사라진다
func _tick_tossed(dt: float) -> void:
	for it in _tossed.duplicate():
		var n: Node3D = it[0]
		it[3] = float(it[3]) + dt
		var u: float = clampf(float(it[3]) / maxf(0.05, float(it[4])), 0.0, 1.0)
		var at: Vector3 = (it[1] as Vector3).lerp(it[2], u)
		at.y = 1.6 * sin(u * PI) + 0.3 * u
		n.position = at
		n.rotation.x = -u * 2.4
		if u >= 1.0:
			n.queue_free()
			_tossed.erase(it)


## 여유 자세(2026-11-12 사용자 "본인보다 레벨이 낮은 캐릭터들만 있으면 여유있는 포즈 … 동급 캐릭터가 나오면 가드를 올려서"):
## 판에 서 있는(쓰러지지 않고 싸움에서 빠지지 않은) 다른 편 사람이 모두 이 사람보다 아랫급이면 calm — 인형이 가드를 내린다(puppet_pose).
## 등급을 모르는 사람(빈 등급)은 가장 아래로 친다. 그림만 바뀐다(판정 · 리플레이와 상관없음)
func _mark_calm() -> void:
	var ladder: Array = Common.ranks()
	var top := {}                                  # 편 → 그 편에 서 있는 사람의 가장 높은 등급 번호
	for f in pup:
		if f.alive() and not f.inert:
			top[f.team] = maxi(int(top.get(f.team, -1)), ladder.find(str(f.rank)))
	for f in pup:
		if _in_scene or f.inert:
			pup[f].calm = true                         # 장면 연출 · 지켜보는 사람(standing)은 편한 자세(사용자 9번 '둘다 편한 자세로')
			continue
		var foe := -1
		for t in top:
			if t != f.team:
				foe = maxi(foe, int(top[t]))
		pup[f].calm = ladder.find(str(f.rank)) > foe


## 무대 + 인형을 지금 판(방)에 맞게 다시 만든다 — 11장은 방을 넘을 때마다(신호 "room")
func _build_stage_view() -> void:
	_gone_t.clear()
	for f in pup:
		pup[f].queue_free()
	pup.clear()
	_lod_dt.clear()
	_build_arena()
	for f in d["world"].fighters:
		_add_puppet(f)
	_markers()
	var hb = d["hero"]
	var bb = d["boss"] if d["boss"] != null else hb
	cam.snap(pup[hb].position, pup[bb].position)


## 무대 그림만 — 방에 들어설 때 · 싸움 중 맵이 넓어지거나 무대가 바뀔 때(stage 신호 stage_view — triggers bounds · theme)
func _build_arena() -> void:
	if arena != null:
		arena.queue_free()
	if kind == "stage":
		arena = VIEWS[Campaign.view(chapter)].new()
		arena.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(arena)
		arena.build(str(d.get("theme", d["room"]["theme"])), d["world"].bounds, not headless)
		Ink.stylize(arena, not headless)
		evfx.arena = arena
	else:
		arena = Arena.new()
		arena.process_mode = Node.PROCESS_MODE_PAUSABLE
		add_child(arena)
		arena.build(not headless)
		Ink.stylize(arena, not headless)
		evfx.arena = arena


## 사람 하나의 인형 — 방에 들어설 때 · 방 안에서 새로 선 사람(stage 신호 spawn — triggers)
func _add_puppet(f) -> void:
	var lname := _look_of(f)
	var art := str(args["art"])
	var p
	if art != "puppet" and Looks.has_art(lname, art):
		p = PuppetGlb.new() if art == "a" else PuppetDot.new()   # 그림 바꿔 끼우기 — 판정은 그대로(LSP)
		lname += "_" + art
	else:
		p = Puppet.new()
	p.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(p)
	p.setup(Looks.look(lname))
	p.update_from(f, 0.0, false)
	pup[f] = p


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
	return "베기" if shape.begins_with("slash") or shape.begins_with("thrust") or shape in ["overhead_chop", "reverse_stab", "rising_slash"] else "치기"


## 방 규칙의 남은 초(따돌리기 2장 남궁혁 · 버티기 · 제한 시간 — stage.timers)와 관전 방을 아래 알림 줄에 — 방을 넘으면 지운다
func _escape_hint() -> void:
	var parts: Array = []
	if kind == "stage":
		var tm := Stage.timers(d)
		if tm["auto"]:
			parts.append(str(Lines.at("stage.watch")))
		if float(tm["escape"]) >= 0.0:
			var eh = Lines.at(str(d["tbl"].LINES) + ".escape_hint")
			parts.append(str(eh if eh != null else Lines.at("stage.escape_hint")) % ceili(float(tm["escape"])))
		if float(tm["survive"]) >= 0.0:
			parts.append(str(Lines.at("stage.survive_hint")) % ceili(float(tm["survive"])))
		if float(tm["limit"]) >= 0.0:
			parts.append(str(Lines.at("stage.limit_hint")) % ceili(float(tm["limit"])))
	if not parts.is_empty():
		hud.set_hint(" · ".join(parts))
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
	touch.set_label("difficulty", Difficulty.label(save["difficulty"]))
	hud.set_hint(_title_hint())
	_trace("MODE title frame=%d" % frames)
	snd.song(Campaign.TITLE_SONG)


func _start(m: String) -> void:
	mode = m
	mode_t = 0
	fights += 1
	touch.show_pause = m == "fight"
	touch.show_swap = m == "fight" and _can_swap()
	touch.show_art = false
	touch.show_fight = true
	menu.visible = false
	if not paused and not menu_open:
		get_tree().paused = false               # 판을 새로 시작하면 장면 트리 멈춤 · 소리 끔이 남지 않게(멈춤 지킴이 참고)
		AudioServer.set_bus_mute(0, false)
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
	_music()


## 지금 장 · 방의 곡(src/data/campaign.gd song_for) — 같은 곡이 이미 돌고 있으면 그대로(방을 넘어도 끊기지 않게)
func _music() -> void:
	var s := Campaign.song_for(chapter, int(d.get("room_i", 0)) if kind == "stage" else 0)
	if snd.current != s or not snd.song_playing():
		snd.song(s)


## 멈춤 지킴이(사용자 2026-11-10 rc.8 폰 "다른 장에서 6장 넘어갈 때 멈춤. 소리도 안남. FPS 120" — v0.5.0-rc.1 에도 같은 말, 서버 ·
## 에뮬레이터에서 재현 안 됨): 싸우는 중(멈춤 · 메뉴 아님)인데 로직이 STALL_SECS 동안 한 칸도 안 돌면 그때 상태를 logcat 에 남기고
## 멈춤 · 속도 · 소리를 다시 건다(그림은 돌고 로직 · 소리만 선 상태 — 장면 트리 멈춤 · 물리 틱 · 소리 버스 중 하나로 본다)
func _watch_stall(_dt: float) -> void:
	# 실제 시계로 잰다(Engine.time_scale 이 0 이 되면 dt 도 0 — 2026-11-12 rc.14 "6장 … 계속 멈추네 · 앱을 다시 켜야")
	var now := Time.get_ticks_msec()
	var logic_mode := mode == "fight" or mode == "demo"
	var tick := _logic_ticks if logic_mode else frames      # 싸움 밖(처음 화면 · 결과 · 바꿈)은 물리 프레임이 도는지만
	if paused or menu_open or tick != _stall_seen or _stall_ms == 0:
		if now - _stall_last > STALL_FORGET_MS:
			_stall_hits = 0
		_stall_seen = tick
		_stall_ms = now
		return
	if now - _stall_ms < int(STALL_SECS * 1000.0):
		return
	_stall_hits += 1
	_stall_last = now
	print("STALL #%d mode=%s kind=%s chapter=%s tree_paused=%s ticks=%d time_scale=%.2f mute=%s slowmo=%d over=%s frames=%d" % [_stall_hits,
		mode, kind, chapter, get_tree().paused, Engine.physics_ticks_per_second, Engine.time_scale, AudioServer.is_bus_mute(0),
		int(d["world"].slowmo), str(d["world"].over), frames])
	_stall_ms = now
	get_tree().paused = false
	AudioServer.set_bus_mute(0, false)
	Engine.time_scale = maxf(Engine.time_scale, 1.0)
	_apply_speed()
	# 다시 걸어도 또 서면(두 번째) 지금 장 · 방을 새로 짓고 이어 싸운다 — 화면에 짧은 표시(폰 리뷰에서 알려 달라고 docs/폰확인.md)
	if _stall_hits >= 2:
		_stall_hits = 0
		hud.message("멈춤을 풀었습니다", "멈춤 코드 %s-%s-%d" % [mode, chapter, int(d.get("room_i", 0))], 3.0)
		if logic_mode:
			_new_run(chapter, int(d.get("room_i", 0)) if kind == "stage" else 0)
			_start("fight" if mode == "fight" else "demo")
		else:
			_new_run(Save.next_chapter(save))
			_enter_title()


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
		"ff":                                      # 장면 빨리 감기 버튼
			if _in_scene:
				_set_ff(not _ff)
		"art":
			_fake_art = true
		"difficulty":
			_fake_difficulty = true
		"autowin":
			_dev_win = true
		"speed":
			save["speed"] = Save.next_speed(float(save["speed"]))
			_apply_speed()
		"menu":
			if mode == "fight":
				_set_menu(true)
		var act:
			if str(act).begins_with("menupick_"):           # menupick_ch11 · menupick_room3 · menupick_resume · menupick_title
				_fake_menu = str(act).substr(9)


## 개발 시험(--events autowin)만: 방의 적을 쓰러뜨린다 — 방 넘기 · 끝 방 · 깸 · 세이브는 게임 그대로 돈다. 결투는 보스를
func _dev_knockout() -> void:
	if kind == "stage":
		for e in d["enemies"]:
			if e.alive() and not e.inert:
				e.die()
		var gx: float = Stage._walk_goal(d)            # 걸어가야 터지는 trigger(x: — 0장 군터의 방)가 남았으면 그 자리로(사람 입력이 없어 걷지 않는다)
		if gx > -INF and d["hero"] != null:
			d["hero"].pos.x = maxf(d["hero"].pos.x, gx + 0.05)
	elif d["boss"] != null and d["boss"].alive() and d["world"].over == "":
		d["boss"].die()
		d["world"].over = "win"


func _pressed_anything() -> bool:
	if _fake_press:
		_fake_press = false
		return true
	return Input.is_action_just_pressed("attack") or Input.is_action_just_pressed("roll") \
		or Input.is_action_just_pressed("parry") or not touch.take_edges().is_empty() \
		or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)


func _title_hint() -> String:
	var t = Lines.at("title")
	return "%s · 그림: %s · %s: %s" % [t["hint"], ART_NAMES[str(args["art"])], t["difficulty"], Difficulty.label(save["difficulty"])]


## 처음 화면 고르기 → 장 id · "bench" · ""(아직). 장 카드 · 이어하기를 누름(터치 · 마우스), 1 · 2 키 = 할 수 있는 장 차례,
## Enter · 베기 · 구르기 · 쳐내기 키 = 이어하기. 빈 곳을 누르면 아무것도 안 한다(카드를 빗맞혀 시작하지 않게)
func _title_pick() -> String:
	if Input.is_action_just_pressed("art") or touch.peek_edge("art") or _fake_art:
		_fake_art = false
		touch.take_edges()
		var order: Array = Save.ARTS                # 그림 B(도트)는 고르지 않는다(2026-11-11 — --art b 개발 인자만)
		args["art"] = order[(order.find(str(args["art"])) + 1) % order.size()]
		save["art"] = args["art"]
		_write_save()
		_build_stage_view()
		hud.set_hint(_title_hint())
		mode_t = 0
		return ""
	if Input.is_action_just_pressed("difficulty") or touch.peek_edge("difficulty") or _fake_difficulty:
		_fake_difficulty = false
		touch.take_edges()
		save["difficulty"] = Difficulty.next(save["difficulty"])
		_write_save()
		touch.set_label("difficulty", Difficulty.label(save["difficulty"]))
		hud.set_hint(_title_hint())
		_trace("DIFFICULTY %s" % save["difficulty"])
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
	_trace("SAVE %s art=%s difficulty=%s cleared=%s" % [p["state"], save["art"], save["difficulty"], ",".join(save["cleared"].keys())])


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
		_menu_diff0 = str(save["difficulty"])
		hud.message("", "", 0.0)                    # 가운데 알림(시작 글 등)이 메뉴 카드 밑으로 비치지 않게
		_fill_stage_menu()
	smenu.visible = on
	_trace("MENU %s frame=%d" % ["on" if on else "off", frames])


func _fill_stage_menu() -> void:
	var ml = Lines.at("menu")
	smenu.heading = str(ml["heading"])
	smenu.buttons = {"resume": str(ml["resume"]), "title": str(ml["title"]), "difficulty": str(ml["difficulty"]) % Difficulty.label(save["difficulty"])}
	smenu.chapters = []
	for id in Campaign.ids():
		var long_t: bool = Campaign.playable_ids().size() <= StageMenu.ROW_MAX     # 장이 많으면 작은 카드 두 줄 — 짧은 이름
		smenu.chapters.append({"id": id, "title": str(Campaign.title(id)[0]) if long_t else Campaign.short_title(id), "open": Save.unlocked(save, id)})
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
	elif pick == "difficulty":
		save["difficulty"] = Difficulty.next(save["difficulty"])
		_write_save()
		_trace("DIFFICULTY %s" % save["difficulty"])
		_fill_stage_menu()
	elif pick == "resume" and str(save["difficulty"]) != _menu_diff0:
		# 난이도를 바꾸고 닫으면 지금 스테이지를 새 난이도로 처음부터(판 중간에 배율을 바꾸지 않는다 — 리플레이 기록은 판 시작 opts)
		_set_menu(false)
		_switch_to = [chapter, int(d.get("room_i", 0)) if kind == "stage" else 0]
		mode = "switch"
		mode_t = 0
		touch.show_fight = false
		var rm: String = str(Lines.at("menu")["restart"]) % Difficulty.label(save["difficulty"])
		hud.message(rm, "", 1.6)
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
	if on and _ff and _in_scene:
		k = maxf(k, FF_SPEED)
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
	if mode == "fight" and _in_scene and touch.take_edge("ff"):
		_set_ff(not _ff)
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
				# 성능 점검(#9 기준 '적 30명'): 11장 첫 방(지하주차장)에 경호원 30명을 더 세우고 봇 데모 — 오른쪽 위 FPS 를 본다
				args["crowd"] = 30
				_new_run("ch11")
				args["crowd"] = 0
				_start("demo")
				hud.message("성능 점검", "지하주차장 · 적 %d명 — 오른쪽 위 FPS" % d["enemies"].size(), 4.0)
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
			if _dev_win and mode == "fight":
				_dev_knockout()
			# 슬로모션(백도찬 첫 엇박): 로직을 두 화면에 한 번만 돌린다
			if d["world"].slowmo <= 0 or frames % 2 == 1:
				var it = null if mode == "demo" else Replay.quantize(_player_intent())   # 양자화한 입력으로 돌려야 재생이 같다
				Replay.add(rec, d, it)
				if kind == "stage":
					Stage.step(d, it)
				else:
					Duel.step(d, it)
				_logic_ticks += 1
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
		# draws = 그리기 호출(화면 / 그림자 패스) · objs = 화면 물체 · tris = 화면 삼각형(천) — 기기와 상관없는 그리기 부담(끊김 원인 가르기)
		var vp := get_viewport()
		print("FPS_LOG fps=%d process_ms=%.1f frame=%d mode=%s kind=%s fighters=%d screen=%s draws=%d/%d objs=%d tris=%dk" % [
			Engine.get_frames_per_second(), Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, frames, mode, chapter,
			d["world"].fighters.size(), str(vp.get_visible_rect().size),
			vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
			vp.get_render_info(Viewport.RENDER_INFO_TYPE_SHADOW, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
			vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_OBJECTS_IN_FRAME),
			vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME) / 1000])
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
	var skip := _in_scene and ((e.has("tap") and not e.has("btn_tap")) or _fake_press)   # 장면 넘기기(화면 누름 — 버튼 말고 · 시험 --events press)
	if skip:
		_fake_press = false
	return {
		"move": mv, "face": h.dir_to(tg) if tg != null else Vector2.ZERO,
		"attack": Input.is_action_just_pressed("attack") or e.has("attack") or skip,   # 장면 중 화면 누름 = 넘기기
		"parry": Input.is_action_just_pressed("parry") or e.has("parry"),
		"parry_held": Input.is_action_pressed("parry") or touch.held("parry"),
		"roll": Input.is_action_just_pressed("roll") or e.has("roll"),
		"jump": Input.is_action_just_pressed("jump") or e.has("jump"),
		"crouch": Input.is_action_pressed("crouch") or touch.held("crouch"),
		"dash": Input.is_action_just_pressed("dash") or e.has("dash"),
		"skill": Input.is_action_just_pressed("skill") or e.has("skill"),
		"skill_next": Input.is_action_just_pressed("skill_next") or e.has("skill_next"),
		"swap": swap,
	}


## 한 프레임 판정 뒤: 방이 바뀌었으면 무대 · 인형을 다시 만들고, 신호를 연출 · 소리로(event_fx.gd), 판이 끝났으면 결과
func _after_tick() -> void:
	var w = d["world"]
	if w.events.any(func(e): return e[0] == "room"):
		_undim()
		_build_stage_view()
		touch.show_swap = mode == "fight" and _can_swap()     # 2장: 방마다 조작 인물이 바뀐다
		if mode == "fight" or mode == "demo":
			_music()                                          # 마지막 보스 방에서 곡이 바뀐다
	for e in w.events:
		if e[0] == "spawn" and not pup.has(e[1]):          # 방 안에서 새로 선 사람(triggers spawn)
			_add_puppet(e[1])
		elif e[0] == "recruit" and pup.has(e[1]):
			pup[e[1]].victory = false                       # 우리 편이 되어 다시 싸운다
		elif e[0] == "toss" and pup.has(e[1]):             # 장면: 날아가 사라진다(대표실 창 밖 — scene.gd toss)
			var tp: Node3D = pup[e[1]]
			pup.erase(e[1])
			_tossed.append([tp, Vector3(e[2].x, 0, e[2].y), Vector3(e[3].x, 0, e[3].y), 0.0, float(e[4])])
		elif e[0] == "scene":
			_set_scene(bool(e[1]))
		elif e[0] == "leave" and pup.has(e[1]):            # 조작 인물 묶음에서 빠짐(triggers cast) · 장면 퇴장
			pup[e[1]].queue_free()
			pup.erase(e[1])
		elif e[0] == "stage_view":
			_build_arena()
		elif e[0] == "cast":
			touch.show_swap = mode == "fight" and _can_swap()
		elif e[0] == "fade":                               # 방 끝 연출 — 어둡게 하며 글(11장 만인지상)
			hud.set_dim(true)
			hud.message(str(e[1]), str(e[2]), float(e[3]))
			_faded = true
	_smash_props(w)
	var swapped: bool = w.events.any(func(e): return e[0] in ["swap", "ko", "spawn", "recruit", "cast"])
	evfx.apply(d)
	w.events.clear()
	if swapped:
		_markers()
	if w.over != "":
		_end_fight(w.over)


## 방 끝 연출(fade)로 어둡게 한 화면을 되돌린다 — 다음 방 · 새 판
func _undim() -> void:
	if _faded:
		hud.set_dim(false)
		_faded = false


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
	if last_win:                                       # 중간 스테이지부터 한 판(난이도 바꿔 다시 · 메뉴로 고름)도 깬 장 — 장은 차례대로만 열려
		Save.record_clear(save, chapter, int(d["world"].frame) if run_room == 0 else 0)   # 건너뛰기는 없다. 가장 짧은 판은 첫 스테이지부터만(rc.4 폰 "8장 깨도 9장으로 안넘어가")
		_write_save()
	if result == "win":
		if pup.has(d["hero"]):
			pup[d["hero"]].victory = true
		var wm = Lines.at("ch6.win")
		if kind == "stage":                             # 끝 방 글은 끝 방에서 이미 보였다 — 결과는 '깸' + 다음(같은 글이면 굳은 것처럼 보였다, rc.2)
			wm = [str(Lines.at("result")["win_title"]) % str(Campaign.title(chapter)[0]),
				str(Lines.at("result")["win_next"]) % str(Campaign.title(Save.next_chapter(save))[0])]
		hud.message(str(wm[0]), str(wm[1]), 9999.0)
		var last_ch: bool = Campaign.playable_ids().back() == chapter
		snd.song(Campaign.ENDING_SONG if last_ch else "victory", false)    # 마지막 장(13장)을 깨면 끝 곡
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
	_watch_stall(dt)
	var partner = Stage.partner(d) if kind == "stage" else null
	var phase: int = d["boss"].phase if d["boss"] != null else 1
	if paused or menu_open:
		hud.update_bars(d["hero"], d["boss"], phase, 0.0, partner)     # 접기 · 펴기에 자리만 다시 잡는다
		return
	evfx.tick_later(dt)
	if not headless:
		Ink.fit_3d_scale(get_window())                  # 접기 · 펴기로 창 크기가 바뀌면 3D 해상도를 다시 맞춘다
	var frozen: bool = d["world"].hitstop > 0 and (mode == "fight" or mode == "demo")
	var lod := pup.size() > LOD_CROWD and cam != null
	_lod_tick += 1
	_mark_calm()
	for f in pup:
		if not f.alive() and kind == "stage" and f != d["boss"] and d["enemies"].has(f):
			_gone_t[f] = float(_gone_t.get(f, 0.0)) + dt    # 쓰러진 적은 몇 초 뒤 치운다(12장 개전 경호대 100 · 13장 공터 50 — 폰 성능)
			if _gone_t[f] > GONE_SECS:
				pup[f].visible = false
				continue
		elif _gone_t.has(f):
			_gone_t.erase(f)                            # 다시 일어남(합류 recruit) — 다시 보인다
			pup[f].visible = true
		if lod and f != d["hero"] and not cam.is_position_in_frustum(pup[f].position + Vector3(0, 1.0, 0)):
			# 사람이 많을 때(11장 주차장 47명 · 12장 개전) 화면 밖 인형은 자세를 LOD_EVERY 프레임에 한 번(밀린 시간을 모아서) — 자리는 매번
			_lod_dt[f] = float(_lod_dt.get(f, 0.0)) + dt
			if (_lod_tick + f.get_instance_id()) % LOD_EVERY != 0:
				pup[f].position = Vector3(f.pos.x, 0, f.pos.y)
				continue
			pup[f].update_from(f, _lod_dt[f], frozen)
			_lod_dt[f] = 0.0
			continue
		_lod_dt.erase(f)
		pup[f].update_from(f, dt, frozen)
	_tick_tossed(dt)
	touch.set_label("attack", _attack_label(d["hero"]))
	touch.set_label("parry", "피하기" if d["hero"].evade_btn else "쳐내기")   # 칼날 쳐내기가 없는 사람은 피하기(2026-11-12)
	var hp: Vector3 = pup[d["hero"]].position if pup.has(d["hero"]) else _cam_last     # 장면에서 퇴장한 조작 인물(2장 이슬 한 합 뒤)
	# 장면 중에는 말하는 사람을 따라간다 — 걸어 나가는 사람(leave nowait)은 화면에서 뺀다(2026-11-12 사용자 "멘트를 할 때는 이슬쪽에
	# 포커싱이 맞춰져야하는데 뛰어나간 김신쪽에 포커싱이 맞춰져 있어서 멘트하는게 하나도 안보여")
	var gone_out: Array = Scene.leaving(d) if _in_scene else []
	if _in_scene:
		var sp = Scene.speaker(d)
		if sp != null and pup.has(sp) and d["world"].fighters.has(sp) and not gone_out.has(sp):
			hp = pup[sp].position
		elif gone_out.has(d["hero"]) or not d["world"].fighters.has(d["hero"]):
			var rest: Array = d["world"].fighters.filter(func(x): return pup.has(x) and not gone_out.has(x))
			if not rest.is_empty():
				hp = pup[rest[0]].position
	_cam_last = hp
	if kind == "stage":
		var pts: Array = []
		for f in pup:
			if gone_out.has(f):
				continue
			if (f.alive() and not f.inert) or (_in_scene and d["world"].fighters.has(f)):   # 장면 중에는 지켜보는 사람 · 말하는 사람도 화면에
				pts.append(pup[f].position)
		cam.follow_group(hp, pts, dt, d["world"].shake)
	else:
		cam.follow(hp, pup[d["boss"]].position if pup.has(d["boss"]) else hp, dt, d["world"].shake)
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
