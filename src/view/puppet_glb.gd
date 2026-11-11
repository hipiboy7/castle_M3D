extends "res://src/view/puppet3d.gd"
## 그림 A — GLB 캐릭터(뼈대 + 피부 메시, assets/models/<id>_a.glb — tools/make_models.gd)를 끼운 인형. 기획서 03 5절 A.
## 관절 인형(puppet3d)의 자세 계산(관절 노드 J)은 그대로 두고 그 메시만 숨긴 뒤, GLB 뼈를 같은 이름의 관절 각도로 돌린다
## (뼈의 쉬는 회전이 0 이라 관절 회전 = 뼈 회전). 무기 · 예고 · 발밑 고리는 인형 것을 그대로 쓴다.
## 바꿔 끼우기(CLAUDE.md 1절 · 2-1절 LSP): update_from(f, dt, frozen) · remove_glasses 를 그대로 물려받는다.
## 화풍: 붓칠 · 먹선 셀(src/view/ink.gd — 2026-11-11, 옛 diffuse toon + next_pass 외곽선을 갈음).

const BONES := ["hips", "spine", "chest", "neck", "head", "sh_r", "el_r", "hand_r", "sh_l", "el_l", "hand_l",
	"th_r", "kn_r", "ft_r", "th_l", "kn_l", "ft_l"]

var model: Node3D
var skel: Skeleton3D
var bone_of := {}


func setup(lk: Dictionary) -> void:
	super.setup(lk)
	_strip_puppet(J["fall"])
	model = load(str(lk["glb"])).instantiate()
	J["body"].add_child(model)
	skel = _find_skeleton(model)
	for n in BONES:
		bone_of[n] = skel.find_bone(n)
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		mi.material_override = _toon()
		mi.material_overlay = Ink.line(true)
	if bone_of.get("head", -1) >= 0:                     # 머리를 작게(Looks.HEAD_K — GLB 는 그대로, 뼈 크기만. _drive 는 자리 · 회전만 쓴다)
		skel.set_bone_pose_scale(bone_of["head"], Vector3.ONE * Looks.HEAD_K)
	_drive(true)


## 관절 인형의 겉모양을 지운다 — 관절(J) 노드 · 무기(손에 붙은 칼)는 남긴다. 숨기기만 하면 관절이 돌 때마다 조각 약 40개에
## 자리 바뀜이 퍼져(그리지 않아도) 한 사람 몫이 컸다(2026-11-11 rc.12 '캐릭터 많이 나오니까 끊김'). 안경 · 풀린 머리 조각도 함께 —
## remove_glasses 는 GLB 에서 아무것도 안 한다(전에도 숨긴 조각이라 보이지 않았다)
func _strip_puppet(n: Node) -> void:
	var list := n.find_children("*", "MeshInstance3D", true, false)
	list.reverse()                                       # 아이부터 — 부모를 먼저 지우면 아이가 함께 사라진다
	for mi in list:
		if not is_instance_valid(mi) or _in_weapon(mi):
			continue
		mi.get_parent().remove_child(mi)
		mi.free()
	glasses = null
	loose = null


func _in_weapon(n: Node) -> bool:
	for w in [weapon_r, weapon_l]:
		if w != null and (w == n or w.is_ancestor_of(n) or n.is_ancestor_of(w)):
			return true
	return false


func _find_skeleton(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var s := _find_skeleton(c)
		if s != null:
			return s
	return null


## 붓칠 · 먹선 셀 재질(src/view/ink.gd — 2026-11-11 Hades 화풍): 꼭짓점 색 바탕 · 세 단 명암 · 빛 색 테두리 빛 + 먹선(화면 픽셀 너비 —
## 멀어도 가늘어지지 않는다). 옛 툰(StandardMaterial3D DIFFUSE_TOON + grow 외곽선)을 갈음
func _toon() -> Material:
	var m := Ink.cel(Color(1, 1, 1), "cloth", true)
	mats.append(m)                                      # 맞음 번쩍임 · 엇엇박 달아오름(인형의 _update_flash)이 이 재질에도
	return m


## 뼈는 한 프레임에 한 번 — 관절 인형 자세(_apply) · 발 붙이기(_ground)가 끝난 뒤(전에는 둘 다 끝에 _drive 를 불러 두 번)
func update_from(f, dt: float, frozen: bool) -> void:
	super.update_from(f, dt, frozen)
	if not frozen:
		_drive()


## 관절 각도 → 뼈. 자리는 골반만 움직인다(관절 인형 _apply — 다른 관절은 지은 자리 그대로)라 all 일 때(setup)만 전부
func _drive(all := false) -> void:
	if skel == null:
		return
	for n in bone_of:
		var i: int = bone_of[n]
		if i < 0:
			continue
		var j: Node3D = J[n]
		if all or n == "hips":
			skel.set_bone_pose_position(i, j.position)
		skel.set_bone_pose_rotation(i, j.quaternion)
