extends RefCounted
## CC0 휴머노이드 모션캡처 드라이버 (Quaternius Universal Animation Library CC0 -> 17본 리타게팅).
## assets/animations/humanoid_cc0.glb 를 한 번만 읽어 정적 캐시로 공유(노드 누수 · 중복 로드 0).
## 상태별 클립 선택(pick_clip)은 순수 함수로 분리해 tests/unit/test_mocap.gd 에서 검증한다(SRP · TDD).

const LIB_PATH := "res://assets/animations/humanoid_cc0.glb"
const CROSSFADE_SECS := 0.14

static var _loaded := false
static var _clips := {}              # clip_name -> {"anim": Animation, "len": float, "rot": {bone: track_i}, "hips_pos": int}

var _cur_clip := ""
var _cur_t := 0.0
var _cur_loop := true
var _prev_clip := ""
var _prev_t := 0.0
var _prev_loop := true
var _fade := 1.0
var _last_state := ""
var _last_move := ""


## 상태 · 이동 속도 · 자세 · 기술 모양 → 재생할 CC0 모캡 클립과 블렌드 가중치(순수 함수)
static func pick_clip(state: String, speed: float, crouching: bool, pose: String, move_shape: String,
		has_weapon: bool, calm: bool) -> Dictionary:
	match state:
		"dead":
			return {"clip": "Death01", "loop": false, "speed": 1.0, "weight": 0.90}
		"down":
			return {"clip": "Death01", "loop": false, "speed": 0.9, "weight": 0.72}
		"hitstun":
			return {"clip": "Hit_Chest", "loop": false, "speed": 1.35, "weight": 0.85}
		"recoil":
			return {"clip": "Hit_Head", "loop": false, "speed": 1.25, "weight": 0.72}
		"roll":
			return {"clip": "Roll", "loop": false, "speed": 1.45, "weight": 0.82}
		"jump":
			return {"clip": "Jump", "loop": true, "speed": 1.0, "weight": 0.75}
		"attack":
			var sh := move_shape.trim_suffix("_L")
			if sh in ["slash", "slash_back", "slash_back_R", "overhead_chop", "rising_slash", "thrust", "reverse_stab"]:
				return {"clip": "Sword_Attack", "loop": false, "speed": 1.4, "weight": 0.55}
			if sh in ["punch", "jab"]:
				return {"clip": "Punch_Jab", "loop": false, "speed": 1.5, "weight": 0.60}
			if sh in ["hook", "upper", "cross"]:
				return {"clip": "Punch_Cross", "loop": false, "speed": 1.35, "weight": 0.60}
			return {"clip": "", "loop": false, "speed": 1.0, "weight": 0.0}
		"idle", "move":
			if pose == "sit" and speed < 0.2:
				return {"clip": "Sitting_Idle", "loop": true, "speed": 1.0, "weight": 0.92}
			if pose != "" and speed < 0.2:
				return {"clip": "", "loop": false, "speed": 1.0, "weight": 0.0}
			if crouching:
				if speed >= 0.2:
					return {"clip": "Crouch_Fwd", "loop": true, "speed": clampf(speed / 1.5, 0.75, 1.4), "weight": 0.90}
				return {"clip": "Crouch_Idle", "loop": true, "speed": 1.0, "weight": 0.90}
			if speed > 4.2:
				return {"clip": "Sprint", "loop": true, "speed": clampf(speed / 4.8, 0.85, 1.45), "weight": 0.92}
			if speed > 2.4:
				return {"clip": "Jog_Fwd", "loop": true, "speed": clampf(speed / 3.4, 0.85, 1.35), "weight": 0.92}
			if speed >= 0.2:
				return {"clip": "Walk_Formal" if calm else "Walk", "loop": true,
					"speed": clampf(speed / 1.7, 0.75, 1.4), "weight": 0.90}
			if has_weapon and not calm:
				return {"clip": "Sword_Idle", "loop": true, "speed": 1.0, "weight": 0.86}
			return {"clip": "Idle", "loop": true, "speed": 1.0, "weight": 0.92}
	return {"clip": "", "loop": false, "speed": 1.0, "weight": 0.0}


