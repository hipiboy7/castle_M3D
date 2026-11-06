extends "res://src/view/puppet3d.gd"
## 그림 B — 3D 무대 위 도트 빌보드(기획서 03 5절 B). 도트 시트(assets/sprites/<id>_b.png · .json — tools/make_sprites.gd)에서
## 상태 · 공격 단계 · 방향(8)에 맞는 칸을 골라 카메라를 보는 판(Sprite3D)에 붙인다. 관절 인형의 자세 계산 · 예고 · 발밑 고리는
## 그대로 물려받고(LSP — update_from · remove_glasses) 인형 · 무기 메시는 숨긴다.

var spr: Sprite3D
var shadow: MeshInstance3D
var frames := {}
var cell := 80
var _dir := 0


func setup(lk: Dictionary) -> void:
	super.setup(lk)
	_hide_all(J["fall"])
	var base := str(lk["dots"])
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base + ".json"))
	cell = int(meta["cell"])
	for i in meta["frames"].size():
		frames[str(meta["frames"][i])] = i
	spr = Sprite3D.new()
	spr.texture = load(base + ".png")
	spr.region_enabled = true
	spr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	spr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	spr.pixel_size = float(meta["world_h"]) / cell
	spr.position = Vector3(0, float(meta["look_y"]), 0)
	spr.shaded = false
	spr.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	add_child(spr)
	var disk := CylinderMesh.new()                       # 발밑 그림자(빌보드는 그림자를 안 드리운다)
	disk.top_radius = 0.34
	disk.bottom_radius = 0.34
	disk.height = 0.01
	shadow = MeshInstance3D.new()
	shadow.mesh = disk
	var sm := StandardMaterial3D.new()
	sm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.albedo_color = Color(0, 0, 0, 0.45)
	shadow.material_override = sm
	shadow.position = Vector3(0, 0.01, 0)
	add_child(shadow)
	_show("idle")


func _hide_all(n: Node) -> void:
	for c in n.get_children():
		if c is MeshInstance3D:
			c.visible = false
		_hide_all(c)


func update_from(f, dt: float, frozen: bool) -> void:
	super.update_from(f, dt, frozen)
	if frozen:
		return
	_dir = posmod(roundi(rad_to_deg(yaw) / 45.0), 8)
	_show(_frame_for(f))
	spr.modulate = Color(1.6, 1.4, 1.3) if f.flash > 0 and (f.flash / 2) % 2 == 0 else Color.WHITE


func _frame_for(f) -> String:
	if victory:
		return "idle"
	match f.state:
		"idle", "move":
			if f.speed_now > 0.2:
				return "walk%d" % (int(phase / (TAU / 4.0)) % 4)
			return "idle"
		"attack":
			var mv: Dictionary = f.move
			var key := shape_key(mv)
			var su := int(mv["startup"])
			var ac := int(mv["active"])
			var part := "W" if f.t <= su else ("S" if f.t <= su + ac + 2 else "F")
			if frames.has(key + ":" + part):
				return key + ":" + part
			if frames.has("slash:" + part):
				return "slash:" + part
			return "idle"
		"parry", "parry_end":
			return "parry"
		"hitstun", "recoil":
			return "hitstun"
		"stun":
			return "stun"
		"stagger":
			return "stagger"
		"roll":
			return "roll%d" % clampi(f.t * 3 / 20, 0, 2)
		"down", "dead":
			return "down" if f.t > 6 else "hitstun"
	return "idle"


func _show(name: String) -> void:
	var c: int = frames.get(name, 0)
	spr.region_rect = Rect2(c * cell, _dir * cell, cell, cell)
