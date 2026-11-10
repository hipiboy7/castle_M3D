extends "res://src/view/haseong3d.gd"
## 3 ~ 13장 무대(2026-11-08 사용자 "3장부터 13장까지 중단없이") — 무대마다 손으로 그리던 0 · 1 · 2장(town3d · haseong3d)과 달리
## **무대 표(SETS)** 한 줄로 그린다: 빛(env · 해/천장) · 바닥(floor | ground) · 뒷벽(wall | window | 없음 = 바깥) · 점광 · 안개 · 눈/비 ·
## 소품 목록(props — [이름, x, z, 덧붙임]). x 는 걸을 곳 가운데에서, z 는 걸을 곳 뒤 끝(bounds 위쪽)에서 잰 m(음수 = 뒤).
## 카메라는 +z 쪽 위에서 내려다본다 — 높은 소품은 뒤(z < 0)나 옆 끝에, 걸을 곳 안(z > 0)에는 납작한 것(매트 · 웅덩이 · 선)만.
## 0 · 1 · 2장 무대 이름도 그대로 그린다(부모 haseong3d → town3d) — 장 목록 view "world" 하나로 3 ~ 13장을 다 맡는다(LSP — build 같음).
## 원작 근거는 장 표 CANON(장소 id)과 머리 주석(화/컷) — 모양은 canon locations · fights place_text(conf ai) 판독이라 연출에만.
## 폰 성능: 점광 3개 이하 · 그림자는 해(천장) 하나 · 재질은 _shared · 소품 30 ~ 90 메시.

