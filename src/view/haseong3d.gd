extends "res://src/view/town3d.gd"
## 2장 무대(하성 본사 — 1부 p1:022-033) — 방(src/data/haseong.gd ROOMS theme)마다 바닥 · 벽 · 소품 · 빛. 1부 무대(town3d.gd —
## 공사장 · 폐차장)를 물려받고 하성 본사 실내만 더한다. build(theme, bounds, detail) 는 같다(LSP). 그리는 도구는 set3d.gd.
## 뼈대(S5 묶음 4 처음): 하성 무대는 아직 1부 무대를 빌려 그린다 — 무대 작업에서 바꾼다.

## 이 그림이 그리는 무대 이름(시험 test_campaign 이 장 표의 theme 이 여기 있는지 본다)
const HASEONG_THEMES := ["haseong_lobby", "haseong_corridor", "haseong_stairs", "haseong_office", "haseong_upper"]


static func themes() -> Array:
	return THEMES + HASEONG_THEMES


func build(th: String, b: Rect2, detail := true) -> void:
	match th:
		"haseong_lobby", "haseong_stairs":
			super.build("vlad_corridor", b, detail)
			theme = th
		"haseong_corridor", "haseong_upper":
			super.build("vlad_corridor", b, detail)
			theme = th
		"haseong_office":
			super.build("gunter_suite", b, detail)
			theme = th
		_:
			super.build(th, b, detail)
