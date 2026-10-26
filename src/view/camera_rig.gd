extends Camera3D
## 3/4 탑뷰 카메라 — 두 사람 사이(김신 쪽으로 조금)를 따라가고, 멀어지면 물러나고, 흔들림 · 결착 줌을 더한다.
## 높이 · 거리 OFFSET 으로 내려다보는 각이 약 55도(castle_M 의 3/4 탑뷰와 같은 느낌, 아이소메트릭 아님).

const OFFSET := Vector3(0, 10.0, 7.0)

var focus := Vector3.ZERO
var dist_k := 1.0
var zoom := 1.0
var rng := RandomNumberGenerator.new()


func _ready() -> void:
	fov = 38.0
	near = 0.3
	far = 120.0
	rng.seed = 5


func follow(a: Vector3, b: Vector3, dt: float, shake: int) -> void:
	var mid := a.lerp(b, 0.42)
	var sep := a.distance_to(b)
	var want := clampf(0.78 + sep * 0.06, 0.8, 1.12) * zoom
	focus = focus.lerp(mid, 1.0 - exp(-5.0 * dt))
	dist_k = lerpf(dist_k, want, 1.0 - exp(-3.0 * dt))
	zoom = lerpf(zoom, 1.0, 1.0 - exp(-1.5 * dt))
	var sh := Vector3.ZERO
	if shake > 0:
		sh = Vector3(rng.randf_range(-1, 1), rng.randf_range(-1, 1), rng.randf_range(-1, 1)) * 0.03 * shake
	position = focus + OFFSET * dist_k + sh
	look_at(focus + Vector3(0, 0.9, 0) + sh * 0.4, Vector3.UP)


func snap(a: Vector3, b: Vector3) -> void:
	focus = a.lerp(b, 0.42)
	position = focus + OFFSET
	look_at(focus + Vector3(0, 0.9, 0), Vector3.UP)


func punch_zoom(k: float) -> void:
	zoom = minf(zoom, k)
