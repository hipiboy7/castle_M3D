extends SceneTree
## 그림 A(기획서 03 5절 — 3D SD 모델 · 툰 · 뼈대) 만들기: 스크립트로 피부 메시(관절에서 두 뼈에 나눠 걸린 가중치 — 팔꿈치 · 무릎이
## 종이처럼 꺾이지 않고 휜다) + 뼈대를 만들어 GLB 로 내보낸다. 사람 손 · 외부 업로드 없음.
##   <godot> --headless --path . -s res://tools/make_models.gd      → assets/models/<id>_a.glb (김신 · 신겐)
## Blender 를 쓰려 했으나 이 서버에서 받아 실행하는 것이 막혀(2026-11-06) Godot GLTFDocument 로 같은 일을 한다 — 게임은 GLB 를
## 가져와 끼우므로(src/view/puppet_glb.gd) 나중에 Blender · Mixamo · ArtCraft GLB 로 바꿔도 뼈 이름만 맞으면 된다.
## 뼈 이름 · 길이는 관절 인형(src/view/puppet3d.gd J)과 같다: hips · spine · chest · neck · head · sh_/el_/hand_ · th_/kn_/ft_ (r · l).
## 쉬는 자세의 뼈 회전은 모두 0(세계 축과 나란히) — 인형의 관절 각도를 그대로 뼈 회전으로 쓴다.
## SD 느낌: 머리를 크게(1.55배) · 몸통 · 팔다리를 둥글고 굵게 · 손발을 크게. 색은 정점 색(툰 재질은 게임에서 입힌다).

const Looks = preload("res://src/view/looks.gd")
const OUT := "res://assets/models/%s_a.glb"

var st: SurfaceTool
var bones := {}                  # 이름 → 번호
var gpos := {}                   # 이름 → 쉬는 자세 위치(뼈대 공간)


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/models")
	for id in ["kim", "shingen"]:
		var t0 := Time.get_ticks_msec()
		var path := OUT % ("kimshin" if id == "kim" else "shingen")
		var err := _make(Looks.LOOKS[id], path)
		print("MODEL %s %s %dms" % [path, "ok" if err == OK else "error %d" % err, Time.get_ticks_msec() - t0])
	quit(0)


func _skeleton(lk: Dictionary) -> Skeleton3D:
	var sk := Skeleton3D.new()
	sk.name = "Skeleton3D"
	var wide: float = lk.get("wide", 1.08 if lk.get("big", false) else 1.0)
	var sh_wide: float = lk.get("shoulder", wide)
	var table := [
		["hips", "", Vector3(0, 0.97, 0)], ["spine", "hips", Vector3(0, 0.02, 0)], ["chest", "spine", Vector3(0, 0.27, 0)],
		["neck", "chest", Vector3(0, 0.215, 0)], ["head", "neck", Vector3(0, 0.135, 0)],
	]
	for side in ["r", "l"]:
		var sx := 1.0 if side == "r" else -1.0
		table.append(["sh_" + side, "chest", Vector3(sx * 0.2 * sh_wide, 0.165, 0)])
		table.append(["el_" + side, "sh_" + side, Vector3(0, -0.29, 0)])
		table.append(["hand_" + side, "el_" + side, Vector3(0, -0.26, 0)])
		table.append(["th_" + side, "hips", Vector3(sx * 0.095 * wide, -0.03, 0)])
		table.append(["kn_" + side, "th_" + side, Vector3(0, -0.45, 0)])
		table.append(["ft_" + side, "kn_" + side, Vector3(0, -0.44, 0)])
	for row in table:
		var i := sk.get_bone_count()
		sk.add_bone(row[0])
		bones[row[0]] = i
		if row[1] != "":
			sk.set_bone_parent(i, bones[row[1]])
		sk.set_bone_rest(i, Transform3D(Basis(), row[2]))
		sk.set_bone_pose_position(i, row[2])
		gpos[row[0]] = (gpos[row[1]] if row[1] != "" else Vector3.ZERO) + row[2]
	return sk


