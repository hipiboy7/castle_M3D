extends "res://src/view/puppet3d.gd"
## 그림 A v2 — 풀컬러 2D 웹툰 얼굴 아틀라스 + 부위별 재질(피부 · 머리 · 옷 · 가죽) + 동적 표정 + 안경/풀린 머리 분리 서브메시 + 발밑 콘택트 섀도.
## 관절 인형(puppet3d)의 자세 계산(관절 노드 J)은 그대로 두고 메시만 숨긴 뒤, GLB 뼈를 같은 이름의 관절 각도로 돌린다.
## 바꿔 끼우기(LSP): update_from(f, dt, frozen) · remove_glasses 그대로 호환.

const SHADOW_SHADER = preload("res://src/view/shaders/contact_shadow.gdshader")
const BONES := ["hips", "spine", "chest", "neck", "head", "sh_r", "el_r", "hand_r", "sh_l", "el_l", "hand_l",
	"th_r", "kn_r", "ft_r", "th_l", "kn_l", "ft_l"]

var model: Node3D
var skel: Skeleton3D
var bone_of := {}
var _body_mat: ShaderMaterial = null
var _last_expr := -1
var _shadow_disc: MeshInstance3D = null


func setup(lk: Dictionary) -> void:
	super.setup(lk)
	_strip_puppet(J["fall"])
	model = load(str(lk["glb"])).instantiate()
	J["body"].add_child(model)
	skel = _find_skeleton(model)
	for n in BONES:
		bone_of[n] = skel.find_bone(n)
	var line_cache := {}
	for mi in model.find_children("*", "MeshInstance3D", true, false):
		var m_inst := mi as MeshInstance3D
		if m_inst.name == "Glasses":
			glasses = m_inst
			var gm := _glass_mat(m_inst)
			m_inst.material_override = gm
			continue
		if m_inst.name == "HairLoose":
			loose = m_inst
			m_inst.visible = false
		var src: Material = m_inst.get_active_material(0)
		var tex: Texture2D = src.albedo_texture if src is BaseMaterial3D else null
		var cm := _toon(tex)
		m_inst.material_override = cm
		if m_inst.name == "Body":
			_body_mat = cm
		m_inst.material_overlay = Ink.line(true, false, line_cache, true)
	if bone_of.get("head", -1) >= 0:
		skel.set_bone_pose_scale(bone_of["head"], Vector3.ONE * Looks.HEAD_K)
	_add_contact_shadow(float(lk.get("wide", 1.0)) * float(lk.get("scale", 1.0)))
	_drive(true)


## 발밑 콘택트 섀도 — 캐릭터가 바닥에 묵직하게 접지되어 보이게(부드러운 원형 그늘, 그림자 패스 없음)
func _add_contact_shadow(rad_k: float) -> void:
	if _shadow_disc != null:
		return
	var q := QuadMesh.new()
	var d := clampf(0.86 * rad_k, 0.72, 1.18)
	q.size = Vector2(d, d)
	var sm := ShaderMaterial.new()
	sm.shader = SHADOW_SHADER
	_shadow_disc = MeshInstance3D.new()
	_shadow_disc.mesh = q
	_shadow_disc.material_override = sm
	_shadow_disc.rotation_degrees.x = -90.0
	_shadow_disc.position = Vector3(0, 0.012, 0)
	_shadow_disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_shadow_disc)


func _glass_mat(mi: MeshInstance3D) -> Material:
	var src: Material = mi.get_active_material(0)
	var m := Ink.cel(Color.WHITE, "metal", true)
	if src is BaseMaterial3D and src.albedo_texture != null:
		m.set_shader_parameter("use_tex", true)
		m.set_shader_parameter("tex", src.albedo_texture)
	mats.append(m)
	return m


func _strip_puppet(n: Node) -> void:
	var list := n.find_children("*", "MeshInstance3D", true, false)
	list.reverse()
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


func _toon(tex: Texture2D = null) -> ShaderMaterial:
	var m := Ink.char_mat(tex) if tex != null else Ink.cel(Color(1, 1, 1), "cloth", true)
	mats.append(m)
	return m


func update_from(f, dt: float, frozen: bool) -> void:
	super.update_from(f, dt, frozen)
	_update_expression(f)
	if _shadow_disc != null:
		var air_k := clampf(1.0 - float(f.air) * 0.45, 0.25, 1.0)
		_shadow_disc.position.y = 0.012 - float(f.air) - _lift
		_shadow_disc.scale = Vector3.ONE * air_k
		_shadow_disc.visible = f.state != "dead"
	if not frozen:
		_drive()


## 전투/장면 상태에 따른 실시간 얼굴 표정 전환(0 평소 · 1 전투/분노 · 2 피격/고통 · 3 기절/눈감음)
func _update_expression(f) -> void:
	if _body_mat == null:
		return
	var expr := 0
	var st := str(f.state)
	var ps := str(f.pose)
	if st == "dead" or st == "down" or ps == "lie_bed":
		expr = 3
	elif st in ["hitstun", "recoil", "stagger", "stun"]:
		expr = 2
	elif st == "attack" or st == "parry":
		expr = 1
	if expr != _last_expr:
		_last_expr = expr
		Ink.set_expression(_body_mat, expr)


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
