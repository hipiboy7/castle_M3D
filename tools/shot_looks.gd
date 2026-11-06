extends SceneTree
## 외형 확인 사진(개발용) — 관절 인형(src/view/puppet3d.gd)을 외형마다 앞 · 옆(3/4)에서 찍어 PNG 로 남긴다. 원작 조각(castle_common
## work/looks/ref/<id>.png)과 나란히 보고 고치는 데 쓴다(castle_common 73차 · 사용자 답58 '원작 캐릭터를 다시 확인해서').
## 창이 있어야 그린다:  tools/xvfb_run.sh <godot> --path . -s res://tools/shot_looks.gd -- 출력폴더 [외형이름 ..]
## 출력: <출력폴더>/<외형이름>.png (앞 · 3/4 두 칸, 480x640 씩) — 저장소 밖에 둔다.

const Puppet3D = preload("res://src/view/puppet3d.gd")
const Looks = preload("res://src/view/looks.gd")

const W := 480
const H := 640


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame
	var args := OS.get_cmdline_user_args()
	var out := str(args[0]) if args.size() > 0 else "user://looks_shots"
	var names: Array = args.slice(1) if args.size() > 1 else Looks.LOOKS.keys()
	DirAccess.make_dir_recursive_absolute(out)
	var vp := SubViewport.new()
	vp.size = Vector2i(W, H)
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.own_world_3d = true
	root.add_child(vp)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color(0.27, 0.35, 0.31)
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color(0.55, 0.55, 0.6)
	env.environment.ambient_light_energy = 0.7
	vp.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40, 20, 0)
	sun.light_energy = 1.1
	vp.add_child(sun)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 2.4
	vp.add_child(cam)
	for n in names:
		var name := str(n)
		var shots: Array[Image] = []
		for yaw in [0.0, 35.0]:
			var p := Puppet3D.new()
			vp.add_child(p)
			p.setup(Looks.look(name))
			var d := Vector3(sin(deg_to_rad(yaw)), 0.15, -cos(deg_to_rad(yaw))).normalized()   # 인형 앞은 -Z
			cam.look_at_from_position(Vector3(0, 1.05, 0) + d * 10.0, Vector3(0, 1.05, 0), Vector3.UP)
			for i in 4:
				await process_frame
			shots.append(vp.get_texture().get_image())
			p.queue_free()
			await process_frame
		var img := Image.create(W * 2, H, false, shots[0].get_format())
		for i in shots.size():
			img.blit_rect(shots[i], Rect2i(0, 0, W, H), Vector2i(W * i, 0))
		img.save_png(out.path_join(name + ".png"))
		print("SHOT %s" % name)
	quit(0)