func _make(lk: Dictionary, path: String) -> int:
	bones.clear()
	gpos.clear()
	var root := Node3D.new()
	root.name = path.get_file().get_basename()
	var sk := _skeleton(lk)
	root.add_child(sk)
	sk.owner = root
	st = SurfaceTool.new()
	st.set_skin_weight_count(SurfaceTool.SKIN_4_WEIGHTS)
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_body(lk)
	st.index()
	st.generate_normals()
	var mesh := st.commit()
	var mi := MeshInstance3D.new()
	mi.name = "Body"
	mi.mesh = mesh
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 0.8
	mi.material_override = m
	var skin := Skin.new()
	for n in bones:
		skin.add_named_bind(n, Transform3D(Basis(), -gpos[n]))
	mi.skin = skin
	sk.add_child(mi)
	mi.owner = root
	mi.skeleton = NodePath("..")
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_scene(root, state)
	if err == OK:
		err = doc.write_to_filesystem(state, ProjectSettings.globalize_path(path))
	root.free()
	return err


# ----------------------------------------------------------------------
# 몸 — 관절을 지나는 관은 두 뼈에 가중치를 나눠 건다(부드러운 굽힘)
func _body(lk: Dictionary) -> void:
	var big: bool = lk.get("big", false)
	var wide: float = lk.get("wide", 1.08 if big else 1.0)
	var limb: float = lk.get("limb", 1.0) * 1.12
	var depth: float = lk.get("depth", 1.0)
	var suit: Color = lk["suit"]
	var pants: Color = lk["pants"]
	var shirt: Color = lk["shirt"]
	var skin: Color = lk["skin"]
	var hair: Color = lk["hair"]
	var shoe := Color(0.05, 0.05, 0.06)
	var g := gpos
	# 골반 · 허리 · 가슴(하나로 이어진 몸통)
	_blob(g["hips"] + Vector3(0, -0.02, 0), Vector3(0.17 * wide, 0.13, 0.13 * depth), pants, "hips")
	_tube(g["hips"], g["chest"] + Vector3(0, 0.05, 0), 0.16 * wide, 0.19 * wide, suit, "spine", "hips", "chest", depth)
	_blob(g["chest"] + Vector3(0, 0.1, 0), Vector3(0.23 * wide, 0.16, 0.15 * depth), suit, "chest")
	# 셔츠 V · 넥타이(가슴 앞, -z)
	_blob(g["chest"] + Vector3(0, 0.12, -0.13 * depth), Vector3(0.05, 0.1, 0.02), shirt, "chest")
	if lk.get("tie") != null:
		_blob(g["chest"] + Vector3(0, 0.06, -0.15 * depth), Vector3(0.022, 0.11, 0.015), lk["tie"], "chest")
	# 목 · 머리(SD — 크게)
	_tube(g["neck"] + Vector3(0, -0.04, 0), g["head"], 0.06 * wide, 0.06 * wide, skin, "neck", "chest", "head")
	var hk: float = 1.55 * float(lk.get("head", 1.0))
	var hc: Vector3 = g["head"] + Vector3(0, 0.06 * hk, 0)
	_blob(hc, Vector3(0.12, 0.13, 0.12) * hk, skin, "head")
	_face(lk, hc, hk)
	_hair(lk, hc, hk, hair)
	# 팔 · 다리
	for side in ["r", "l"]:
		var sh: Vector3 = g["sh_" + side]
		var el: Vector3 = g["el_" + side]
		var ha: Vector3 = g["hand_" + side]
		_blob(sh, Vector3(0.085, 0.08, 0.08) * limb, suit, "sh_" + side)
		_tube(sh, el, 0.065 * limb, 0.055 * limb, suit, "sh_" + side, "chest", "el_" + side)
		_tube(el, ha, 0.055 * limb, 0.045 * limb, suit, "el_" + side, "sh_" + side, "hand_" + side)
		_blob(ha + Vector3(0, -0.05, 0), Vector3(0.055, 0.065, 0.05) * limb, skin, "hand_" + side)
		var th: Vector3 = g["th_" + side]
		var kn: Vector3 = g["kn_" + side]
		var ft: Vector3 = g["ft_" + side]
		_tube(th, kn, 0.095 * limb * wide, 0.072 * limb, pants, "th_" + side, "hips", "kn_" + side)
		_tube(kn, ft, 0.07 * limb, 0.055 * limb, pants, "kn_" + side, "th_" + side, "ft_" + side)
		_blob(ft + Vector3(0, -0.02, -0.06), Vector3(0.06, 0.045, 0.12) * sqrt(limb), shoe, "ft_" + side)


