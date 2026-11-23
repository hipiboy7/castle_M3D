extends Camera3D
## 3/4 탑뷰 카메라 — 두 사람 사이(김신 쪽으로 조금)를 따라가고, 멀어지면 물러나고, 흔들림 · 결착 줌을 더한다.
## 높이 · 거리 OFFSET 으로 내려다보는 각이 약 55도. 2026-11-11 Hades 화풍(사용자 1 ~ 5 추천대로 — 4. 카메라 각): 화각을 38 → FOV 로 좁히고
## 그만큼 멀리 — 원근이 납작해져(망원) 그린 그림처럼 보이고, 인물 크기는 그대로(옛 화각 38 · OFFSET (0, 10, 7) 과 같은 화면 높이).

const OFFSET := Vector3(0, 13.0, 8.5)
const OFFSET_SCENE := Vector3(0, 6.4, 10.6)          # 장면 연출(대화) 시 낮은 31° 시네마틱 앵글 — 얼굴 · 표정 · 코트가 선명하게 보인다
const FOV := 30.0

var focus := Vector3.ZERO
var dist_k := 1.0
var zoom := 1.0
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
	var want_combat := clampf(0.5 + sep * 0.045, 0.56, 0.95)
	var want_scene := clampf(0.62 + sep * 0.04, 0.66, 0.92)
	var want := lerpf(want_combat, want_scene, _scene_k) * zoom
	focus = focus.lerp(mid, 1.0 - exp(-5.0 * dt))
	dist_k = lerpf(dist_k, want, 1.0 - exp(-3.0 * dt))
	zoom = lerpf(zoom, 1.0, 1.0 - exp(-1.5 * dt))
	var sh := Vector3.ZERO
	if shake > 0:
		sh = Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * 0.03 * shake
	var off := OFFSET.lerp(OFFSET_SCENE, _scene_k)
	var look_y := lerpf(0.9, 1.15, _scene_k)
	position = focus + off * dist_k + sh
	look_at(focus + Vector3(0, look_y, 0) + sh * 0.4, Vector3.UP)


func snap(a: Vector3, b: Vector3) -> void:
	focus = a.lerp(b, 0.42)
	var off := OFFSET.lerp(OFFSET_SCENE, _scene_k)
	var look_y := lerpf(0.9, 1.15, _scene_k)
	position = focus + off
	look_at(focus + Vector3(0, look_y, 0), Vector3.UP)


func punch_zoom(k: float) -> void:
	zoom = minf(zoom, k)
