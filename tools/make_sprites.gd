extends SceneTree
## 그림 B(기획서 03 5절 — 3D 배경 + 도트 빌보드)의 도트 시트 만들기: 그림 A 모델(GLB)을 게임 카메라와 같은 각(위 55도)에서
## 직교로 8방향 × 자세마다 그려, 작게 줄이고(도트) 색 수를 줄이고 검은 외곽선을 둘러 한 장(시트)으로 묶는다.
## 이 판의 임시 도트 규격(무정지 규칙 5): 칸 80x80 · 3.4m 높이 · 8방향(45도 — 앞이 0, 왼쪽으로 돈다) · 색 채널 16단 · 1px 외곽선.
## 창이 있어야 그린다 — 작업 서버는 가상 화면으로:
##   tools/xvfb_run.sh <godot> --path . -s res://tools/make_sprites.gd [-- 외형이름 ..]   (이름을 주면 그 시트만)
## 출력: src/view/looks.gd ART 의 dots — assets/sprites/<id>_b.png(행 = 방향 8, 열 = 자세) · <id>_b.json(자세 이름 · 칸 · 높이)

const Puppet = preload("res://src/view/puppet_glb.gd")
const Looks = preload("res://src/view/looks.gd")
const Fighter = preload("res://src/combat/fighter.gd")
const Moves = preload("res://src/data/moves.gd")

const CELL := 80
const RENDER := 320
const WORLD_H := 3.4
const LIE := 1.85                 # 누운 몸(넘어짐 · 쓰러짐) 길이(m, 몸 배율 1) — 칸 반쪽이 이보다 짧으면 칸을 키운다(밀도 그대로)
const LOOK_Y := 1.05

## 자세 목록(외형 이름 → 동작) — 공격은 동작(moves.gd)의 준비(W) · 타격(S) · 회수(F) 세 칸. 칸 이름은 인형의 모양 이름(shape ·
## 왼손이면 _L). "동작@R" · "동작@L" 은 치는 손만 바꿔 그린다. 시트에 없는 모양은 그림 B 가 가까운 칸으로 대신한다(puppet_dot.gd NEAR)
## 0 · 1장 인물의 기술은 아직 쓰는 중이라(S5 묶음 2 · 3) 싸움 갈래마다 모양별 대표 동작 하나씩 — 맨주먹(주먹 · 왼주먹 · 옆차기 ·
## 내려찍기 · 찌르기(돌진 · 태클) · 돌기) · 칼(베기 · 되베기 양손 · 찌르기 · 주먹 · 발) · 총(총 양손 · 주먹 · 베기 · 찌르기 · 발)
const FISTS := ["w_jab", "w_straight", "j_kick", "j_finisher", "k_thrust", "b_wide"]
const KNIFE := ["k_slash1", "b_slash2", "k_slash2", "k_thrust", "w_jab", "w_straight", "j_kick", "j_finisher"]
const GUN := ["t_shot@R", "t_shot", "w_jab", "w_straight", "k_slash1", "k_thrust", "j_kick"]
const ATTACKS := {
	"kim": ["k_slash1", "k_slash2", "k_thrust", "s_offbeat", "s_kick", "s_triple", "k_finisher", "k_dash"],
	"shingen": ["sg_slash1", "sg_slash2", "sg_stab", "s_sg_dive", "s_sg_kick", "s_sg_leap"],
	"kim_bare": ["kf_jab", "kf_jab2", "kf_upper", "kf_dash", "j_finisher", "k_thrust"],
	"gunter": GUN, "jintae": FISTS, "kimhyeokju": KNIFE, "kimseongjun": KNIFE,
	"kimdaegeon": FISTS, "gangmanjae": FISTS, "yundeoksu": FISTS,
	# 2장 하성 본사
	"kim_p1_blade": ["k_slash1", "k_slash2", "k_thrust", "k_dash", "kf_jab", "kf_upper", "kf_dash", "j_finisher"],
	"sintaejin": KNIFE, "hwangbomincheol": KNIFE, "gangchangseok": KNIFE, "kimjaehoon": GUN,
	"namgunghyuk": FISTS, "iseul": FISTS, "insu": FISTS,
	"ojiin": ["hy_slash1", "hy_slash2", "hy_thrust", "k_thrust", "w_jab", "j_kick"],
	# 전인물 외형(2026-11-06) — 장 표 이름은 그 인물 동작, 명부 인물은 무기 갈래로(_by_weapon)
	"baek": ["b_slash1", "b_slash2", "b_thrust", "b_sidekick", "b_wide", "b_vital", "b_counter"],
	"woojin": ["w_jab", "w_straight", "w_hook", "w_dash", "w_finisher"],
	"guilhwa": ["gu_jab", "gu_elbow", "gu_dash", "gu_finisher", "s_gu_headbutt", "s_gu_forearm"],
	"hayabusa": ["hy_slash1", "hy_slash2", "hy_thrust", "s_hy_arc", "s_hy_low"],
	"guard": ["c_baton", "c_punch", "w_jab", "j_kick"],
	"g4": ["g4_slash", "g4_thrust", "s_g4_chop", "s_g4_heel", "t_shot"],
	"g4_leader": ["g4_slash", "g4_thrust", "s_g4_chop", "s_g4_heel", "t_shot"],
	"ds_suit": FISTS,
}
const SWORD := ["hy_slash1", "hy_slash2", "hy_thrust", "k_thrust", "w_jab", "j_kick"]
const GUNS := ["pistol", "revolver", "uzi"]