func _face(lk: Dictionary, hc: Vector3, hk: float) -> void:
	var eye := Color(0.06, 0.05, 0.05)
	var eh: float = 0.012 if float(lk.get("eye_h", 0.011)) < 0.009 else 0.02
	for sx in [-1.0, 1.0]:
		_blob(hc + Vector3(0.045 * sx, 0.01, -0.112) * hk, Vector3(0.02, eh, 0.01) * hk, eye, "head")
		_blob(hc + Vector3(0.045 * sx, 0.045, -0.108) * hk, Vector3(0.026, 0.006, 0.01) * hk, lk["hair"].darkened(0.1), "head")
	_blob(hc + Vector3(0, -0.02, -0.118) * hk, Vector3(0.016, 0.022, 0.016) * hk, lk["skin"].darkened(0.08), "head")
	if lk.get("beard", false):
		_blob(hc + Vector3(0, -0.085, -0.085) * hk, Vector3(0.06, 0.035, 0.035) * hk, lk["hair"], "head")
	if lk.get("scar", false):
		_blob(hc + Vector3(-0.07, -0.03, -0.1) * hk, Vector3(0.006, 0.03, 0.006) * hk, lk["skin"].darkened(0.35), "head")


func _hair(lk: Dictionary, hc: Vector3, hk: float, hair: Color) -> void:
	var style := str(lk.get("hair_style", "short"))
	if style == "spiky":
		_blob(hc + Vector3(0, 0.05, 0.01) * hk, Vector3(0.125, 0.09, 0.125) * hk, hair, "head")
		for k in 9:
			var a := TAU * k / 9.0
			var base: Vector3 = hc + Vector3(0.07 * cos(a), 0.1, 0.07 * sin(a) + 0.01) * hk
			_cone(base, base + Vector3(0.06 * cos(a), 0.12, 0.06 * sin(a)) * hk, 0.035 * hk, hair, "head")
	else:
		# 뒤로 넘긴 올백: 정수리 · 뒤통수를 덮고 이마 선은 높게 + 앞머리 몇 가닥
		_blob(hc + Vector3(0, 0.06, 0.025) * hk, Vector3(0.126, 0.085, 0.125) * hk, hair, "head")
		_blob(hc + Vector3(0, 0.0, 0.06) * hk, Vector3(0.115, 0.1, 0.08) * hk, hair, "head")
		if style == "slick_fringe":
			for k in 3:
				var b: Vector3 = hc + Vector3(-0.03 + 0.03 * k, 0.09, -0.11) * hk
				_cone(b, b + Vector3(0.005, -0.07, -0.01) * hk, 0.012 * hk, hair, "head")


# ---- 도형 (정점마다 뼈 · 가중치)
func _vert(p: Vector3, col: Color, b: Array, w: Array) -> void:
	st.set_color(col)
	var bi := PackedInt32Array([0, 0, 0, 0])
	var wi := PackedFloat32Array([0, 0, 0, 0])
	for k in b.size():
		bi[k] = bones[b[k]]
		wi[k] = w[k]
	st.set_bones(bi)
	st.set_weights(wi)
	st.add_vertex(p)