static func ensure_loaded() -> bool:
	if _loaded:
		return not _clips.is_empty()
	_loaded = true
	if not ResourceLoader.exists(LIB_PATH):
		return false
	var scene = load(LIB_PATH)
	if not (scene is PackedScene):
		return false
	var inst: Node = scene.instantiate()
	var ap: AnimationPlayer = null
	for n in inst.find_children("*", "AnimationPlayer", true, false):
		ap = n as AnimationPlayer
		break
	if ap != null:
		for raw_name in ap.get_animation_list():
			var anim: Animation = ap.get_animation(raw_name)
			if anim == null or anim.length <= 0.0:
				continue
			var clean := String(raw_name).get_slice("/", String(raw_name).get_slice_count("/") - 1)
			var rot_map := {}
			var hips_pos := -1
			for ti in anim.get_track_count():
				var tp := anim.track_get_path(ti)
				var sub := tp.get_concatenated_subnames()
				if sub == "":
					continue
				var ttype := anim.track_get_type(ti)
				if ttype == Animation.TYPE_ROTATION_3D:
					rot_map[String(sub)] = ti
				elif ttype == Animation.TYPE_POSITION_3D and String(sub) == "hips":
					hips_pos = ti
			if not rot_map.is_empty():
				_clips[clean] = {"anim": anim.duplicate(), "len": anim.length, "rot": rot_map, "hips_pos": hips_pos}
	inst.free()
	return not _clips.is_empty()


static func clip_names() -> Array:
	ensure_loaded()
	return _clips.keys()


## 매 프레임 상태에 맞는 모캡 샘플을 계산해 { "weight": float, "rot": {bone: Quaternion}, "hips_dy": float } 반환
func sample(f, dt: float, has_weapon: bool, calm: bool) -> Dictionary:
	if not ensure_loaded():
		return {"weight": 0.0, "rot": {}, "hips_dy": 0.0}
	var st := str(f.state)
	var mv_shape := str(f.move.get("shape", "")) if (st == "attack" and f.move is Dictionary) else ""
	var mv_name := str(f.move.get("name", "")) if (st == "attack" and f.move is Dictionary) else ""
	var pick := pick_clip(st, float(f.speed_now), bool(f.crouching), str(f.pose), mv_shape, has_weapon, calm)
	var want := str(pick["clip"])
	if want != "" and not _clips.has(want):
		want = ""
	var restart := (st != _last_state) or (st == "attack" and mv_name != _last_move and int(f.t) <= 2)
	_last_state = st
	_last_move = mv_name

	if want != _cur_clip or (restart and not bool(pick["loop"])):
		_prev_clip = _cur_clip
		_prev_t = _cur_t
		_prev_loop = _cur_loop
		_cur_clip = want
		_cur_t = 0.0
		_cur_loop = bool(pick["loop"])
		_fade = 0.0 if _prev_clip != "" else 1.0

	var spd := float(pick["speed"])
	_cur_t = _advance(_cur_clip, _cur_t, dt * spd, _cur_loop)
	if _fade < 1.0:
		_prev_t = _advance(_prev_clip, _prev_t, dt, _prev_loop)
		_fade = minf(1.0, _fade + dt / CROSSFADE_SECS)

	var w := float(pick["weight"])
	if _cur_clip == "" and _prev_clip == "":
		return {"weight": 0.0, "rot": {}, "hips_dy": 0.0}
	if _cur_clip == "":
		w *= (1.0 - _fade)
		if w <= 0.005:
			return {"weight": 0.0, "rot": {}, "hips_dy": 0.0}
		var prev_s := _eval_clip(_prev_clip, _prev_t)
		return {"weight": w, "rot": prev_s["rot"], "hips_dy": prev_s["hips_dy"]}

	var cur_s := _eval_clip(_cur_clip, _cur_t)
	if _fade >= 0.999 or _prev_clip == "" or not _clips.has(_prev_clip):
		return {"weight": w, "rot": cur_s["rot"], "hips_dy": cur_s["hips_dy"]}

	var prev_s2 := _eval_clip(_prev_clip, _prev_t)
	var out_rot := {}
	for b in cur_s["rot"]:
		var qc: Quaternion = cur_s["rot"][b]
		var qp: Quaternion = prev_s2["rot"].get(b, Quaternion.IDENTITY)
		out_rot[b] = qp.slerp(qc, _fade)
	var dy := lerpf(float(prev_s2["hips_dy"]), float(cur_s["hips_dy"]), _fade)
	return {"weight": w, "rot": out_rot, "hips_dy": dy}


static func _advance(clip: String, t: float, dt: float, loop: bool) -> float:
	if clip == "" or not _clips.has(clip):
		return 0.0
	var length: float = float(_clips[clip]["len"])
	if length <= 0.001:
		return 0.0
	var nt := t + dt
	return fposmod(nt, length) if loop else clampf(nt, 0.0, length)


static func _eval_clip(clip: String, t: float) -> Dictionary:
	var c: Dictionary = _clips[clip]
	var anim: Animation = c["anim"]
	var rot := {}
	for b in c["rot"]:
		var ti: int = int(c["rot"][b])
		rot[b] = anim.rotation_track_interpolate(ti, t)
	var dy := 0.0
	var hi: int = int(c["hips_pos"])
	if hi >= 0:
		var pv: Vector3 = anim.position_track_interpolate(hi, t)
		dy = clampf(pv.y, -0.55, 0.35)
	return {"rot": rot, "hips_dy": dy}
