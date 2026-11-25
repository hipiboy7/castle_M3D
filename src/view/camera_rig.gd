extends Camera3D
## 3/4 액션 쿼터뷰 카메라 — 두 사람 사이(김신 쪽으로 조금)를 따라가고, 멀어지면 물러나고, 흔들림 · 결착 줌을 더한다.
## 2026-11-25 앵글 하향(57° → ~35° 전투 / ~20° 컷신): 정수리만 보이던 탑뷰에서 벗어나 캐릭터 얼굴 · 상반신 · 무기 · 체격이 뚜렷이 보이게.
## 망원 화각(FOV 30)을 유지해 원근 왜곡을 줄이고 그래픽 노블 구도를 만든다.

const OFFSET := Vector3(0, 8.8, 12.4)                # 전투 시 ~35.4° 액션 쿼터뷰(거리 15.2m)
const OFFSET_SCENE := Vector3(0, 4.2, 11.8)          # 장면 연출(대화) 시 ~19.6° 눈높이 시네마틱 앵글(거리 12.5m)
const FOV := 30.0
const USER_ZOOM_MIN := 0.55
const USER_ZOOM_MAX := 1.45

var focus := Vector3.ZERO
var dist_k := 1.0
var zoom := 1.0
var user_zoom := 1.0                                 # 사용자 줌 배율(작을수록 넓게 · 멀리, 클수록 가깝게 — Save["zoom"])
var scene_mode := false
var _scene_k := 0.0
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	fov = FOV
	near = 0.3
	far = 120.0
	rng.seed = 5


func follow(a: Vector3, b: Vector3, dt: float, shake: int) -> void:
	_aim(a.lerp(b, 0.42), a.distance_to(b), dt, shake)


## 여럿(11장): 조작하는 사람(lead) 둘레 7.5m 안 사람들을 한 화면에 — 그 묶음 가운데와 lead 사이를 보고, 퍼진 만큼 물러난다
func follow_group(lead: Vector3, pts: Array, dt: float, shake: int) -> void:
	var lo := Vector2(lead.x, lead.z)
	var hi := lo
	for p in pts:
		if p.distance_to(lead) < 7.5:
			lo = lo.min(Vector2(p.x, p.z))
			hi = hi.max(Vector2(p.x, p.z))
	var c := (lo + hi) * 0.5
	_aim(Vector3(lerpf(lead.x, c.x, 0.6), 0, lerpf(lead.z, c.y, 0.6)), (hi - lo).length() * 0.85, dt, shake)


func _aim(mid: Vector3, sep: float, dt: float, shake: int) -> void:
	var target_s := 1.0 if scene_mode else 0.0
	_scene_k = lerpf(_scene_k, target_s, 1.0 - exp(-3.5 * dt))
	var want_combat := clampf(0.56 + sep * 0.045, 0.64, 1.02)
	var want_scene := clampf(0.68 + sep * 0.04, 0.74, 1.02)
	var want := lerpf(want_combat, want_scene, _scene_k) * zoom / maxf(user_zoom, USER_ZOOM_MIN)
	focus = focus.lerp(mid, 1.0 - exp(-5.0 * dt))
	dist_k = lerpf(dist_k, want, 1.0 - exp(-3.0 * dt))
	zoom = lerpf(zoom, 1.0, 1.0 - exp(-1.5 * dt))
	var sh := Vector3.ZERO
	if shake > 0:
		sh = Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * 0.03 * shake
	var off := OFFSET.lerp(OFFSET_SCENE, _scene_k)
	var look_y := lerpf(1.05, 1.24, _scene_k)
	position = focus + off * dist_k + sh
	look_at(focus + Vector3(0, look_y, 0) + sh * 0.4, Vector3.UP)


func snap(a: Vector3, b: Vector3) -> void:
	focus = a.lerp(b, 0.42)
	var off := OFFSET.lerp(OFFSET_SCENE, _scene_k)
	var look_y := lerpf(1.05, 1.24, _scene_k)
	dist_k = (0.74 if scene_mode else 0.72) / maxf(user_zoom, USER_ZOOM_MIN)
	position = focus + off * dist_k
	look_at(focus + Vector3(0, look_y, 0), Vector3.UP)


func set_user_zoom(z: float) -> void:
	user_zoom = clampf(z, USER_ZOOM_MIN, USER_ZOOM_MAX)


func punch_zoom(k: float) -> void:
	zoom = minf(zoom, k)
