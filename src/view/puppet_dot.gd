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
			return attack_frame(key, part)
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


## 시트에 없는 모양은 가까운 모양으로 대신한다(왼손 → 오른손 · 같은 갈래), 끝까지 없으면 베기 · 주먹 · 서 있는 칸.
## 새 인물의 기술이 시트보다 먼저 생겨도(tools/make_sprites.gd 를 다시 돌리기 전) 그림이 비지 않게
const NEAR := {
	"punch": ["punch_L", "thrust"], "punch_L": ["punch", "thrust"], "shot": ["shot_L", "punch", "thrust"],
	"shot_L": ["shot", "punch_L", "punch"], "slash_back_L": ["slash_back_R", "slash"], "slash_back_R": ["slash_back_L", "slash"],
	"thrust": ["thrust_low", "punch"], "thrust_low": ["thrust", "punch"], "offbeat": ["thrust", "punch"],
	"offbeat_rev": ["offbeat", "thrust"], "cross": ["slash", "punch"], "spin": ["sidekick", "slash"],
	"sidekick": ["axe", "spin", "punch"], "axe": ["sidekick", "punch"],
	# 2026-11-10 새 모양(시트는 다시 구울 때 생긴다 — 그 전에는 가까운 갈래: 주먹 · 발 · 칼 · 총)
	"jab": ["punch"], "straight": ["punch"], "hook": ["punch"], "uppercut": ["punch"], "body_blow": ["punch"],
	"elbow": ["punch"], "palm": ["punch"], "backfist": ["punch"], "guard_counter": ["punch"], "hammer_fist": ["punch"],
	"headbutt": ["punch"], "grab": ["punch"], "choke": ["punch"], "throw_slam": ["cross", "punch"],
	"two_hand_slam": ["cross", "punch"], "shoulder_ram": ["punch"], "tackle": ["thrust_low", "punch"], "toss": ["punch"],
	"knee": ["sidekick", "punch"], "flying_knee": ["sidekick", "punch"], "front_kick": ["sidekick", "punch"],
	"round_kick": ["sidekick", "spin", "punch"], "low_kick": ["sidekick", "punch"], "spin_back_kick": ["sidekick", "spin"],
	"axe_kick": ["axe", "sidekick"], "flying_kick": ["sidekick", "punch"], "sweep": ["spin", "sidekick"],
	"stomp": ["axe", "sidekick"], "overhead_chop": ["cross", "slash"], "rising_slash": ["slash_back_R", "slash"],
	"reverse_stab": ["thrust", "slash"], "draw_shot": ["shot", "punch"], "duck": [], "weave": [], "sidestep": [],
}


func attack_frame(key: String, part: String) -> String:
	if frames.has(key + ":" + part):
		return key + ":" + part
	var base := key.trim_suffix("_L")                    # 새 모양의 왼쪽 판은 시트에 없으면 오른쪽 · 가까운 갈래로
	if base != key and not NEAR.has(key):
		key = base
	if NEAR.has(key) and (NEAR[key] as Array).is_empty() and not frames.has(key + ":" + part):
		return "idle"                                   # 피하기(숙이기 · 흔들기 · 비켜서기)는 칼을 휘두르는 칸 대신 서 있는 칸
	for k in [key] + NEAR.get(key, []) + ["slash", "punch"]:
		if frames.has(str(k) + ":" + part):
			return str(k) + ":" + part
	return "idle"


func _show(name: String) -> void:
	var c: int = frames.get(name, 0)
	spr.region_rect = Rect2(c * cell, _dir * cell, cell, cell)