## 무대 표 — 색은 Color, 소품 칸은 아래 _prop 의 이름
const SETS := {
	# ---- 3장 청주 교도소 · 블라디보스토크 · 부산(p1:037-060)
	"prison_cell": {"env": [Color(0.32, 0.34, 0.36), 0.7, Color(0.03, 0.03, 0.04)], "top": [Color(0.86, 0.92, 1.0), 0.75],
		"floor": [Color(0.42, 0.43, 0.42), 0.8, true], "wall": [Color(0.5, 0.52, 0.5), 3.0],
		"omni": [[0, 2.4, 1.0, Color(0.85, 0.95, 1.0), 1.4, 7.0]],
		"props": [["bars", 0, -0.5, {"w": 12.0}], ["bunk", -4.5, -0.3], ["bunk", 4.5, -0.3], ["shower", 0, -0.35], ["puddle", -1.0, 2.0], ["puddle", 2.4, 3.0]]},
	"club_cage": {"env": [Color(0.3, 0.2, 0.26), 0.6, Color(0.02, 0.01, 0.02)], "top": [Color(1.0, 0.8, 0.85), 0.6],
		"floor": [Color(0.12, 0.1, 0.12), 0.5, false], "wall": [Color(0.16, 0.1, 0.14), 3.2],
		"omni": [[-3, 2.6, 0.5, Color(1.0, 0.3, 0.55), 2.0, 7.0], [3, 2.6, 0.5, Color(0.4, 0.5, 1.0), 2.0, 7.0]],
		"props": [["mat", 0, 2.4, {"w": 8.0, "d": 4.0, "col": Color(0.55, 0.12, 0.14)}], ["cage", 0, 0, {}], ["neon", 0, -0.6, {"text": "BALLERINO", "col": Color(1.0, 0.35, 0.6)}],
			["crowd", -5.0, -1.4], ["crowd", 5.0, -1.4]]},
	"busan_arcade": {"env": [Color(0.24, 0.2, 0.32), 0.65, Color(0.02, 0.01, 0.03)], "top": [Color(0.9, 0.8, 1.0), 0.5],
		"floor": [Color(0.2, 0.12, 0.24), 0.45, true], "wall": [Color(0.12, 0.08, 0.16), 3.0],
		"omni": [[-3, 1.8, 0.2, Color(1.0, 0.4, 0.9), 1.8, 6.0], [3, 1.8, 0.2, Color(0.3, 0.9, 1.0), 1.8, 6.0]],
		"props": [["slots", 0, -0.45, {"n": 9}], ["neon", -3.5, -0.75, {"text": "GAME LAND", "col": Color(1.0, 0.85, 0.2)}], ["stool", -2.0, -0.05], ["stool", 1.5, -0.05]]},
	"busan_rain": {"env": [Color(0.22, 0.26, 0.32), 0.6, Color(0.02, 0.03, 0.05)], "sun": [Color(0.6, 0.7, 0.9), 0.5, Vector3(-55, 30, 0)],
		"ground": [Color(0.1, 0.11, 0.12), Color(0.18, 0.19, 0.2), 0.25], "fog": [Color(0.2, 0.24, 0.3), 0.025], "rain": 360,
		"omni": [[-4, 3.2, -0.6, Color(1.0, 0.7, 0.4), 1.6, 7.0], [4, 3.2, -0.6, Color(0.5, 0.8, 1.0), 1.4, 7.0]],
		"props": [["building", -4.0, -2.5, {"col": Color(0.3, 0.24, 0.2)}], ["building", 3.5, -2.8, {"col": Color(0.24, 0.24, 0.28)}], ["shutter", -1.0, -1.0],
			["sign", 3.5, -1.0, {"text": "부산 밤 시장", "col": Color(1.0, 0.4, 0.3)}], ["puddle", -2.0, 1.6], ["puddle", 2.6, 3.2], ["barrel", 5.6, -0.4]]},
	"busan_lobby": {"env": [Color(0.32, 0.28, 0.24), 0.7, Color(0.03, 0.02, 0.02)], "top": [Color(1.0, 0.9, 0.75), 0.8],
		"floor": [Color(0.5, 0.44, 0.36), 0.3, true], "wall": [Color(0.3, 0.24, 0.2), 3.2],
		"omni": [[0, 2.6, 0.5, Color(1.0, 0.85, 0.6), 1.6, 8.0]],
		"props": [["neon", 0, -0.62, {"text": "ROLLING BALL", "col": Color(0.4, 0.8, 1.0)}], ["pillar", -4.2, -0.4], ["pillar", 4.2, -0.4], ["sofa", -2.4, -0.4], ["plant", 2.4, -0.4]]},
	"busan_office": {"env": [Color(0.34, 0.28, 0.22), 0.7, Color(0.03, 0.02, 0.01)], "top": [Color(1.0, 0.88, 0.7), 0.75],
		"floor": [Color(0.36, 0.22, 0.12), 0.4, false], "wall": [Color(0.32, 0.26, 0.2), 3.0],
		"omni": [[0, 2.4, 0.6, Color(1.0, 0.8, 0.55), 1.5, 7.0]],
		"props": [["desk", 0, -0.9], ["trophy", -3.6, -0.45], ["trophy", 3.6, -0.45], ["rug", 0, 2.2, {"w": 5.0, "d": 2.4, "col": Color(0.4, 0.12, 0.1)}]]},
	"busan_street": {"env": [Color(0.4, 0.42, 0.46), 0.75, Color(0.4, 0.46, 0.55)], "sun": [Color(1.0, 0.95, 0.85), 1.0, Vector3(-50, 35, 0)],
		"ground": [Color(0.24, 0.24, 0.26), Color(0.34, 0.34, 0.36), 0.7],
		"props": [["building", -4.5, -2.6, {"col": Color(0.5, 0.3, 0.24)}], ["building", 1.0, -2.8, {"col": Color(0.45, 0.28, 0.22)}], ["building", 6.0, -2.5, {"col": Color(0.4, 0.38, 0.36)}],
			["car", -3.0, -0.9, {"col": Color(0.2, 0.25, 0.4)}], ["car", 4.2, -0.9, {"col": Color(0.6, 0.6, 0.62)}], ["line", 0, 2.4, {"w": 14.0}]]},
	# ---- 4장 당구장 · 지하 케이지 · 러시아 · 저수지 · 공단 폐공장(p1:061-085)
	"billiard": {"env": [Color(0.26, 0.28, 0.24), 0.65, Color(0.02, 0.02, 0.02)], "top": [Color(0.95, 1.0, 0.85), 0.6],
		"floor": [Color(0.3, 0.26, 0.22), 0.6, true], "wall": [Color(0.24, 0.3, 0.26), 3.0],
		"omni": [[-3, 1.8, -0.4, Color(0.9, 1.0, 0.75), 1.8, 5.0], [3, 1.8, -0.4, Color(0.9, 1.0, 0.75), 1.8, 5.0]],
		"props": [["pool", -3.0, -0.5], ["pool", 3.0, -0.5], ["sign", 0, -0.75, {"text": "당구장", "col": Color(0.3, 1.0, 0.5)}]]},
	"cage_pit": {"env": [Color(0.24, 0.22, 0.2), 0.55, Color(0.01, 0.01, 0.01)], "top": [Color(1.0, 0.92, 0.75), 0.9],
		"floor": [Color(0.16, 0.15, 0.14), 0.8, false], "wall": [Color(0.14, 0.13, 0.12), 3.4],
		"omni": [[0, 3.0, 1.6, Color(1.0, 0.9, 0.7), 2.4, 8.0]],
		"props": [["mat", 0, 2.4, {"w": 8.0, "d": 4.2, "col": Color(0.32, 0.3, 0.28)}], ["cage", 0, 0, {}], ["crowd", -5.2, -1.2], ["crowd", 0, -1.6], ["crowd", 5.2, -1.2],
			["line", 0, 0.3, {"w": 8.2, "d": 0.1, "col": Color(0.85, 0.85, 0.8)}], ["line", 0, 4.5, {"w": 8.2, "d": 0.1, "col": Color(0.85, 0.85, 0.8)}],
			["line", -4.05, 2.4, {"w": 0.1, "d": 4.2, "col": Color(0.85, 0.85, 0.8)}], ["line", 4.05, 2.4, {"w": 0.1, "d": 4.2, "col": Color(0.85, 0.85, 0.8)}]]},
	"siberia_ward": {"env": [Color(0.28, 0.32, 0.3), 0.6, Color(0.02, 0.03, 0.03)], "top": [Color(0.8, 1.0, 0.9), 0.6],
		"floor": [Color(0.32, 0.36, 0.34), 0.4, true], "wall": [Color(0.38, 0.44, 0.4), 3.0], "snow_out": true,
		"omni": [[0, 2.4, 0.4, Color(0.75, 1.0, 0.9), 1.4, 7.0]],
		"props": [["bed", -3.6, -0.45], ["bed", 3.6, -0.45], ["lamp_op", 0, -0.4], ["door", -5.6, -0.15], ["puddle", 1.0, 2.6, {"col": Color(0.3, 0.02, 0.02, 0.8)}]]},
	"lakehouse": {"env": [Color(0.3, 0.34, 0.4), 0.6, Color(0.05, 0.07, 0.1)], "sun": [Color(0.7, 0.8, 1.0), 0.55, Vector3(-40, 20, 0)],
		"floor": [Color(0.32, 0.22, 0.14), 0.7, false], "water": true, "fog": [Color(0.3, 0.36, 0.42), 0.008],
		"props": [["house", 0, -2.2], ["boat", -5.0, 4.6], ["post", -6.0, 3.6], ["post", 6.0, 3.6], ["lamp", 5.0, -0.6, {"col": Color(1.0, 0.8, 0.5)}], ["barrel", -5.4, -0.4],
			["line", 0, 0.6, {"w": 12.0, "d": 0.05, "col": Color(0.2, 0.13, 0.08)}], ["line", 0, 1.4, {"w": 12.0, "d": 0.05, "col": Color(0.2, 0.13, 0.08)}], ["line", 0, 2.2, {"w": 12.0, "d": 0.05, "col": Color(0.2, 0.13, 0.08)}], ["line", 0, 3.0, {"w": 12.0, "d": 0.05, "col": Color(0.2, 0.13, 0.08)}], ["line", 0, 3.8, {"w": 12.0, "d": 0.05, "col": Color(0.2, 0.13, 0.08)}]]},
	"factory": {"env": [Color(0.28, 0.26, 0.24), 0.6, Color(0.03, 0.02, 0.02)], "sun": [Color(1.0, 0.75, 0.5), 0.7, Vector3(-30, 60, 0)],
		"floor": [Color(0.3, 0.29, 0.27), 0.85, true], "wall": [Color(0.34, 0.3, 0.26), 4.0],
		"omni": [[0, 3.0, 0.4, Color(1.0, 0.7, 0.45), 1.8, 9.0]],
		"props": [["machine", -4.0, -0.7], ["machine", 4.0, -0.7], ["beam", -6.0, -0.2], ["beam", 0, -0.3], ["beam", 6.0, -0.2], ["barrel", -2.0, -0.3], ["crate", 2.2, -0.4], ["puddle", 0, 2.8]]},
	# ---- 5장 장례 · 백의 결성(p1:086-088) — 싸움 없음
	"funeral": {"env": [Color(0.32, 0.32, 0.34), 0.7, Color(0.03, 0.03, 0.04)], "top": [Color(1.0, 0.98, 0.95), 0.7],
		"floor": [Color(0.5, 0.48, 0.46), 0.5, true], "wall": [Color(0.75, 0.74, 0.72), 3.0],
		"omni": [[0, 2.4, -0.2, Color(1.0, 0.95, 0.85), 1.4, 6.0]],
		"props": [["altar", 0, -0.55], ["wreath", -2.6, -0.4], ["wreath", 2.6, -0.4], ["rug", 0, 2.0, {"w": 3.0, "d": 4.0, "col": Color(0.12, 0.12, 0.14)}]]},
	"rooftop_dusk": {"env": [Color(0.5, 0.36, 0.3), 0.7, Color(0.55, 0.3, 0.22)], "sun": [Color(1.0, 0.6, 0.35), 1.0, Vector3(-15, 60, 0)],
		"floor": [Color(0.4, 0.38, 0.36), 0.8, true], "city": true, "rail": true,
		"props": [["tank", -5.0, -0.6], ["vent", 4.6, -0.3]]},
	# 놀이공원 분수대 광장(p1:087/005-008 — 대관람차 · 성 모양 탑 · 범퍼카 · 분수 · 'CAFFEE' 간판, 낮) — 하성 김태훈과의 회담
	"park_plaza": {"env": [Color(0.5, 0.5, 0.5), 0.8, Color(0.62, 0.72, 0.85)], "sun": [Color(1.0, 0.96, 0.88), 1.1, Vector3(-55, 30, 0)],
		"ground": [Color(0.52, 0.48, 0.44), Color(0.62, 0.58, 0.52), 0.7],
		"props": [["building", -4.4, -2.8, {"col": Color(0.85, 0.55, 0.6)}], ["building", 3.8, -3.0, {"col": Color(0.55, 0.7, 0.9)}],
			["stall", -1.6, -0.9, {"col": Color(0.95, 0.4, 0.3)}], ["neon", 2.2, -0.9, {"text": "CAFFEE", "col": Color(1.0, 0.85, 0.3)}],
			["round_table", -4.2, 3.4], ["round_table", 4.2, 3.4], ["lamp", 0.0, -0.4, {"col": Color(1.0, 0.9, 0.7)}], ["plant", 5.6, -0.4]]},
	# ---- 6장 인천항 — 백도찬의 배(p1:089-111)
	"ship_deck": {"env": [Color(0.2, 0.24, 0.32), 0.6, Color(0.02, 0.03, 0.06)], "sun": [Color(0.6, 0.7, 1.0), 0.55, Vector3(-50, -30, 0)],
		"floor": [Color(0.32, 0.3, 0.28), 0.7, true], "water": true, "rail": true, "fog": [Color(0.12, 0.15, 0.22), 0.02],
		"omni": [[-3, 3.2, -0.4, Color(1.0, 0.85, 0.6), 1.6, 8.0]],
		"props": [["container", -4.6, -1.4, {"col": Color(0.6, 0.2, 0.15)}], ["container", 1.2, -1.6, {"col": Color(0.15, 0.35, 0.5)}], ["winch", 5.4, -0.4], ["rope_coil", -1.4, -0.2]]},
	"ship_hold": {"env": [Color(0.2, 0.3, 0.3), 0.65, Color(0.01, 0.03, 0.03)], "top": [Color(0.7, 1.0, 0.95), 0.6],
		"floor": [Color(0.24, 0.3, 0.3), 0.6, true], "wall": [Color(0.12, 0.32, 0.32), 3.6],
		"omni": [[0, 3.0, 0.4, Color(0.6, 1.0, 0.9), 1.6, 9.0]],
		"props": [["pipes", 0, -0.55, {"w": 12.0}], ["beam", -5.4, -0.2], ["beam", 5.4, -0.2], ["crate", -2.4, -0.35], ["crate", 2.8, -0.35]]},
	"ship_bridge": {"env": [Color(0.22, 0.26, 0.32), 0.65, Color(0.01, 0.02, 0.04)], "top": [Color(0.8, 0.9, 1.0), 0.55],
		"floor": [Color(0.22, 0.22, 0.24), 0.5, false], "window": 2.6, "sea_view": true,
		"omni": [[0, 2.2, 0.2, Color(0.4, 1.0, 0.6), 1.2, 6.0]],
		"props": [["console", -2.4, -0.4], ["console", 2.4, -0.4], ["wheel", 0, -0.4]]},
	# ---- 7장 대화 — 임무열 · 최민욱(p1:117-121)
	"meeting_room": {"env": [Color(0.3, 0.3, 0.34), 0.7, Color(0.02, 0.02, 0.03)], "top": [Color(0.95, 0.95, 1.0), 0.7],
		"floor": [Color(0.2, 0.2, 0.22), 0.4, false], "window": 3.0, "city": true,
		"props": [["long_table", 0, 1.2], ["plant", -5.0, -0.4], ["plant", 5.0, -0.4]]},
	"port_alley": {"env": [Color(0.18, 0.2, 0.26), 0.6, Color(0.01, 0.02, 0.03)], "sun": [Color(0.6, 0.7, 0.95), 0.45, Vector3(-55, 20, 0)],
		"ground": [Color(0.12, 0.12, 0.13), Color(0.2, 0.2, 0.21), 0.6], "fog": [Color(0.16, 0.18, 0.24), 0.03],
		"omni": [[2, 3.0, -0.6, Color(1.0, 0.75, 0.45), 1.8, 7.0]],
		"props": [["container", -4.0, -1.4, {"col": Color(0.25, 0.4, 0.3)}], ["building", 3.0, -2.6, {"col": Color(0.26, 0.24, 0.22)}], ["lamp", 2.0, -0.5, {"col": Color(1.0, 0.7, 0.4)}],
			["barrel", -1.0, -0.3], ["crate", 5.4, -0.4]]},
	# ---- 8장 동남아 항구 · 교류회(2부 2-14)
	"port_market": {"env": [Color(0.5, 0.48, 0.42), 0.75, Color(0.6, 0.66, 0.7)], "sun": [Color(1.0, 0.92, 0.75), 1.2, Vector3(-60, 40, 0)],
		"ground": [Color(0.4, 0.36, 0.3), Color(0.5, 0.46, 0.38), 0.8], "water_back": true,
		"props": [["stall", -4.0, -0.9, {"col": Color(0.9, 0.3, 0.2)}], ["stall", 0, -0.9, {"col": Color(0.2, 0.5, 0.8)}], ["stall", 4.0, -0.9, {"col": Color(0.9, 0.75, 0.2)}],
			["crate", -6.0, -0.3], ["boat", 3.0, -3.6]]},
	"western_pub": {"env": [Color(0.36, 0.26, 0.18), 0.65, Color(0.03, 0.02, 0.01)], "top": [Color(1.0, 0.8, 0.55), 0.7],
		"floor": [Color(0.34, 0.2, 0.1), 0.6, false], "wall": [Color(0.3, 0.18, 0.1), 3.0],
		"omni": [[-3, 2.2, 0.0, Color(1.0, 0.7, 0.4), 1.6, 6.0], [3, 2.2, 0.0, Color(1.0, 0.7, 0.4), 1.6, 6.0]],
		"props": [["bar", 0, -0.6, {"w": 9.0}], ["round_table", -4.6, 3.8], ["round_table", 4.6, 3.8], ["neon", 3.6, -0.75, {"text": "SALOON", "col": Color(1.0, 0.6, 0.2)}]]},
	"warehouse": {"env": [Color(0.3, 0.3, 0.3), 0.65, Color(0.02, 0.02, 0.02)], "top": [Color(0.95, 0.95, 0.9), 0.75],
		"floor": [Color(0.36, 0.36, 0.34), 0.8, true], "wall": [Color(0.4, 0.4, 0.4), 4.2],
		"omni": [[0, 3.4, 0.6, Color(1.0, 0.95, 0.85), 1.6, 10.0]],
		"props": [["shelf", -4.6, -0.5], ["shelf", 4.6, -0.5], ["crate", -1.6, -0.35], ["crate", 1.6, -0.4], ["forklift", 0, -0.6], ["line", 0, 2.2, {"w": 12.0, "col": Color(0.9, 0.8, 0.2)}]]},
	"gala_hall": {"env": [Color(0.4, 0.34, 0.28), 0.75, Color(0.04, 0.03, 0.02)], "top": [Color(1.0, 0.9, 0.7), 0.8],
		"floor": [Color(0.55, 0.48, 0.38), 0.25, true], "wall": [Color(0.45, 0.35, 0.25), 3.6],
		"omni": [[0, 3.0, 1.0, Color(1.0, 0.85, 0.6), 1.6, 9.0]],
		"props": [["chandelier", 0, 1.6], ["round_table", -4.8, -0.4], ["round_table", 4.8, -0.4], ["rug", 0, 2.2, {"w": 7.0, "d": 3.0, "col": Color(0.5, 0.08, 0.1)}], ["pillar", -6.4, -0.4], ["pillar", 6.4, -0.4]]},
	# ---- 9장 백의 사무실 · 클럽 부다페스트 · 선박 카지노(2부 15-32)
	"office_corridor": {"env": [Color(0.32, 0.34, 0.36), 0.7, Color(0.02, 0.02, 0.03)], "top": [Color(0.95, 0.98, 1.0), 0.7],
		"floor": [Color(0.3, 0.3, 0.32), 0.35, true], "wall": [Color(0.6, 0.6, 0.6), 3.0],
		"omni": [[0, 2.4, 0.4, Color(0.95, 0.98, 1.0), 1.3, 8.0]],
		"props": [["door", -4.0, -0.15], ["door", 0, -0.15], ["door", 4.0, -0.15], ["elevator", 6.4, -0.15], ["plant", -6.0, -0.35]]},
	"club_budapest": {"env": [Color(0.22, 0.18, 0.3), 0.6, Color(0.01, 0.01, 0.02)], "top": [Color(0.8, 0.7, 1.0), 0.45],
		"floor": [Color(0.08, 0.08, 0.1), 0.2, true], "wall": [Color(0.08, 0.06, 0.12), 3.4],
		"omni": [[-3, 2.6, 1.0, Color(0.8, 0.2, 1.0), 2.2, 7.0], [3, 2.6, 1.0, Color(0.2, 0.8, 1.0), 2.2, 7.0]],
		"props": [["neon", 0, -0.62, {"text": "BUDAPEST", "col": Color(0.9, 0.3, 1.0)}], ["bar", -3.6, -0.6, {"w": 4.0}], ["speaker", 4.6, -0.5], ["speaker", 6.2, -0.5], ["dots", 0, 2.4]]},
	"casino_deck": {"env": [Color(0.36, 0.22, 0.18), 0.7, Color(0.03, 0.01, 0.01)], "top": [Color(1.0, 0.75, 0.5), 0.7],
		"floor": [Color(0.4, 0.12, 0.1), 0.4, true], "wall": [Color(0.5, 0.12, 0.08), 3.2],
		"omni": [[-3, 2.4, 0.2, Color(1.0, 0.55, 0.3), 1.6, 7.0], [3, 2.4, 0.2, Color(1.0, 0.85, 0.4), 1.6, 7.0]],
		"props": [["red_pillar", -5.0, -0.3], ["red_pillar", -1.7, -0.3], ["red_pillar", 1.7, -0.3], ["red_pillar", 5.0, -0.3], ["lantern", -3.4, -0.6], ["lantern", 3.4, -0.6], ["gold_roof", 0, -1.2]]},
	# ---- 10장 회암시 · 임대 아파트 · 화진 호텔(2부 36-51)
	"iron_arcade": {"env": [Color(0.34, 0.32, 0.3), 0.65, Color(0.2, 0.22, 0.26)], "sun": [Color(0.95, 0.9, 0.8), 0.7, Vector3(-65, 20, 0)],
		"floor": [Color(0.3, 0.28, 0.26), 0.85, false], "wall": [Color(0.36, 0.34, 0.32), 3.2],
		"props": [["shutter", -4.0, -0.95], ["shutter", 0, -0.95], ["anvil", 3.6, -0.3], ["machine", 5.6, -0.6], ["sign", -4.0, -0.75, {"text": "철공소", "col": Color(1.0, 0.85, 0.3)}], ["barrel", -5.6, -0.4],
			["line", 0, 0.5, {"w": 12.0, "d": 0.12}]]},
	"apartment_lot": {"env": [Color(0.4, 0.42, 0.46), 0.75, Color(0.5, 0.55, 0.62)], "sun": [Color(1.0, 0.95, 0.88), 1.0, Vector3(-50, 30, 0)],
		"ground": [Color(0.3, 0.3, 0.3), Color(0.4, 0.4, 0.4), 0.8],
		"props": [["building", -3.0, -3.0, {"col": Color(0.7, 0.66, 0.6), "h": 9.0}], ["building", 4.0, -3.0, {"col": Color(0.66, 0.62, 0.58), "h": 9.0}], ["van", -4.2, -0.9], ["car", 3.4, -0.9, {"col": Color(0.3, 0.3, 0.32)}],
			["tank", 6.4, -0.6]]},
	"hwajin_hall": {"env": [Color(0.38, 0.3, 0.26), 0.75, Color(0.03, 0.02, 0.02)], "top": [Color(1.0, 0.85, 0.65), 0.8],
		"floor": [Color(0.5, 0.36, 0.26), 0.25, true], "wall": [Color(0.4, 0.2, 0.14), 3.6],
		"omni": [[0, 3.0, 0.6, Color(1.0, 0.8, 0.55), 1.6, 9.0]],
		"props": [["lantern", -4.0, -0.6], ["lantern", 4.0, -0.6], ["sofa", -2.2, -0.45], ["sofa", 2.2, -0.45], ["chandelier", 0, 1.4], ["rug", 0, 2.4, {"w": 8.0, "d": 3.0, "col": Color(0.55, 0.1, 0.08)}]]},
	"library": {"env": [Color(0.34, 0.28, 0.22), 0.7, Color(0.02, 0.02, 0.01)], "top": [Color(1.0, 0.88, 0.7), 0.7],
		"floor": [Color(0.3, 0.2, 0.12), 0.4, false], "wall": [Color(0.25, 0.16, 0.1), 3.6],
		"omni": [[0, 2.6, 0.6, Color(1.0, 0.82, 0.55), 1.6, 8.0]],
		"props": [["books", -4.0, -0.5], ["books", 0, -0.5], ["books", 4.0, -0.5], ["rug", 0, 2.2, {"w": 4.4, "d": 3.0, "col": Color(0.3, 0.12, 0.1)}]]},
	# 10장 회암시 시장골목(김신 대 리천 — 사용자 rc.8 '회암시 시장골목' · 036/013 '나와라') — 노점 천막 · 셔터 · 상자
	"market_alley": {"env": [Color(0.32, 0.3, 0.3), 0.65, Color(0.16, 0.18, 0.22)], "sun": [Color(0.95, 0.88, 0.78), 0.65, Vector3(-65, 25, 0)],
		"floor": [Color(0.3, 0.29, 0.27), 0.85, true], "wall": [Color(0.38, 0.34, 0.3), 3.2],
		"props": [["shutter", -4.4, -0.95], ["stall", -1.6, -0.9, {"col": Color(0.85, 0.3, 0.22)}], ["stall", 1.8, -0.9, {"col": Color(0.25, 0.45, 0.75)}],
			["shutter", 4.6, -0.95], ["sign", -4.4, -0.75, {"text": "시장", "col": Color(1.0, 0.85, 0.3)}], ["crate", -5.6, -0.4], ["crate", 5.6, -0.3],
			["lantern", 0, -0.6]]},
	# 10장 산 기슭(아킬라 대 구스타프 — fight:akila_suv 046/038-054 굽은 산길 · 붉은 픽업 · 부딪친 SUV 두 대, 055 덩굴 낀 폐건물 · 숲)
	"mountain_road": {"env": [Color(0.4, 0.44, 0.38), 0.75, Color(0.55, 0.64, 0.7)], "sun": [Color(1.0, 0.95, 0.85), 1.0, Vector3(-50, 35, 0)],
		"ground": [Color(0.3, 0.34, 0.24), Color(0.4, 0.42, 0.3), 0.9],
		"props": [["building", -1.0, -3.2, {"col": Color(0.5, 0.5, 0.46), "h": 4.0}], ["plant", -6.0, -0.6], ["plant", -3.2, -1.0], ["plant", 3.0, -1.2],
			["plant", 6.2, -0.6], ["car", -5.0, -0.9, {"col": Color(0.6, 0.12, 0.1)}], ["car", 2.6, -0.9, {"col": Color(0.08, 0.08, 0.1)}],
			["car", 5.0, -1.2, {"col": Color(0.1, 0.1, 0.12)}], ["line", 0, 3.4, {"w": 14.0, "d": 0.12, "col": Color(0.9, 0.8, 0.3)}]]},
	# ---- 12장 교회 비전센터 · 스카이 브리지 · 공사장 · 지하(2부 70-126)
	"church_yard": {"env": [Color(0.24, 0.28, 0.34), 0.6, Color(0.04, 0.05, 0.07)], "sun": [Color(0.7, 0.78, 0.9), 0.5, Vector3(-55, 25, 0)],
		"ground": [Color(0.16, 0.17, 0.18), Color(0.26, 0.27, 0.28), 0.3], "rain": 380, "fog": [Color(0.2, 0.24, 0.3), 0.03],
		"props": [["church", 0, -3.2], ["cross", 0, -3.0, {"y": 7.4}], ["lamp", -5.0, -0.5, {"col": Color(1.0, 0.85, 0.6)}], ["lamp", 5.0, -0.5, {"col": Color(1.0, 0.85, 0.6)}], ["puddle", -1.6, 2.0], ["puddle", 2.4, 3.4]]},
	"green_office": {"env": [Color(0.22, 0.32, 0.26), 0.65, Color(0.01, 0.03, 0.02)], "top": [Color(0.7, 1.0, 0.75), 0.6],
		"floor": [Color(0.26, 0.3, 0.28), 0.4, true], "window": 3.0, "rain_view": true,
		"omni": [[0, 2.4, 0.6, Color(0.5, 1.0, 0.6), 1.6, 8.0]],
		"props": [["cubicle", -4.0, -0.5], ["cubicle", 0, -0.5], ["cubicle", 4.0, -0.5], ["stained", 6.4, -0.6]]},
	"church_hall": {"env": [Color(0.3, 0.26, 0.24), 0.65, Color(0.02, 0.01, 0.01)], "top": [Color(1.0, 0.85, 0.7), 0.6],
		"floor": [Color(0.36, 0.26, 0.2), 0.4, false], "wall": [Color(0.5, 0.42, 0.36), 4.0],
		"omni": [[0, 3.0, 0.2, Color(1.0, 0.75, 0.5), 1.6, 8.0]],
		"props": [["stained", -3.6, -0.6], ["stained", 3.6, -0.6], ["cross", 0, -0.65, {"y": 2.6}], ["pews", 0, -0.2], ["rug", 0, 2.4, {"w": 2.4, "d": 5.0, "col": Color(0.5, 0.08, 0.08)}]]},
	"build_site": {"env": [Color(0.22, 0.3, 0.24), 0.6, Color(0.01, 0.02, 0.01)], "top": [Color(0.7, 1.0, 0.7), 0.55],
		"floor": [Color(0.36, 0.36, 0.34), 0.9, false], "wall": [Color(0.34, 0.34, 0.32), 4.0],
		"omni": [[0, 3.0, 0.4, Color(0.55, 1.0, 0.55), 1.8, 9.0]],
		"props": [["scaffold", -3.6, -0.6], ["scaffold", 3.6, -0.6], ["beam", 0, -0.3], ["blocks", -5.8, -0.3], ["tub", 5.6, -0.2], ["puddle", 0.8, 2.6, {"col": Color(0.4, 0.4, 0.38, 0.8)}]]},
	"basement": {"env": [Color(0.24, 0.24, 0.24), 0.6, Color(0.01, 0.01, 0.01)], "top": [Color(0.9, 0.9, 0.85), 0.55],
		"floor": [Color(0.3, 0.3, 0.3), 0.7, true], "wall": [Color(0.4, 0.4, 0.38), 3.0],
		"omni": [[0, 2.4, 0.4, Color(1.0, 0.95, 0.8), 1.3, 7.0]],
		"props": [["pipes", 0, -0.55, {"w": 12.0}], ["door", -4.0, -0.15], ["door", 4.0, -0.15], ["sign", 0, -0.75, {"text": "B1", "col": Color(0.4, 1.0, 0.5)}]]},
	"parking": {"env": [Color(0.24, 0.3, 0.26), 0.6, Color(0.01, 0.02, 0.01)], "top": [Color(0.75, 1.0, 0.8), 0.55],
		"floor": [Color(0.3, 0.3, 0.3), 0.6, false], "wall": [Color(0.36, 0.38, 0.36), 3.0],
		"omni": [[-3, 2.6, 0.4, Color(0.6, 1.0, 0.7), 1.4, 7.0], [3, 2.6, 0.4, Color(0.6, 1.0, 0.7), 1.4, 7.0]],
		"props": [["pillar", -4.0, -0.3, {"col": Color(0.5, 0.52, 0.5)}], ["pillar", 4.0, -0.3, {"col": Color(0.5, 0.52, 0.5)}], ["car", -1.0, -1.0, {"col": Color(0.1, 0.1, 0.12)}],
			["shutter", 6.0, -0.95], ["line", -3.0, 2.0, {"w": 0.12, "d": 4.0, "col": Color(0.9, 0.9, 0.9)}], ["line", 3.0, 2.0, {"w": 0.12, "d": 4.0, "col": Color(0.9, 0.9, 0.9)}]]},
	# 12장 다시 짬(2026-11-10 사용자 스테이지 목록): 비전센터 안(구스타프 전 — 사무실에서 넓어짐) · 본동 3층 복도 · 본동 로비
	"vision_center": {"env": [Color(0.22, 0.3, 0.26), 0.65, Color(0.01, 0.03, 0.02)], "top": [Color(0.75, 1.0, 0.8), 0.6],
		"floor": [Color(0.3, 0.32, 0.3), 0.35, true], "window": 3.4, "rain_view": true,
		"omni": [[-4, 2.8, 0.6, Color(0.5, 1.0, 0.6), 1.6, 9.0], [5, 2.8, 0.6, Color(0.6, 1.0, 0.7), 1.4, 9.0]],
		"props": [["cubicle", -7.0, -0.5], ["stained", -3.0, -0.6], ["pews", 2.0, -0.2], ["stained", 6.0, -0.6], ["pillar", -5.0, -0.4], ["pillar", 8.6, -0.4]]},
	"church_corridor": {"env": [Color(0.3, 0.26, 0.22), 0.6, Color(0.02, 0.01, 0.01)], "top": [Color(1.0, 0.85, 0.7), 0.55],
		"floor": [Color(0.34, 0.24, 0.16), 0.45, false], "wall": [Color(0.46, 0.4, 0.34), 3.2],
		"omni": [[-4, 2.6, 0.4, Color(1.0, 0.8, 0.55), 1.4, 7.0], [4, 2.6, 0.4, Color(1.0, 0.8, 0.55), 1.4, 7.0]],
		"props": [["stained", -6.0, -0.6], ["door", -3.0, -0.15], ["stained", 0, -0.6], ["door", 3.0, -0.15], ["stained", 6.0, -0.6],
			["sign", 0, -0.75, {"text": "3F", "col": Color(1.0, 0.85, 0.5)}], ["rug", 0, 2.0, {"w": 14.0, "d": 1.6, "col": Color(0.45, 0.08, 0.08)}]]},
	"church_lobby": {"env": [Color(0.32, 0.3, 0.28), 0.7, Color(0.02, 0.02, 0.02)], "top": [Color(1.0, 0.92, 0.8), 0.7],
		"floor": [Color(0.5, 0.48, 0.44), 0.25, true], "wall": [Color(0.5, 0.46, 0.4), 4.0],
		"omni": [[0, 3.0, 0.6, Color(1.0, 0.9, 0.7), 1.6, 9.0]],
		"props": [["pillar", -4.0, -0.4], ["pillar", 4.0, -0.4], ["stained", 0, -0.6], ["cross", 0, -0.65, {"y": 3.0}], ["door", -6.2, -0.15],
			["sign", -6.2, -0.75, {"text": "B1", "col": Color(0.4, 1.0, 0.5)}], ["plant", 6.0, -0.4]]},
	# ---- 13장 미술관 앞(2부 127-134)
	"museum_plaza": {"env": [Color(0.42, 0.42, 0.44), 0.75, Color(0.55, 0.57, 0.6)], "sun": [Color(0.9, 0.92, 0.95), 0.75, Vector3(-55, 20, 0)],
		"ground": [Color(0.46, 0.45, 0.43), Color(0.58, 0.57, 0.55), 0.7], "tiles_out": true,
		"props": [["museum", 0, -3.4], ["statue", -5.0, -0.6], ["statue", 5.0, -0.6]]},
	"red_plaza": {"env": [Color(0.5, 0.24, 0.2), 0.7, Color(0.45, 0.1, 0.08)], "sun": [Color(1.0, 0.5, 0.35), 0.9, Vector3(-20, 40, 0)],
		"ground": [Color(0.3, 0.26, 0.24), Color(0.4, 0.34, 0.3), 0.35], "rain": 300, "fog": [Color(0.45, 0.16, 0.12), 0.03],
		"props": [["museum", 0, -3.6, {"col": Color(0.3, 0.26, 0.26)}], ["puddle", -2.0, 2.0, {"col": Color(0.6, 0.15, 0.1, 0.6)}], ["puddle", 2.8, 3.2, {"col": Color(0.6, 0.15, 0.1, 0.6)}]]},
	# 13장 다시 짬: 미술관 안(사인진 · 그림 앞의 최민욱 — 가운데 큰 그림은 스테인드 판으로)
	"museum_hall": {"env": [Color(0.4, 0.38, 0.36), 0.75, Color(0.03, 0.03, 0.03)], "top": [Color(1.0, 0.96, 0.9), 0.8],
		"floor": [Color(0.62, 0.6, 0.56), 0.2, true], "wall": [Color(0.78, 0.76, 0.72), 4.0],
		"omni": [[0, 3.2, 0.4, Color(1.0, 0.95, 0.85), 1.6, 9.0]],
		"props": [["stained", 0, -0.6], ["statue", -4.4, -0.5], ["statue", 4.4, -0.5], ["pillar", -6.0, -0.4], ["pillar", 6.0, -0.4],
			["rug", 0, 2.2, {"w": 6.0, "d": 3.0, "col": Color(0.35, 0.1, 0.1)}]]},
}

