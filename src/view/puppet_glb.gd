extends "res://src/view/puppet3d.gd"
## 그림 A v2/v3 — 실사 PBR 휴머노이드(MPFB2 CC0 + CC0 모캡 블렌딩) 및 기존 툰 GLB 양쪽 호환.
##  - GLB 안에 "PBR_Body" 메시가 있으면 실사 PBR 모드: 카툰 외곽선(ink_line)과 2단계 셀 셰이더를 끄고
##    원본 PBR(Albedo + Normal + Roughness + 은은한 느와르 림 라이트)을 유지, 실제 인체 뼈 위치와
##    BoneAttachment3D 무기 장착, CC0 모션캡처(MocapDriver) 블렌딩을 적용한다.
##  - 기존 툰 GLB("Body")는 기존 풀컬러 2D 얼굴 아틀라스 + 부위별 셀 셰이딩 + 표정 전환을 그대로 유지한다.
## 바꿔 끼우기(LSP): update_from(f, dt, frozen) · remove_glasses 그대로 호환.

const SHADOW_SHADER = preload("res://src/view/shaders/contact_shadow.gdshader")
const WEBTOON_SHADER = preload("res://src/view/shaders/webtoon_3d.gdshader")
const Mocap = preload("res://src/view/mocap_driver.gd")
const BONES := ["hips", "spine", "chest", "neck", "head", "sh_r", "el_r", "hand_r", "sh_l", "el_l", "hand_l",
	"th_r", "kn_r", "ft_r", "th_l", "kn_l", "ft_l"]

var model: Node3D
var skel: Skeleton3D
var bone_of := {}
var _body_mat: ShaderMaterial = null
var _last_expr := -1
var _shadow_disc: MeshInstance3D = null
var _is_pbr := false
var _is_webtoon := false
var _hips_rest_y := PELVIS_H
var _mocap: Mocap = null
var _mocap_sample := {}


func setup(lk: Dictionary) -> void:
	super.setup(lk)
	_strip_puppet(J["fall"])
	model = load(str(lk["glb"])).instantiate()
	J["body"].add_child(model)
	skel = _find_skeleton(model)
	for n in BONES:
		bone_of[n] = skel.find_bone(n)
	var meshes: Array = model.find_children("*", "MeshInstance3D", true, false)
	_is_webtoon = meshes.any(func(mi): return mi.name == "Webtoon_Body")
	_is_pbr = not _is_webtoon and meshes.any(func(mi): return mi.name == "PBR_Body")
	if _is_webtoon:
		_setup_webtoon(meshes)
	elif _is_pbr:
		_setup_pbr(meshes)
	else:
		_setup_toon(meshes)
	_add_contact_shadow(float(lk.get("wide", 1.0)) * float(lk.get("scale", 1.0)))
	_drive(true)


## 3단계 원작 기반 만화 3D 파일럿("Webtoon_Body") — 원작 얼굴 투영 + 3D 조각 만화 헤어 + 느와르 셀/해칭 셰이더 + 먹선 윤곽 + CC0 모캡
func _setup_webtoon(meshes: Array) -> void:
	var hi: int = int(bone_of.get("hips", -1))
	if hi >= 0:
		_hips_rest_y = skel.get_bone_rest(hi).origin.y
	_mocap = Mocap.new()
	var line_mat := Ink.line(true, false, null, false)
	line_mat.set_shader_parameter("width", 2.0)
	for mi in meshes:
		var m_inst := mi as MeshInstance3D
		var is_glasses := m_inst.name == "Glasses"
		if is_glasses:
			glasses = m_inst
		var mesh: Mesh = m_inst.mesh
		if mesh == null:
			continue
		for s in mesh.get_surface_count():
			var src: Material = m_inst.get_active_material(s)
			var mname := (src.resource_name if src != null else "").to_lower()
			var kind := 0
			if is_glasses or mname.contains("wt_glass"):
				kind = 3
			elif mname.contains("wt_face") or mname.contains("wt_skin") or mname.contains("skin"):
				kind = 1
			elif mname.contains("wt_hair") or mname.contains("hair"):
				kind = 2
			elif mname.contains("wt_leather") or mname.contains("holster") or mname.contains("shoe"):
				kind = 4
			var sm := ShaderMaterial.new()
			sm.shader = WEBTOON_SHADER
			sm.set_shader_parameter("use_lut", true)
			sm.set_shader_parameter("ink_lut", Ink.LUT)
			sm.set_shader_parameter("mat_kind", kind)
			if src is BaseMaterial3D:
				var bm := src as BaseMaterial3D
				sm.set_shader_parameter("albedo", bm.albedo_color)
				if bm.albedo_texture != null:
					sm.set_shader_parameter("use_tex", true)
					sm.set_shader_parameter("tex", bm.albedo_texture)
				else:
					sm.set_shader_parameter("use_tex", false)
			else:
				sm.set_shader_parameter("use_tex", false)
			m_inst.set_surface_override_material(s, sm)
			mats.append(sm)
		if not is_glasses:
			m_inst.material_overlay = line_mat
	_reparent_weapon_to_bone(weapon_r, "hand_r", false)
	_reparent_weapon_to_bone(weapon_l, "hand_l", false)


