extends SceneTree
## 자세 모양 모아 보기(개발용) — src/view/poses.gd SHAPES 의 모양마다 A(예비 동작) · W(준비 끝) · S(타격) · O(지나침) 를 옆에서, S 를
## 게임 카메라(위 55도)에서 찍어 한 장(쪽마다 8 모양)에 모은다. 팔다리가 몸을 뚫거나 꺾이지 않는지 눈으로 보는 데 쓴다.
## 창이 있어야 그린다:  tools/xvfb_run.sh <godot> --path . -s res://tools/pose_gallery.gd -- 출력폴더 외형이름 [모양 ..]
## 외형이름 끝이 _a 면 그림 A(GLB — src/view/puppet_glb.gd). 모양을 안 주면 SHAPES 전부(+ 쪽 붙은 _L 은 이름으로 주면 찍는다).
## 출력: <출력폴더>/<외형이름>_<쪽번호>.png — 저장소 밖에 둔다.

const Puppet3D = preload("res://src/view/puppet3d.gd")
const PuppetGlb = preload("res://src/view/puppet_glb.gd")
const Looks = preload("res://src/view/looks.gd")
const P = preload("res://src/view/poses.gd")

const CW := 260
const CH := 320
const PER_ROW := 2          # 한 줄에 모양 둘(칸 다섯씩)
const CELLS := 5
const ROWS := 4


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	var out := str(args[0]) if args.size() > 0 else "user://pose_gallery"
	var name := str(args[1]) if args.size() > 1 else "woojin"
	var shapes: Array = args.slice(2) if args.size() > 2 else P.SHAPES.keys()
	DirAccess.make_dir_recursive_absolute(out)
	var vp := SubViewport.new()
	vp.size = Vector2i(CW, CH)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.own_world_3d = true
	root.add_child(vp)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.72, 0.76, 0.8)     # 밝게 — 검은 정장 윤곽이 보이게
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.55, 0.55, 0.6)
	env.environment.ambient_light_energy = 0.7
	vp.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 20, 0)
	sun.light_energy = 1.1
	vp.add_child(sun)
	var floor_mesh := MeshInstance3D.new()           # 땅 줄(발이 떠 있는지 보이게)
	var bm := BoxMesh.new()
	bm.size = Vector3(4, 0.02, 4)
	floor_mesh.mesh = bm
	floor_mesh.position = Vector3(0, -0.01, 0)
	vp.add_child(floor_mesh)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.9
	vp.add_child(cam)
	var lab := Label3D.new()
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.font_size = 40
	lab.outline_size = 8
	lab.no_depth_test = true
	lab.position = Vector3(0, 2.32, 0)
	vp.add_child(lab)
	var p = PuppetGlb.new() if name.ends_with("_a") and Looks.has_art(name.trim_suffix("_a")) else Puppet3D.new()
	vp.add_child(p)
	p.setup(Looks.look(name))
	var per := PER_ROW * ROWS
	var page := 0
	var i := 0
	while i < shapes.size():
		var img := Image.create(CW * CELLS * PER_ROW, CH * ROWS, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.1, 0.1, 0.1))
		for j in per:
			if i + j >= shapes.size():
				break
			var sh := str(shapes[i + j])
			if not p.shape_keys.has(sh):
				print("NO SHAPE %s" % sh)
				continue
			var keys: Array = p.shape_keys[sh]
			var side := Vector3(1, 0.12, 0)
			var cells := [[keys[3] if keys.size() > 3 else keys[0], side, sh + " A"], [keys[0], side, "W"], [keys[1], side, "S"],
				[keys[4] if keys.size() > 4 else keys[1], side, "O"], [keys[1], Vector3(0.55, 0.82, 0.15), "S 위"]]
			for c in CELLS:
				var pose: Dictionary = cells[c][0]
				p.cur = pose.duplicate()
				p._apply(p.cur)
				p._ground()
				if p.has_method("_drive"):
					p._drive()                 # 그림 A: 뼈는 update_from 끝에 한 번 돈다 — 자세를 바로 넣었으면 직접
				lab.text = str(cells[c][2])
				var d: Vector3 = (cells[c][1] as Vector3).normalized()     # 인형 앞은 -Z, +X = 오른쪽 옆
				cam.look_at_from_position(Vector3(0, 1.05, 0) + d * 10.0, Vector3(0, 1.05, 0), Vector3.UP)
				for _k in 3:
					await process_frame
				var shot := vp.get_texture().get_image()
				shot.convert(Image.FORMAT_RGBA8)
				var col := (j % PER_ROW) * CELLS + c
				img.blit_rect(shot, Rect2i(0, 0, CW, CH), Vector2i(col * CW, (j / PER_ROW) * CH))
		img.save_png(out.path_join("%s_%d.png" % [name, page]))
		print("PAGE %s_%d" % [name, page])
		page += 1
		i += per
	quit(0)