## 명부 인물 자세 — 오른손 무기 갈래(총 · 긴 칼 · 짧은 칼 · 맨손)
static func _by_weapon(lk: Dictionary) -> Array:
	var w := str(lk.get("weapon_r", ""))
	if w in GUNS:
		return GUN
	if w in ["katana", "tachi", "pipe", "bat"]:
		return SWORD
	if w == "" or w == "knuckles" or w == "baton":
		return FISTS
	return KNIFE

var vp: SubViewport
var cam: Camera3D


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame                                 # 나무(SceneTree)에 들어간 뒤에 만든다(look_at · 발 붙이기)
	vp = SubViewport.new()
	vp.size = Vector2i(RENDER, RENDER)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.own_world_3d = true
	root.add_child(vp)
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = WORLD_H
	var dir := Vector3(0, 10, 7).normalized()
	vp.add_child(cam)
	cam.look_at_from_position(Vector3(0, LOOK_Y, 0) + dir * 20.0, Vector3(0, LOOK_Y, 0), Vector3.UP)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 25, 0)
	sun.light_energy = 1.1
	vp.add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 200, 0)
	fill.light_energy = 0.35
	vp.add_child(fill)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.5, 0.5, 0.55)
	env.environment.ambient_light_energy = 0.6
	vp.add_child(env)
	var only := OS.get_cmdline_user_args()
	var done := {}
	for id in Looks.art_names():
		var dots := str(Looks.art_of(id)["dots"])
		if done.has(dots) or (not only.is_empty() and not only.has(id)):
			continue
		done[dots] = true
		var t0 := Time.get_ticks_msec()
		await _sheet(id)
		print("SPRITES %s %dms" % [dots, Time.get_ticks_msec() - t0])
	quit(0)