const FONT_W = preload("res://assets/fonts/Galmuri11-Bold.ttf")


static func themes() -> Array:
	return THEMES + HASEONG_THEMES + SETS.keys()


func build(th: String, b: Rect2, detail := true) -> void:
	if not SETS.has(th):
		super.build(th, b, detail)
		return
	theme = th
	_detail = detail
	var s: Dictionary = SETS[th]
	var e: Array = s["env"]
	_env(e[0], e[1], e[2])
	if s.has("top"):
		_top(s["top"][0], s["top"][1])
	if s.has("sun"):
		_sun(s["sun"][0], s["sun"][1], s["sun"][2])
	if s.has("fog"):
		_fog(s["fog"][0], s["fog"][1])
	if s.has("floor"):
		_floor(b, s["floor"][0], s["floor"][1], s["floor"][2])
	if s.has("ground"):
		_ground(b, s["ground"][0], s["ground"][1], s["ground"][2], th.hash() % 97)
	if s.has("wall"):
		_back_wall(b, s["wall"][0], s["wall"][1])
	if s.has("window"):
		_window_wall(b, s["window"])
	if s.get("city", false):
		_city(b.position.y - 1.0, b.size.x + 30.0, th.length())
	if s.get("water", false) or s.get("sea_view", false):
		_water(b, s.get("sea_view", false))
	if s.get("water_back", false):
		_water_back(b)
	if s.get("rail", false):
		_rail(b)
	for o in s.get("omni", []):
		_omni(Vector3(b.get_center().x + o[0], o[1], b.position.y + o[2]), o[3], o[4], o[5])
	var cx := b.get_center().x
	var bz := b.position.y
	for p in s.get("props", []):
		_prop(str(p[0]), Vector3(cx + float(p[1]), 0, bz + float(p[2])), p[3] if p.size() > 3 else {}, b)
	if s.has("rain") or s.get("rain_view", false):
		_rain(Vector3(cx, 4.0, b.get_center().y), Vector3(b.size.x * 0.6, 0.5, b.size.y * 0.7), int(s.get("rain", 200)))
	if s.get("snow_out", false):
		_snow(Vector3(cx, 4.0, bz - 2.0), Vector3(b.size.x * 0.6, 0.5, 1.0), 120)