func _setup_pbr(meshes: Array) -> void:
	var hi: int = int(bone_of.get("hips", -1))
	if hi >= 0:
		_hips_rest_y = skel.get_bone_rest(hi).origin.y
	_mocap = Mocap.new()
	for mi in meshes:
		var m_inst := mi as MeshInstance3D
		if m_inst.name == "Glasses":
			glasses = m_inst
		var mesh: Mesh = m_inst.mesh
		if mesh == null:
			continue
		for s in mesh.get_surface_count():
			var src: Material = m_inst.get_active_material(s)
			if src is StandardMaterial3D:
				var pm := (src as StandardMaterial3D).duplicate() as StandardMaterial3D
				pm.diffuse_mode = BaseMaterial3D.DIFFUSE_BURLEY
				pm.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
				pm.rim_enabled = true
				pm.rim = 0.24
				pm.rim_tint = 0.35
				if pm.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR or pm.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_HASH:
					pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
					pm.alpha_scissor_threshold = 0.35
					pm.cull_mode = BaseMaterial3D.CULL_DISABLED
				m_inst.set_surface_override_material(s, pm)
				mats.append(pm)
	_reparent_weapon_to_bone(weapon_r, "hand_r")
	_reparent_weapon_to_bone(weapon_l, "hand_l")


func _reparent_weapon_to_bone(w: Node3D, bname: String, strip_ink := true) -> void:
	if w == null or skel == null or int(bone_of.get(bname, -1)) < 0:
		return
	var ba := BoneAttachment3D.new()
	ba.name = "Attach_" + bname
	ba.bone_name = bname
	skel.add_child(ba)
	var old_parent := w.get_parent()
	if old_parent != null:
		old_parent.remove_child(w)
	ba.add_child(w)
	w.position = Vector3(0, -0.05, 0)
	if strip_ink:
		for mi in w.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).material_overlay = null


func _setup_toon(meshes: Array) -> void:
	var line_cache := {}
	for mi in meshes:
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
	var use_mocap := _is_pbr or _is_webtoon
	if not use_mocap:
		_update_expression(f)
	if _shadow_disc != null:
		var air_k := clampf(1.0 - float(f.air) * 0.45, 0.25, 1.0)
		_shadow_disc.position.y = 0.012 - float(f.air) - _lift
		_shadow_disc.scale = Vector3.ONE * air_k
		_shadow_disc.visible = f.state != "dead"
	if not frozen:
		if use_mocap and _mocap != null:
			var armed := weapon_r != null or weapon_l != null
			_mocap_sample = _mocap.sample(f, dt, armed, calm or _calm > 0.5)
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
	if _is_pbr or _is_webtoon:
		var mw := float(_mocap_sample.get("weight", 0.0))
		var mrot: Dictionary = _mocap_sample.get("rot", {})
		var mdy := float(_mocap_sample.get("hips_dy", 0.0))
		for n in bone_of:
			var i: int = bone_of[n]
			if i < 0:
				continue
			var j: Node3D = J[n]
			if n == "hips":
				var proc_dy := j.position.y - PELVIS_H
				# 바닥 접지 · 의자 앉기 높이는 puppet_pose(_ground) 기준을 유지하고, 모캡 수직 흔들림은 보행/전투 시 미세하게만 반영
				var dy := proc_dy + (mdy * 0.22 * mw if absf(proc_dy) < 0.20 else 0.0)
				skel.set_bone_pose_position(i, Vector3(0.0, _hips_rest_y + dy, j.position.z))
			var q: Quaternion = j.quaternion
			if mw > 0.001 and mrot.has(n):
				q = q.slerp(mrot[n] as Quaternion, mw)
			skel.set_bone_pose_rotation(i, q)
		return
	for n in bone_of:
		var i: int = bone_of[n]
		if i < 0:
			continue
		var j: Node3D = J[n]
		if all or n == "hips":
			skel.set_bone_pose_position(i, j.position)
		skel.set_bone_pose_rotation(i, j.quaternion)
