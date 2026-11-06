extends "res://src/view/set3d.gd"
## 0 · 1장 무대(1부 처음 — 블라디보스토크 호텔 · 회암시) — 방(src/data/prologue.gd · hoeam.gd ROOMS theme)마다 바닥 · 벽 · 소품 · 빛.
## 그리는 도구(_env · _top · _floor · _omni · _mat …)는 src/view/set3d.gd(호텔 무대와 같이 쓴다). build(theme, bounds, detail) 는 같다(LSP).
## (뼈대 — 무대마다 그림은 다음 커밋에서 채운다. 지금은 어두운 바닥 · 뒷벽만)

## 이 그림이 그리는 무대 이름(시험 test_campaign 이 장 표의 theme 이 여기 있는지 본다)
const THEMES := ["vlad_corridor", "gunter_suite", "vlad_night", "site_alley", "junkyard_night", "junkyard_dusk", "hoeam_street"]


func build(th: String, b: Rect2, detail := true) -> void:
	theme = th
	_detail = detail
	_env(Color(0.3, 0.28, 0.26), 0.7, Color(0.03, 0.03, 0.04))
	_top(Color(1.0, 0.9, 0.8), 0.7)
	_floor(b, Color(0.3, 0.29, 0.28), 0.6, false)
	_back_wall(b, Color(0.32, 0.3, 0.28), 3.2)