## 소품 하나 — at 은 바닥 자리(y 0). o 는 덧붙임(색 col · 너비 w · 깊이 d · 글 text · 높이 h · y)
func _prop(kind: String, at: Vector3, o: Dictionary, b: Rect2) -> void:
	var col: Color = o.get("col", Color(0.4, 0.3, 0.2))
	match kind:
		"bars":                                          # 교도소 창살(뒷벽 앞)
			var w: float = o.get("w", 10.0)
			var m := _shared(Color(0.35, 0.37, 0.4), 0.4, 0.0, 0.8)
			for i in int(w / 0.3):
				_mesh(self, _cyl(0.025, 0.025, 2.8), m, at + Vector3(-w * 0.5 + i * 0.3, 1.4, 0))
			for y in [0.1, 1.4, 2.7]:
				_mesh(self, _box(Vector3(w, 0.08, 0.06)), m, at + Vector3(0, y, 0))
		"bunk":
			var m := _shared(Color(0.35, 0.37, 0.4), 0.5, 0.0, 0.6)
			for y in [0.45, 1.35]:
				_mesh(self, _box(Vector3(1.9, 0.08, 0.8)), m, at + Vector3(0, y, 0))
				_mesh(self, _box(Vector3(1.8, 0.12, 0.7)), _shared(Color(0.55, 0.6, 0.55), 0.95), at + Vector3(0, y + 0.1, 0))
			for x in [-0.92, 0.92]:
				_mesh(self, _box(Vector3(0.05, 1.6, 0.05)), m, at + Vector3(x, 0.8, 0))
		"shower":
			var m := _shared(Color(0.6, 0.62, 0.64), 0.3, 0.0, 0.9)
			for x in [-2.0, 0.0, 2.0]:
				_mesh(self, _box(Vector3(0.06, 2.3, 0.06)), m, at + Vector3(x, 1.15, -0.1))
				_mesh(self, _cyl(0.12, 0.05, 0.1), m, at + Vector3(x, 2.25, 0.05))
		"puddle":
			var pm := _mat(o.get("col", Color(0.4, 0.5, 0.65, 0.5)), 0.05, 0.0, 0.3)
			pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			var c := _mesh(self, _cyl(1.0, 1.0, 0.005), pm, at + Vector3(0, 0.004, 0))
			c.scale = Vector3(1.4, 1, 0.8)
		"mat", "rug":
			_decal(Rect2(at.x - float(o.get("w", 6.0)) * 0.5, at.z - float(o.get("d", 3.0)) * 0.5, o.get("w", 6.0), o.get("d", 3.0)),
				_shared(o.get("col", Color(0.4, 0.1, 0.1)), 0.9))
		"cage":                                          # 철망 — 뒤 · 양옆(앞은 열어 둔다 — 카메라)
			var m := _shared(Color(0.3, 0.32, 0.34), 0.5, 0.0, 0.7)
			var net := _mat(Color(0.5, 0.52, 0.55, 0.35), 0.5, 0.0, 0.5)
			net.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			var z0 := b.position.y - 0.3
			_mesh(self, _box(Vector3(b.size.x + 1.0, 2.6, 0.02)), net, Vector3(at.x, 1.3, z0))
			for sx in [-1.0, 1.0]:
				var x: float = at.x + sx * (b.size.x * 0.5 + 0.5)
				_mesh(self, _box(Vector3(0.02, 1.2, b.size.y + 0.6)), net, Vector3(x, 0.6, b.get_center().y))
			for i in 7:
				var x := b.position.x - 0.5 + i * (b.size.x + 1.0) / 6.0
				_mesh(self, _cyl(0.05, 0.05, 2.7), m, Vector3(x, 1.35, z0))
		"neon", "sign":
			var l := Label3D.new()
			l.text = str(o.get("text", ""))
			l.font = FONT_W
			l.font_size = 64 if kind == "neon" else 48
			l.pixel_size = 0.008
			l.modulate = col
			l.outline_size = 8
			l.outline_modulate = col.darkened(0.6)
			l.position = at + Vector3(0, 2.3 if kind == "neon" else 1.9, 0)
			add_child(l)
			if kind == "neon":
				_mesh(self, _box(Vector3(l.text.length() * 0.42 + 0.4, 0.04, 0.04)), _glow(col, 3.0), at + Vector3(0, 1.95, 0))
		"crowd":                                         # 관중(낮은 실루엣 줄)
			var m := _shared(Color(0.08, 0.07, 0.08), 0.9)
			for i in 5:
				var x := -1.6 + i * 0.8
				_mesh(self, _cyl(0.22, 0.26, 1.3), m, at + Vector3(x, 0.65, sin(i * 1.7) * 0.2))
				_mesh(self, _sphere(0.18), m, at + Vector3(x, 1.45, sin(i * 1.7) * 0.2))
		"slots":                                         # 슬롯머신 줄
			var n: int = o.get("n", 8)
			for i in n:
				var x := (i - (n - 1) * 0.5) * 1.2
				_mesh(self, _box(Vector3(0.9, 1.7, 0.7)), _shared(Color(0.25, 0.1, 0.3), 0.4, 0.0, 0.3), at + Vector3(x, 0.85, 0))
				_mesh(self, _box(Vector3(0.6, 0.45, 0.04)), _glow(Color(0.3, 0.9, 1.0) if i % 2 == 0 else Color(1.0, 0.4, 0.8), 2.4), at + Vector3(x, 1.2, 0.36))
		"stool":
			_mesh(self, _cyl(0.2, 0.2, 0.06), _shared(Color(0.6, 0.1, 0.12), 0.5), at + Vector3(0, 0.62, 0))
			_mesh(self, _cyl(0.04, 0.04, 0.6), _shared(Color(0.6, 0.6, 0.62), 0.3, 0.0, 0.8), at + Vector3(0, 0.3, 0))
		"building":
			var h: float = o.get("h", 6.0)
			_mesh(self, _box(Vector3(4.6, h, 3.0)), _shared(col, 0.85), at + Vector3(0, h * 0.5, 0))
			for k in 3:
				for j in 3:
					var lit := (k + j) % 2 == 0
					_mesh(self, _box(Vector3(0.7, 0.8, 0.04)), _glow(Color(1.0, 0.8, 0.5), 1.4) if lit else _shared(Color(0.1, 0.12, 0.15), 0.2),
						at + Vector3(-1.4 + k * 1.4, 2.0 + j * 1.5, 1.52))
		"shutter":
			_mesh(self, _box(Vector3(2.6, 2.4, 0.08)), _shared(Color(0.5, 0.52, 0.54), 0.5, 0.0, 0.6), at + Vector3(0, 1.2, 0))
			for y in range(1, 12):
				_mesh(self, _box(Vector3(2.6, 0.02, 0.1)), _shared(Color(0.36, 0.37, 0.4), 0.5, 0.0, 0.6), at + Vector3(0, y * 0.2, 0))
		"barrel":
			_barrel(at, Color(0.3, 0.32, 0.36))
		"crate":
			var m := _shared(Color(0.5, 0.36, 0.2), 0.85)
			_mesh(self, _box(Vector3(1.0, 1.0, 1.0)), m, at + Vector3(0, 0.5, 0))
			_mesh(self, _box(Vector3(0.8, 0.8, 0.8)), m, at + Vector3(0.6, 0.4, -0.5))
			_mesh(self, _box(Vector3(0.9, 0.9, 0.9)), m, at + Vector3(0.1, 1.45, -0.1))
		"car":
			_car(at, 0.0, col, false)
		"van":
			var g := _group(at)
			_mesh(g, _box(Vector3(4.6, 1.8, 1.9)), _shared(Color(0.9, 0.9, 0.9), 0.4), Vector3(0, 1.1, 0))
			_mesh(g, _box(Vector3(1.0, 0.7, 1.8)), _shared(Color(0.15, 0.2, 0.26), 0.1, 0.0, 0.5), Vector3(1.9, 1.5, 0))
		"line":
			_decal(Rect2(at.x - float(o.get("w", 10.0)) * 0.5, at.z - float(o.get("d", 0.14)) * 0.5, o.get("w", 10.0), o.get("d", 0.14)),
				_shared(o.get("col", Color(0.9, 0.75, 0.2)), 0.6))
		"pillar":
			_pillar(at, o.get("col", Color(0.75, 0.7, 0.6)))
		"sofa":
			_sofa(at)
		"plant":
			_plant(at)
		"desk":
			_desk(at)
		"round_table":
			_round_table(at)
		"trophy":
			_mesh(self, _box(Vector3(1.4, 2.2, 0.5)), _shared(Color(0.3, 0.18, 0.1), 0.4), at + Vector3(0, 1.1, 0))
			for y in [0.9, 1.5]:
				for x in [-0.4, 0.0, 0.4]:
					_mesh(self, _cyl(0.06, 0.1, 0.3), _shared(Color(0.9, 0.75, 0.3), 0.25, 0.0, 0.9), at + Vector3(x, y, 0.15))
		"pool":
			_mesh(self, _box(Vector3(2.6, 0.12, 1.4)), _shared(Color(0.1, 0.45, 0.25), 0.9), at + Vector3(0, 0.82, 0))
			_mesh(self, _box(Vector3(2.8, 0.76, 1.6)), _shared(Color(0.3, 0.18, 0.1), 0.4), at + Vector3(0, 0.38, 0))
			_mesh(self, _box(Vector3(1.2, 0.08, 0.6)), _glow(Color(0.9, 1.0, 0.8), 1.4), at + Vector3(0, 2.4, 0))
		"bed":
			_mesh(self, _box(Vector3(2.0, 0.6, 0.9)), _shared(Color(0.7, 0.74, 0.72), 0.6), at + Vector3(0, 0.3, 0))
			_mesh(self, _box(Vector3(1.9, 0.1, 0.8)), _shared(Color(0.85, 0.9, 0.88), 0.9), at + Vector3(0, 0.65, 0))
		"lamp_op":
			_mesh(self, _cyl(0.5, 0.3, 0.2), _glow(Color(0.9, 1.0, 0.95), 2.0), at + Vector3(0, 2.4, 0))
			_mesh(self, _box(Vector3(0.05, 1.0, 0.05)), _shared(Color(0.6, 0.6, 0.6), 0.3, 0.0, 0.8), at + Vector3(0, 2.9, 0))
		"door":
			_mesh(self, _box(Vector3(1.0, 2.2, 0.08)), _shared(col.lightened(0.1), 0.6), at + Vector3(0, 1.1, 0))
			_mesh(self, _box(Vector3(0.06, 0.06, 0.08)), _shared(Color(0.8, 0.75, 0.6), 0.3, 0.0, 0.8), at + Vector3(0.38, 1.05, 0.06))
		"elevator":
			_elevator(at, "7")
		"house":                                         # 물가 목조 집(뒤)
			var wood := _shared(Color(0.36, 0.25, 0.16), 0.85)
			_mesh(self, _box(Vector3(8.0, 3.0, 3.0)), wood, at + Vector3(0, 1.5, -0.6))
			_mesh(self, _box(Vector3(8.6, 0.2, 3.6)), _shared(Color(0.2, 0.14, 0.1), 0.8), at + Vector3(0, 3.1, -0.6))
			for x in [-2.4, 0.0, 2.4]:
				_mesh(self, _box(Vector3(1.0, 0.9, 0.04)), _glow(Color(1.0, 0.75, 0.4), 1.2), at + Vector3(x, 1.6, 0.92))
		"boat":
			var g := _group(at, 10.0)
			_mesh(g, _box(Vector3(3.6, 0.5, 1.2)), _shared(Color(0.4, 0.28, 0.18), 0.8), Vector3(0, 0.0, 0))
			_mesh(g, _box(Vector3(3.2, 0.1, 1.0)), _shared(Color(0.3, 0.2, 0.12), 0.8), Vector3(0, 0.22, 0))
		"post":
			_mesh(self, _cyl(0.12, 0.14, 1.6), _shared(Color(0.3, 0.22, 0.14), 0.9), at + Vector3(0, 0.3, 0))
		"lamp":
			_lamp_post(at, col, 4.0, 0.6, true)
		"machine":
			_mesh(self, _box(Vector3(2.2, 2.0, 1.4)), _shared(Color(0.35, 0.4, 0.36), 0.6, 0.0, 0.5), at + Vector3(0, 1.0, 0))
			_mesh(self, _cyl(0.4, 0.4, 0.3), _shared(Color(0.25, 0.25, 0.27), 0.5, 0.0, 0.7), at + Vector3(0.6, 2.15, 0))
			_mesh(self, _box(Vector3(0.3, 0.2, 0.04)), _glow(Color(1.0, 0.3, 0.2), 1.6), at + Vector3(-0.6, 1.4, 0.72))
		"beam":
			_mesh(self, _box(Vector3(0.3, 4.4, 0.3)), _shared(Color(0.55, 0.3, 0.18), 0.6, 0.0, 0.6), at + Vector3(0, 2.2, 0))
		"altar":
			_mesh(self, _box(Vector3(3.2, 1.0, 0.9)), _shared(Color(0.95, 0.95, 0.93), 0.6), at + Vector3(0, 0.5, 0))
			_mesh(self, _box(Vector3(0.6, 0.8, 0.06)), _shared(Color(0.15, 0.15, 0.15), 0.3), at + Vector3(0, 1.5, -0.2))
			for x in [-1.2, 1.2]:
				_mesh(self, _cyl(0.04, 0.04, 0.3), _glow(Color(1.0, 0.85, 0.5), 2.0), at + Vector3(x, 1.15, 0))
		"wreath":
			var c := _mesh(self, _cyl(0.55, 0.55, 0.12), _shared(Color(0.95, 0.95, 0.9), 0.8), at + Vector3(0, 1.4, 0))
			c.rotation_degrees.x = 90
			_mesh(self, _box(Vector3(0.06, 1.4, 0.06)), _shared(Color(0.3, 0.3, 0.3), 0.5), at + Vector3(0, 0.7, 0))
		"tank":
			_mesh(self, _cyl(0.9, 0.9, 2.2), _shared(Color(0.6, 0.62, 0.6), 0.5, 0.0, 0.5), at + Vector3(0, 1.4, 0))
		"vent":
			_mesh(self, _box(Vector3(1.2, 0.9, 1.0)), _shared(Color(0.55, 0.56, 0.58), 0.4, 0.0, 0.6), at + Vector3(0, 0.45, 0))
		"container":
			var g := _group(at)
			_mesh(g, _box(Vector3(6.0, 2.6, 2.4)), _shared(col, 0.7, 0.0, 0.4), Vector3(0, 1.3, 0))
			for k in 10:
				_mesh(g, _box(Vector3(0.05, 2.4, 0.04)), _shared(col.darkened(0.3), 0.7), Vector3(-2.7 + k * 0.6, 1.3, 1.22))
		"winch":
			var c := _mesh(self, _cyl(0.5, 0.5, 1.2), _shared(Color(0.7, 0.55, 0.1), 0.5, 0.0, 0.5), at + Vector3(0, 0.7, 0))
			c.rotation_degrees.z = 90
		"rope_coil":
			_mesh(self, _cyl(0.5, 0.5, 0.25), _shared(Color(0.7, 0.6, 0.4), 0.95), at + Vector3(0, 0.12, 0))
		"pipes":
			var w: float = o.get("w", 10.0)
			for y in [1.6, 2.2, 2.8]:
				var c := _mesh(self, _cyl(0.1, 0.1, w), _shared(Color(0.4, 0.45, 0.44), 0.5, 0.0, 0.7), at + Vector3(0, y, -0.1))
				c.rotation_degrees.z = 90
		"console":
			_mesh(self, _box(Vector3(2.0, 1.0, 0.8)), _shared(Color(0.25, 0.27, 0.3), 0.5, 0.0, 0.5), at + Vector3(0, 0.5, 0))
			_mesh(self, _box(Vector3(1.6, 0.04, 0.5)), _glow(Color(0.3, 1.0, 0.5), 1.2), at + Vector3(0, 1.02, 0))
		"wheel":
			var c := _mesh(self, _cyl(0.45, 0.45, 0.06), _shared(Color(0.4, 0.26, 0.14), 0.5), at + Vector3(0, 1.3, 0))
			c.rotation_degrees.x = 90
		"long_table":
			_mesh(self, _box(Vector3(6.0, 0.08, 1.6)), _shared(Color(0.16, 0.12, 0.1), 0.3), at + Vector3(0, 0.76, 0))
			for x in [-2.6, 2.6]:
				_mesh(self, _box(Vector3(0.1, 0.74, 1.4)), _shared(Color(0.12, 0.1, 0.08), 0.3), at + Vector3(x, 0.37, 0))
		"stall":                                         # 시장 노점(천막)
			_mesh(self, _box(Vector3(3.0, 0.08, 1.8)), _shared(col, 0.8), at + Vector3(0, 2.3, 0))
			_mesh(self, _box(Vector3(2.8, 0.8, 1.2)), _shared(Color(0.45, 0.35, 0.25), 0.85), at + Vector3(0, 0.4, 0))
			for x in [-1.4, 1.4]:
				_mesh(self, _box(Vector3(0.06, 2.3, 0.06)), _shared(Color(0.4, 0.4, 0.4), 0.5), at + Vector3(x, 1.15, 0.8))
		"bar":
			var w: float = o.get("w", 6.0)
			_mesh(self, _box(Vector3(w, 1.05, 0.7)), _shared(Color(0.3, 0.18, 0.1), 0.35), at + Vector3(0, 0.52, 0))
			_mesh(self, _box(Vector3(w, 1.8, 0.4)), _shared(Color(0.2, 0.12, 0.08), 0.5), at + Vector3(0, 1.4, -0.6))
			for i in int(w / 0.5):
				_mesh(self, _cyl(0.05, 0.05, 0.28), _shared(Color(0.3, 0.6, 0.3) if i % 3 == 0 else Color(0.6, 0.4, 0.15), 0.1, 0.0, 0.2),
					at + Vector3(-w * 0.5 + 0.25 + i * 0.5, 1.4, -0.38))
		"shelf":
			_mesh(self, _box(Vector3(3.0, 3.2, 1.0)), _shared(Color(0.3, 0.45, 0.65), 0.5, 0.0, 0.5), at + Vector3(0, 1.6, 0))
			for y in [0.6, 1.6, 2.6]:
				_mesh(self, _box(Vector3(2.6, 0.7, 0.8)), _shared(Color(0.55, 0.42, 0.26), 0.85), at + Vector3(0, y, 0.05))
		"forklift":
			_mesh(self, _box(Vector3(1.4, 1.2, 1.0)), _shared(Color(0.95, 0.7, 0.1), 0.5), at + Vector3(0, 0.8, 0))
			_mesh(self, _box(Vector3(0.1, 2.2, 0.8)), _shared(Color(0.2, 0.2, 0.2), 0.5, 0.0, 0.6), at + Vector3(0.8, 1.1, 0))
		"chandelier":                                     # 걸을 곳 위 높이(카메라를 가리지 않게 3.8m)
			_mesh(self, _sphere(0.5), _glow(Color(1.0, 0.9, 0.65), 2.0), at + Vector3(0, 3.8, 0))
		"speaker":
			_mesh(self, _box(Vector3(1.0, 2.0, 0.8)), _shared(Color(0.06, 0.06, 0.07), 0.6), at + Vector3(0, 1.0, 0))
			for y in [0.6, 1.4]:
				var c := _mesh(self, _cyl(0.3, 0.3, 0.04), _shared(Color(0.15, 0.15, 0.16), 0.4), at + Vector3(0, y, 0.41))
				c.rotation_degrees.x = 90
		"dots":                                          # 무대 바닥 빛 점(클럽)
			for i in 14:
				var p := Vector3(at.x - 5.0 + (i * 2.3) - floor(i * 2.3 / 10.0) * 10.0, 0.006, at.z - 1.0 + float(i % 3))
				_mesh(self, _cyl(0.3, 0.3, 0.004), _glow(Color(0.8, 0.3, 1.0) if i % 2 == 0 else Color(0.2, 0.9, 1.0), 1.4), p)
		"red_pillar":
			_mesh(self, _cyl(0.3, 0.3, 3.4), _shared(Color(0.7, 0.1, 0.06), 0.4), at + Vector3(0, 1.7, 0))
			_mesh(self, _box(Vector3(0.8, 0.2, 0.8)), _shared(Color(0.85, 0.65, 0.2), 0.3, 0.0, 0.8), at + Vector3(0, 3.4, 0))
		"lantern":
			_mesh(self, _sphere(0.3), _glow(Color(1.0, 0.25, 0.1), 2.0), at + Vector3(0, 2.4, 0))
		"gold_roof":
			_mesh(self, _box(Vector3(b.size.x + 4.0, 0.3, 1.6)), _shared(Color(0.85, 0.65, 0.2), 0.3, 0.0, 0.8), at + Vector3(0, 3.6, 0))
		"anvil":
			_mesh(self, _box(Vector3(0.8, 0.5, 0.4)), _shared(Color(0.2, 0.2, 0.22), 0.4, 0.0, 0.8), at + Vector3(0, 0.75, 0))
			_mesh(self, _box(Vector3(0.4, 0.5, 0.4)), _shared(Color(0.25, 0.22, 0.2), 0.6), at + Vector3(0, 0.25, 0))
		"roof_beams":                                    # 아케이드 지붕(높게 — 4m)
			for k in 5:
				_mesh(self, _box(Vector3(0.12, 0.12, b.size.y + 2.0)), _shared(Color(0.35, 0.3, 0.26), 0.6, 0.0, 0.6),
					Vector3(b.position.x + k * b.size.x / 4.0, 4.2, b.get_center().y))
		"books":
			_mesh(self, _box(Vector3(3.6, 3.2, 0.5)), _shared(Color(0.25, 0.15, 0.08), 0.6), at + Vector3(0, 1.6, 0))
			for y in [0.5, 1.2, 1.9, 2.6]:
				for x in 6:
					_mesh(self, _box(Vector3(0.5, 0.5, 0.3)), _shared([Color(0.5, 0.12, 0.1), Color(0.15, 0.25, 0.4), Color(0.6, 0.5, 0.2)][(x + int(y * 3)) % 3], 0.8),
						at + Vector3(-1.5 + x * 0.6, y, 0.14))
		"church":
			_mesh(self, _box(Vector3(10.0, 6.0, 3.0)), _shared(Color(0.62, 0.6, 0.58), 0.8), at + Vector3(0, 3.0, -0.6))
			_mesh(self, _box(Vector3(2.0, 3.0, 0.1)), _shared(Color(0.25, 0.16, 0.1), 0.5), at + Vector3(0, 1.5, 0.92))
			for x in [-3.0, 3.0]:
				_mesh(self, _box(Vector3(1.0, 2.2, 0.06)), _glow(Color(0.6, 0.4, 1.0), 1.0), at + Vector3(x, 3.2, 0.92))
		"cross":
			var y: float = o.get("y", 2.4)
			var m := _glow(Color(1.0, 0.92, 0.75), 1.8)
			_mesh(self, _box(Vector3(0.14, 1.4, 0.1)), m, at + Vector3(0, y, 0))
			_mesh(self, _box(Vector3(0.8, 0.14, 0.1)), m, at + Vector3(0, y + 0.3, 0))
		"stained":
			var cols := [Color(0.9, 0.2, 0.2), Color(0.2, 0.4, 1.0), Color(1.0, 0.85, 0.2), Color(0.3, 0.8, 0.4)]
			for k in 4:
				_mesh(self, _box(Vector3(0.36, 0.9, 0.04)), _glow(cols[k], 1.4), at + Vector3(-0.6 + k * 0.4, 2.2, 0))
		"pews":
			for x in [-4.4, -2.2, 2.2, 4.4]:
				_mesh(self, _box(Vector3(1.8, 0.5, 0.5)), _shared(Color(0.35, 0.22, 0.12), 0.6), at + Vector3(x, 0.45, 0))
				_mesh(self, _box(Vector3(1.8, 0.6, 0.08)), _shared(Color(0.35, 0.22, 0.12), 0.6), at + Vector3(x, 0.8, -0.25))
		"cubicle":
			_mesh(self, _box(Vector3(2.6, 1.3, 0.08)), _shared(Color(0.4, 0.45, 0.42), 0.8), at + Vector3(0, 0.65, 0))
			_mesh(self, _box(Vector3(1.6, 0.06, 0.7)), _shared(Color(0.6, 0.58, 0.54), 0.5), at + Vector3(0, 0.74, 0.4))
			_mesh(self, _box(Vector3(0.5, 0.35, 0.04)), _glow(Color(0.6, 1.0, 0.7), 1.2), at + Vector3(0, 1.0, 0.2))
		"scaffold":
			var m := _shared(Color(0.55, 0.55, 0.58), 0.4, 0.0, 0.8)
			for x in [-1.2, 1.2]:
				for z in [-0.4, 0.4]:
					_mesh(self, _cyl(0.04, 0.04, 3.6), m, at + Vector3(x, 1.8, z))
			for y in [1.2, 2.4, 3.5]:
				_mesh(self, _box(Vector3(2.5, 0.06, 0.9)), _shared(Color(0.45, 0.35, 0.2), 0.8), at + Vector3(0, y, 0))
		"blocks":
			for k in 3:
				_mesh(self, _box(Vector3(1.2, 0.4, 0.6)), _shared(Color(0.55, 0.55, 0.52), 0.9), at + Vector3(0, 0.2 + k * 0.4, 0))
		"tub":
			_mesh(self, _cyl(0.5, 0.42, 0.6), _shared(Color(0.3, 0.3, 0.32), 0.6, 0.0, 0.4), at + Vector3(0, 0.3, 0))
			_mesh(self, _cyl(0.46, 0.46, 0.02), _shared(Color(0.55, 0.55, 0.52), 0.9), at + Vector3(0, 0.56, 0))
		"museum":
			_mesh(self, _box(Vector3(14.0, 5.0, 3.0)), _shared(o.get("col", Color(0.75, 0.73, 0.7)), 0.7), at + Vector3(0, 2.5, -0.6))
			for x in range(-5, 6, 2):
				_mesh(self, _cyl(0.3, 0.3, 4.6), _shared(Color(0.85, 0.84, 0.8), 0.6), at + Vector3(x, 2.3, 1.1))
			_mesh(self, _box(Vector3(14.6, 0.3, 4.0)), _shared(Color(0.65, 0.64, 0.6), 0.6), at + Vector3(0, 5.1, -0.2))
		"statue":
			_mesh(self, _box(Vector3(0.9, 1.2, 0.9)), _shared(Color(0.6, 0.6, 0.58), 0.7), at + Vector3(0, 0.6, 0))
			_mesh(self, _cyl(0.2, 0.3, 1.4), _shared(Color(0.35, 0.45, 0.38), 0.4, 0.0, 0.6), at + Vector3(0, 1.9, 0))
			_mesh(self, _sphere(0.22), _shared(Color(0.35, 0.45, 0.38), 0.4, 0.0, 0.6), at + Vector3(0, 2.75, 0))


