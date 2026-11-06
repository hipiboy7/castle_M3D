extends SceneTree
## 그림 B(기획서 03 5절 — 3D 배경 + 도트 빌보드)의 도트 시트 만들기: 그림 A 모델(GLB)을 게임 카메라와 같은 각(위 55도)에서
## 직교로 8방향 × 자세마다 그려, 작게 줄이고(도트) 색 수를 줄이고 검은 외곽선을 둘러 한 장(시트)으로 묶는다.
## 이 판의 임시 도트 규격(무정지 규칙 5): 칸 80x80 · 3.4m 높이 · 8방향(45도 — 앞이 0, 왼쪽으로 돈다) · 색 채널 16단 · 1px 외곽선.
## 창이 있어야 그린다 — 작업 서버는 가상 화면으로:
##   tools/xvfb_run.sh <godot> --path . -s res://tools/make_sprites.gd
## 출력: assets/sprites/<id>_b.png(행 = 방향 8, 열 = 자세) · <id>_b.json(자세 이름 · 칸 · 높이)

const Puppet = preload("res://src/view/puppet_glb.gd")
const Looks = preload("res://src/view/looks.gd")
const Fighter = preload("res://src/combat/fighter.gd")
const Moves = preload("res://src/data/moves.gd")

const CELL := 80
const RENDER := 320
const WORLD_H := 3.4
const LOOK_Y := 1.05

## 자세 목록 — 공격은 동작(moves.gd)의 준비(W) · 타격(S) · 회수(F) 세 칸. 칸 이름은 인형의 모양 이름(shape · 왼손이면 _L)
const ATTACKS := {
	"kimshin": ["k_slash1", "k_slash2", "k_thrust", "s_offbeat", "s_kick", "s_triple", "k_finisher", "k_dash"],
	"shingen": ["sg_slash1", "sg_slash2", "sg_stab", "s_sg_dive", "s_sg_kick", "s_sg_leap"],
}

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
	for id in ATTACKS:
		var t0 := Time.get_ticks_msec()
		await _sheet(id)
		print("SPRITES %s %dms" % [id, Time.get_ticks_msec() - t0])
	quit(0)


func _sheet(id: String) -> void:
	var lk: Dictionary = Looks.look("kim_a" if id == "kimshin" else "shingen_a")
	var p = Puppet.new()
	vp.add_child(p)
	p.setup(lk)
	var poses := _poses(p, id)
	var names: Array = poses.keys()
	var sheet := Image.create(CELL * names.size(), CELL * 8, false, Image.FORMAT_RGBA8)
	for k in 8:
		p.rotation.y = deg_to_rad(45.0 * k)
		for c in names.size():
			p._apply(poses[names[c]])
			p._ground()
			await process_frame
			await process_frame
			var img := vp.get_texture().get_image()
			sheet.blit_rect(_dot(img), Rect2i(0, 0, CELL, CELL), Vector2i(c * CELL, k * CELL))
	DirAccess.make_dir_recursive_absolute("res://assets/sprites")
	var base := "res://assets/sprites/%s_b" % id
	sheet.save_png(ProjectSettings.globalize_path(base + ".png"))
	var meta := {"frames": names, "dirs": 8, "cell": CELL, "world_h": WORLD_H, "look_y": LOOK_Y,
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
	for mv_name in ATTACKS[id]:
		var mv := Moves.get_move(mv_name)
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


## 320px 그림 → 80px 도트: 4x4 평균(알파 반 이상만) · 색 16단 · 투명 옆 1px 검은 외곽선
func _dot(img: Image) -> Image:
	img.convert(Image.FORMAT_RGBA8)
	var k := RENDER / CELL
	var out := Image.create(CELL, CELL, false, Image.FORMAT_RGBA8)
	for y in CELL:
		for x in CELL:
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
	for y in CELL:
		for x in CELL:
			if out.get_pixel(x, y).a > 0.0:
				continue
			for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + o
				if q.x >= 0 and q.y >= 0 and q.x < CELL and q.y < CELL and out.get_pixelv(q).a > 0.0:
					edged.set_pixel(x, y, Color(0.03, 0.03, 0.05, 1.0))
					break
	return edged
