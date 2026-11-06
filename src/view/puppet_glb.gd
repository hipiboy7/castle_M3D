extends "res://src/view/puppet3d.gd"
## 그림 A — GLB 캐릭터(뼈대 + 피부 메시, assets/models/<id>_a.glb — tools/make_models.gd)를 끼운 인형. 기획서 03 5절 A.
## 관절 인형(puppet3d)의 자세 계산(관절 노드 J)은 그대로 두고 그 메시만 숨긴 뒤, GLB 뼈를 같은 이름의 관절 각도로 돌린다
## (뼈의 쉬는 회전이 0 이라 관절 회전 = 뼈 회전). 무기 · 예고 · 발밑 고리는 인형 것을 그대로 쓴다.
## 바꿔 끼우기(CLAUDE.md 1절 · 2-1절 LSP): update_from(f, dt, frozen) · remove_glasses 를 그대로 물려받는다.
## 툰: 빛을 2 ~ 3 단으로 끊는 재질(diffuse toon) + 뒷면을 조금 키운 검은 외곽선(next_pass).

const BONES := ["hips", "spine", "chest", "neck", "head", "sh_r", "el_r", "hand_r", "sh_l", "el_l", "hand_l",
	"th_r", "kn_r", "ft_r", "th_l", "kn_l", "ft_l"]

var model: Node3D
var skel: Skeleton3D
var bone_of := {}


func setup(lk: Dictionary) -> void:
	super.setup(lk)
	_hide_puppet(J["fall"])
	model = load(str(lk["glb"])).instantiate()
	J["body"].add_child(model)
	skel = _find_skeleton(model)
	for n in BONES:
		bone_of[n] = skel.find_bone(n)
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		mi.material_override = _toon()
	if bone_of.get("head", -1) >= 0:                     # 머리를 작게(Looks.HEAD_K — GLB 는 그대로, 뼈 크기만. _drive 는 자리 · 회전만 쓴다)
		skel.set_bone_pose_scale(bone_of["head"], Vector3.ONE * Looks.HEAD_K)
	_drive()


## 관절 인형의 겉모양만 숨긴다 — 무기(손에 붙은 칼)는 남긴다
func _hide_puppet(n: Node) -> void:
	for c in n.get_children():
		if c == weapon_r or c == weapon_l:
			continue
		if c is MeshInstance3D:
			c.visible = false
		_hide_puppet(c)


func _find_skeleton(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var s := _find_skeleton(c)
		if s != null:
			return s
	return null


func _toon() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_TOON
	m.roughness = 0.6
	m.rim_enabled = true
	m.rim = 0.35
	m.rim_tint = 0.4
	var ol := StandardMaterial3D.new()                  # 외곽선
	ol.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ol.albedo_color = Color(0.02, 0.02, 0.03)
	ol.cull_mode = BaseMaterial3D.CULL_FRONT
	ol.grow = true
	ol.grow_amount = 0.012
	m.next_pass = ol
	mats.append(m)                                      # 맞음 번쩍임 · 엇엇박 달아오름(인형의 _update_flash)이 이 재질에도
	m.emission_enabled = true
	return m


func _apply(p: Dictionary) -> void:
	super._apply(p)
	_drive()


func _ground() -> void:
	super._ground()
	_drive()


func _drive() -> void:
	if skel == null:
		return
	for n in bone_of:
		var i: int = bone_of[n]
		if i < 0:
			continue
		var j: Node3D = J[n]
		skel.set_bone_pose_position(i, j.position)
		skel.set_bone_pose_rotation(i, j.quaternion)