## 물(뒤쪽 · 아래 — 저수지 · 바다). sea_view: 유리창 너머 먼 바다만
func _water(b: Rect2, far_only: bool) -> void:
	var m := _mat(Color(0.08, 0.16, 0.24), 0.08, 0.0, 0.3)
	var pm := PlaneMesh.new()
	pm.size = Vector2(b.size.x + 60.0, 60.0)
	var z := b.position.y - 31.0 if far_only else b.get_center().y
	_mesh(self, pm, m, Vector3(b.get_center().x, -0.6 if not far_only else -6.0, z))


func _water_back(b: Rect2) -> void:
	var pm := PlaneMesh.new()
	pm.size = Vector2(b.size.x + 60.0, 30.0)
	_mesh(self, pm, _shared(Color(0.12, 0.3, 0.38), 0.1, 0.0, 0.3), Vector3(b.get_center().x, -0.4, b.position.y - 17.0))


## 난간(갑판 · 옥상 뒤 끝)
func _rail(b: Rect2) -> void:
	var m := _shared(Color(0.75, 0.75, 0.72), 0.4, 0.0, 0.7)
	var z := b.position.y - 0.4
	_mesh(self, _box(Vector3(b.size.x + 4.0, 0.06, 0.06)), m, Vector3(b.get_center().x, 1.05, z))
	_mesh(self, _box(Vector3(b.size.x + 4.0, 0.04, 0.04)), m, Vector3(b.get_center().x, 0.55, z))
	for i in int(b.size.x / 1.2) + 4:
		_mesh(self, _box(Vector3(0.05, 1.05, 0.05)), m, Vector3(b.position.x - 2.0 + i * 1.2, 0.52, z))


## 비(입자 — 상세일 때만) — 내리는 가는 줄
func _rain(center: Vector3, ext: Vector3, amount: int) -> void:
	if not _detail:
		return
	var p := CPUParticles3D.new()
	p.amount = amount
	p.lifetime = 0.9
	p.preprocess = 1.0
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	p.emission_box_extents = ext
	p.direction = Vector3(0.1, -1, 0)
	p.spread = 4.0
	p.initial_velocity_min = 7.0
	p.initial_velocity_max = 9.0
	p.gravity = Vector3(0, -2, 0)
	var s := BoxMesh.new()
	s.size = Vector3(0.012, 0.34, 0.012)
	p.mesh = s
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(0.75, 0.82, 0.95, 0.45)
	p.material_override = m
	p.position = center
	add_child(p)
