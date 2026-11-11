extends SceneTree
## 그리기 부담 가르기(개발용 — 끊김 원인 찾기, 2026-11-11 rc.12 폰 리뷰 '캐릭터 많이 나오니까 끊김'): 게임(main.tscn)을 그대로 띄워
## N 프레임 뒤 화면에 보이는 메시를 '누구 것'(인형 하나 · 무대)별로 세고, 그리기 호출 · 물체 · 삼각형 수를 찍는다.
## 창이 있어야 그린다:  tools/xvfb_run.sh <godot> --path . --rendering-driver opengl3 -s res://tools/perf_probe.gd -- <게임 인자> [--probe-at N]
##   예) ... -- --autoplay --mode stage --crowd 30 --art a --probe-at 90 [--probe-shadow off | ortho | 2 | 4]
## 출력: PROBE 줄(합계) · PROBE_OWNER 줄(주인별 메시 · 먹선 · 그림자 드리움 · 삼각형) — 기기와 상관없는 수라 고치기 앞뒤를 맞대 본다.

var at := 90
var n := 0
var proc_sum := 0.0          # 처음 30 프레임(방 짓기)을 뺀 평균 처리 시간 — 스크립트(로직 + 인형 자세) CPU 부담
var proc_n := 0
var shadow := ""             # --probe-shadow off | ortho | 2 | 4 — 해 그림자 방식을 바꿔 재 본다(실험)


func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	var i := a.find("--probe-at")
	if i >= 0 and i + 1 < a.size():
		at = int(a[i + 1])
	i = a.find("--probe-shadow")
	if i >= 0 and i + 1 < a.size():
		shadow = a[i + 1]
	root.add_child(load("res://main.tscn").instantiate())


func _process(_dt: float) -> bool:
	n += 1
	if n > 30:
		proc_sum += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		proc_n += 1
	if n == at - 3 and shadow != "":
		for l in root.find_children("*", "DirectionalLight3D", true, false):
			var dl := l as DirectionalLight3D
			if not dl.shadow_enabled:
				continue
			match shadow:
				"off":
					dl.shadow_enabled = false
				"ortho":
					dl.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
				"2":
					dl.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
				"4":
					dl.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	if n == at:
		_report()
		return true
	return false


func _report() -> void:
	var vp := root.get_viewport()
	print("PROBE draws=%d shadow_draws=%d objs=%d tris=%dk process_ms=%.1f avg_process_ms=%.2f" % [
		vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
		vp.get_render_info(Viewport.RENDER_INFO_TYPE_SHADOW, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
		vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_OBJECTS_IN_FRAME),
		vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME) / 1000,
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, proc_sum / maxi(proc_n, 1)])
	var own := {}          # 주인 → [메시, 먹선, 그림자 드리움, 삼각형, 면 수]
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if not m.is_visible_in_tree() or m.mesh == null:
			continue
		var key := _owner_key(m)
		if not own.has(key):
			own[key] = [0, 0, 0, 0, 0]
		var r: Array = own[key]
		r[0] += 1
		r[1] += 1 if m.material_overlay != null else 0
		r[2] += 1 if m.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF else 0
		r[4] += m.mesh.get_surface_count()
		for s in m.mesh.get_surface_count():
			var arr := m.mesh.surface_get_arrays(s)
			var idx = arr[Mesh.ARRAY_INDEX]
			r[3] += (idx.size() if idx != null else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	var keys := own.keys()
	keys.sort_custom(func(x, y): return own[x][0] > own[y][0])
	var tot := [0, 0, 0, 0, 0]
	for k in keys:
		for j in 5:
			tot[j] += own[k][j]
	print("PROBE_TOTAL owners=%d meshes=%d surfaces=%d overlay=%d cast=%d tris=%dk" % [keys.size(), tot[0], tot[4], tot[1], tot[2], tot[3] / 1000])
	for grp in ["puppet:puppet3d", "puppet:puppet_glb", "puppet:puppet_dot", "set:"]:
		var g := [0, 0, 0, 0, 0, 0]
		for k in keys:
			if str(k).begins_with(grp):
				g[5] += 1
				for j in 5:
					g[j] += own[k][j]
		print("PROBE_GROUP %s owners=%d meshes=%d surf=%d overlay=%d cast=%d tris=%dk" % [grp, g[5], g[0], g[4], g[1], g[2], g[3] / 1000])
	for k in keys.slice(0, 14):
		var r: Array = own[k]
		print("PROBE_OWNER %-40s meshes=%d surf=%d overlay=%d cast=%d tris=%d" % [k, r[0], r[4], r[1], r[2], r[3]])


## 메시의 주인 — 인형(puppet3d 계열 스크립트가 붙은 가장 가까운 조상)이면 그 이름, 아니면 무대 뿌리 밑 첫 마디
func _owner_key(n: Node) -> String:
	var p := n.get_parent()
	var last := n
	while p != null and p != root:
		var s = p.get_script()
		if s != null and str(s.resource_path).contains("puppet"):
			return "puppet:%s#%d" % [s.resource_path.get_file(), p.get_instance_id()]
		last = p
		p = p.get_parent()
	return "set:" + str(last.name) + "/" + str(n.get_parent().name)