func _quad(a, b, c, d, cols: Array, wts: Array) -> void:
	# a b c d 는 [위치, 뼈 목록, 가중치 목록]
	for v in [a, c, b, a, d, c]:             # Godot 앞면 감기 방향(뒤집으면 외곽선 판만 보인다 — 첫 시도)
		_vert(v[0], cols[0], v[1], v[2])


## 관: p0(own 뼈 시작) → p1. 시작 쪽 30% 는 prev 뼈와, 끝 쪽 30% 는 next 뼈와 가중치를 나눈다(관절 가운데서 반반)
func _tube(p0: Vector3, p1: Vector3, r0: float, r1: float, col: Color, own: String, prev := "", next := "", dz := 1.0) -> void:
	var seg := 12
	var rings := 6
	var axis := (p1 - p0)
	var up := axis.normalized()
	var side := up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var fwd := side.cross(up).normalized()
	var rows: Array = []
	for i in rings + 1:
		var t := float(i) / rings
		var r := lerpf(r0, r1, t)
		var b: Array = [own]
		var w: Array = [1.0]
		if prev != "" and t < 0.3:
			var k := 0.5 * (1.0 - t / 0.3)
			b = [own, prev]
			w = [1.0 - k, k]
		elif next != "" and t > 0.7:
			var k2 := 0.5 * (t - 0.7) / 0.3
			b = [own, next]
			w = [1.0 - k2, k2]
		var row: Array = []
		for j in seg:
			var a := TAU * j / seg
			var p := p0 + axis * t + (side * cos(a) + fwd * sin(a) * dz) * r
			row.append([p, b, w])
		rows.append(row)
	for i in rings:
		for j in seg:
			var j2 := (j + 1) % seg
			_quad(rows[i][j], rows[i + 1][j], rows[i + 1][j2], rows[i][j2], [col], [])
	_cap(rows[0], p0, col, true)
	_cap(rows[rings], p1, col, false)


func _cap(row: Array, c: Vector3, col: Color, flip: bool) -> void:
	var cv: Array = [c, row[0][1], row[0][2]]
	for j in row.size():
		var a: Array = row[j]
		var b: Array = row[(j + 1) % row.size()]
		if not flip:
			for v in [cv, b, a]:
				_vert(v[0], col, v[1], v[2])
		else:
			for v in [cv, a, b]:
				_vert(v[0], col, v[1], v[2])


## 타원체(한 뼈에 단단히)
func _blob(c: Vector3, r: Vector3, col: Color, bone: String) -> void:
	var seg := 14
	var rings := 8
	var grid: Array = []
	for i in rings + 1:
		var v := PI * i / rings
		var row: Array = []
		for j in seg:
			var u := TAU * j / seg
			row.append([c + Vector3(sin(v) * cos(u) * r.x, cos(v) * r.y, sin(v) * sin(u) * r.z), [bone], [1.0]])
		grid.append(row)
	for i in rings:
		for j in seg:
			var j2 := (j + 1) % seg
			_quad(grid[i][j], grid[i][j2], grid[i + 1][j2], grid[i + 1][j], [col], [])


func _cone(base: Vector3, tip: Vector3, r: float, col: Color, bone: String) -> void:
	var up := (tip - base).normalized()
	var side := up.cross(Vector3.FORWARD if absf(up.dot(Vector3.FORWARD)) < 0.9 else Vector3.RIGHT).normalized()
	var fwd := side.cross(up)
	var n := 6
	for j in n:
		var a0 := TAU * j / n
		var a1 := TAU * (j + 1) / n
		var p0 := base + (side * cos(a0) + fwd * sin(a0)) * r
		var p1 := base + (side * cos(a1) + fwd * sin(a1)) * r
		for p in [p0, p1, tip]:
			_vert(p, col, [bone], [1.0])