func _sheet(id: String) -> void:
	var lk: Dictionary = Looks.look(id + "_a")
	var p = Puppet.new()
	vp.add_child(p)
	p.setup(lk)
	var poses := _poses(p, id)
	var names: Array = poses.keys()
	# 큰 몸(거구 보스)은 누운 칸이 잘리지 않게 칸 · 그리는 넓이를 같은 비율로 키운다 — 도트 밀도(칸 / m)는 김신과 같다.
	# 김신 · 신겐 시트(S3)는 3.4m 칸 그대로 만들어 두었다(누운 칸 발끝이 조금 잘림 — 다시 돌리면 이 규칙으로 바뀐다)
	var grow := maxf(1.0, LIE * float(lk.get("scale", 1.0)) / (WORLD_H * 0.5) + 0.02)
	var cell := CELL if grow <= 1.0 else 2 * ceili(CELL * 0.5 * grow)
	var world_h := WORLD_H * cell / CELL
	vp.size = Vector2i(cell, cell) * (RENDER / CELL)
	cam.size = world_h
	var sheet := Image.create(cell * names.size(), cell * 8, false, Image.FORMAT_RGBA8)
	for k in 8:
		p.rotation.y = deg_to_rad(45.0 * k)
		for c in names.size():
			p._apply(poses[names[c]])
			p._ground()
			if p.has_method("_drive"):
				p._drive()                 # 그림 A: 뼈는 update_from 끝에 한 번 돈다 — 자세를 바로 넣었으면 직접
			await process_frame
			await process_frame
			var img := vp.get_texture().get_image()
			sheet.blit_rect(_dot(img, cell), Rect2i(0, 0, cell, cell), Vector2i(c * cell, k * cell))
	var base := str(lk["dots"])
	DirAccess.make_dir_recursive_absolute(base.get_base_dir())
	sheet.save_png(ProjectSettings.globalize_path(base + ".png"))
	var meta := {"frames": names, "dirs": 8, "cell": cell, "world_h": world_h, "look_y": LOOK_Y,
		"made_by": "tools/make_sprites.gd", "source": str(lk["glb"])}
	var f := FileAccess.open(ProjectSettings.globalize_path(base + ".json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(meta, "  "))
	f.close()
	p.queue_free()


## 자세 이름 → 관절 각도 표(인형의 자세 계산을 그대로 — 가짜 Fighter 상태를 넣어 _target_pose 를 부른다)
func _poses(p, id: String) -> Dictionary:
	var out := {}
	var f := Fighter.new()
	f.facing = Vector2(0, -1)
	out["idle"] = p.guard_pose.duplicate()
	f.speed_now = 2.0
	f.move_vec = Vector2(0, -0.034)
	for k in 4:
		p.phase = TAU * k / 4.0
		out["walk%d" % k] = p._locomotion(f, 0.0)
	f.speed_now = 0.0
	for st in ["parry", "hitstun", "stun", "stagger"]:
		f.state = st
		out[st] = p._target_pose(f, 0.0)
	f.state = "roll"
	for k in 3:
		f.t = 4 + 5 * k
		out["roll%d" % k] = p._target_pose(f, 0.0)
	f.state = "down"
	f.t = 30
	out["down"] = p._target_pose(f, 0.0)
	f.state = "attack"
	for entry in ATTACKS.get(id, _by_weapon(p.look)):
		var parts: PackedStringArray = str(entry).split("@")
		var mv := Moves.get_move(parts[0])
		if parts.size() > 1:
			mv = mv.duplicate()
			mv["hand"] = parts[1]
		f.move = mv
		var key: String = p.shape_key(mv)
		if out.has(key + ":S"):
			continue
		var su := int(mv["startup"])
		var ac := int(mv["active"])
		var rc := int(mv["recovery"])
		for pair in [["W", su], ["S", su + ac], ["F", su + ac + maxi(2, int(rc * 0.45))]]:
			f.t = pair[1]
			out[key + ":" + pair[0]] = p._attack_pose(f)
	return out


## 그림(칸의 4배) → 칸 도트(80px 이상): 4x4 평균(알파 반 이상만) · 색 16단 · 투명 옆 1px 검은 외곽선
func _dot(img: Image, cell: int) -> Image:
	img.convert(Image.FORMAT_RGBA8)
	var k := RENDER / CELL
	var out := Image.create(cell, cell, false, Image.FORMAT_RGBA8)
	for y in cell:
		for x in cell:
			var acc := Color(0, 0, 0, 0)
			var n := 0
			var alpha := 0.0
			for dy in k:
				for dx in k:
					var c := img.get_pixel(x * k + dx, y * k + dy)
					alpha += c.a
					if c.a > 0.5:
						acc += c
						n += 1
			if n * 2 >= k * k:
				var c2 := acc / n
				out.set_pixel(x, y, Color(snappedf(c2.r, 1.0 / 15.0), snappedf(c2.g, 1.0 / 15.0), snappedf(c2.b, 1.0 / 15.0), 1.0))
	var edged := out.duplicate()
	for y in cell:
		for x in cell:
			if out.get_pixel(x, y).a > 0.0:
				continue
			for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + o
				if q.x >= 0 and q.y >= 0 and q.x < cell and q.y < cell and out.get_pixelv(q).a > 0.0:
					edged.set_pixel(x, y, Color(0.03, 0.03, 0.05, 1.0))
					break
	return edged
