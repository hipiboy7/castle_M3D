extends Node3D
## 부서지는 소품(2026-11-12 사용자 "싸우면서 주변 물건들도 박살나는 연출" · 3장 오락실 "게임기들이 … 부딪히거나 거기로 캐릭이 넘어지면
## 부서지고 깨지도록"). 무대(set3d 계열 · arena3d)가 소품 묶음을 register 하고, 사람이 날아와 부딪히면(main.gd → break_hit) 또는
## 장면 연출(scene.gd fx glass · smash → break_at) 이면 부순다: 원래 묶음은 기울이고 어둡게 · 빛나는 화면은 끄고(또는 깨진 모양으로 바꾸고),
## 조각이 튀어 떨어져 구르다 사라진다. 그림만 — 판정 · 리플레이와 상관없다. 폰 성능: 조각은 한 번에 PIECES_MAX 까지.

const PIECES_PER := 9
const PIECES_MAX := 90
const GRAVITY := 9.8
const LIFE := 2.4
const HIT_PAD := 0.38               # 사람 몸 반지름(소품 반지름에 더함)

var items: Array = []               # {node, at(Vector2), r, kind, after(Node3D | null), broken}
var _pieces: Array = []             # [MeshInstance3D, 속도 Vector3, 돌기 Vector3, 남은 초]
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 7
	process_mode = Node.PROCESS_MODE_PAUSABLE


## 소품 묶음 하나 — at 은 바닥 자리(x, z), r 은 부딪힘 반지름, kind 는 glass(유리 — 장면 fx 로만) · prop(몸으로 부서짐),
## after 는 깨진 뒤 보일 노드(깨진 유리 테 — 처음엔 숨김)
func register(node: Node3D, at: Vector2, r: float, kind := "prop", after: Node3D = null) -> void:
	if after != null:
		after.visible = false
	items.append({"node": node, "at": at, "r": r, "kind": kind, "after": after, "broken": false})


## 사람이 부딪힘(날아옴 · 넘어짐): pos 근처의 부서지지 않은 소품을 부순다 — 부쉈으면 true(소리 · 흔들림은 부른 쪽이)
func break_hit(pos: Vector2, dir: Vector2) -> bool:
	var hit := false
	for it in items:
		if it["broken"] or it["kind"] == "glass":
			continue
		if pos.distance_to(it["at"]) <= float(it["r"]) + HIT_PAD:
			_smash(it, dir)
			hit = true
	return hit


## 장면 연출: 그 자리 반지름 안 소품(종류가 맞으면 — 빈 글이면 모두)을 부순다
func break_at(at: Vector2, r: float, dir: Vector2, kind := "") -> bool:
	var hit := false
	for it in items:
		if it["broken"] or (kind != "" and it["kind"] != kind):
			continue
		if at.distance_to(it["at"]) <= r + float(it["r"]):
			_smash(it, dir)
			hit = true
	return hit


func _smash(it: Dictionary, dir: Vector2) -> void:
	it["broken"] = true
	var n: Node3D = it["node"]
	var mats: Array = []
	var aabb := AABB()
	var first := true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		var mat := m.get_active_material(0)
		if mat != null and mats.size() < 4:
			mats.append(mat)
		var box: AABB = m.global_transform * m.get_aabb()
		aabb = box if first else aabb.merge(box)
		first = false
	if it["after"] != null:
		n.visible = false
		(it["after"] as Node3D).visible = true
	else:
		# 남은 몸: 부딪힌 쪽으로 기울고 주저앉는다 · 빛나는 화면(글로)은 꺼진다
		var tilt := Vector3(dir.y, 0, -dir.x).normalized() if dir.length() > 0.01 else Vector3(1, 0, 0)
		n.rotate(tilt, deg_to_rad(_rng.randf_range(10.0, 22.0)))
		n.scale *= Vector3(1.0, 0.82, 1.0)
		for mi in n.find_children("*", "MeshInstance3D", true, false):
			var m2 := mi as MeshInstance3D
			var sm := m2.get_active_material(0)
			if sm is StandardMaterial3D and (sm as StandardMaterial3D).emission_enabled:
				m2.visible = false
	if first:
		return
	var glass: bool = it["kind"] == "glass"
	var c := aabb.get_center()
	var ext := aabb.size
	var k := 0
	for i in PIECES_PER + (6 if glass else 0):
		if _pieces.size() >= PIECES_MAX:
			_free_piece(0)
		var mi2 := MeshInstance3D.new()
		var bm := BoxMesh.new()
		var s := _rng.randf_range(0.05, 0.16) if not glass else _rng.randf_range(0.04, 0.12)
		bm.size = Vector3(s, s * (0.15 if glass else _rng.randf_range(0.4, 1.0)), s * _rng.randf_range(0.5, 1.2))
		mi2.mesh = bm
		if not mats.is_empty():
			mi2.material_override = mats[k % mats.size()]
		mi2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi2)
		mi2.global_position = c + Vector3(_rng.randf_range(-0.5, 0.5) * ext.x, _rng.randf_range(-0.2, 0.4) * ext.y, _rng.randf_range(-0.5, 0.5) * ext.z)
		var out := Vector3(dir.x, 0, dir.y) * 2.2 + Vector3(_rng.randf_range(-1.6, 1.6), _rng.randf_range(1.8, 3.6), _rng.randf_range(-1.6, 1.6))
		_pieces.append([mi2, out, Vector3(_rng.randf_range(-9, 9), _rng.randf_range(-9, 9), _rng.randf_range(-9, 9)), LIFE + _rng.randf_range(0.0, 0.8)])
		k += 1


func _process(dt: float) -> void:
	var i := 0
	while i < _pieces.size():
		var p: Array = _pieces[i]
		var mi: MeshInstance3D = p[0]
		var v: Vector3 = p[1]
		v.y -= GRAVITY * dt
		var at := mi.position + v * dt
		if at.y < 0.03:
			at.y = 0.03
			v = Vector3(v.x * 0.45, -v.y * 0.25, v.z * 0.45)          # 바닥에 튀고 미끄러진다
			p[2] = (p[2] as Vector3) * 0.5
		mi.position = at
		mi.rotation += (p[2] as Vector3) * dt
		p[1] = v
		p[3] = float(p[3]) - dt
		if float(p[3]) < 0.4:
			mi.scale = Vector3.ONE * maxf(0.01, float(p[3]) / 0.4)
		if float(p[3]) <= 0.0:
			_free_piece(i)
			continue
		i += 1


func _free_piece(i: int) -> void:
	(_pieces[i][0] as Node3D).queue_free()
	_pieces.remove_at(i)
