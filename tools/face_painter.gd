extends RefCounted
## 2D 웹툰 얼굴 아틀라스 생성기(tools/make_models.gd 가 호출 — 512x512 RGB8 텍스처의 좌상단 256x256).
## 4개 128x128 표정 칸(2x2):
##   (0,0) 0 평소 · (1,0) 1 전투/분노 · (0,1) 2 피격/고통 · (1,1) 3 기절/눈감음
## 머리 앞면 반구 UV([0..0.25]²)에 직접 투영 — 떠 있는 3D 패치(_patch)와 외곽선 고리를 없애고,
## 안티앨리어싱된 웹툰 눈매 · 속눈썹 · 홍채 그라데이션 · 광택 입술 · 볼터치 · 흉터 · 수염을 선명하게 그린다.

const Looks = preload("res://src/view/looks.gd")
const QUAD := 128


static func paint(data: PackedByteArray, tex_size: int, lk: Dictionary) -> void:
	for expr in 4:
		var ox := (expr % 2) * QUAD
		var oy := (expr / 2) * QUAD
		_paint_quad(data, tex_size, ox, oy, lk, expr)


static func _paint_quad(data: PackedByteArray, tex_size: int, ox: int, oy: int, lk: Dictionary, expr: int) -> void:
	var sk: Color = lk["skin"]
	var fem: bool = lk.get("female", false)
	var has_mask: bool = lk.get("mask") != null
	var hair_col: Color = Looks.hair_lift(lk["hair"])
	var brow_col: Color = hair_col.darkened(0.22 if fem else 0.34)
	var lash := Color(0.055, 0.035, 0.045)
	var eye_col: Color = lk.get("eye_col", Color(0.14, 0.09, 0.07) if fem else Color(0.11, 0.08, 0.06))
	var eh_k := float(lk.get("eye_h", 0.011))
	var sharp: bool = eh_k <= 0.008
	var slit: bool = (not fem) and eh_k <= 0.006
	var brow_k: float = float(lk.get("brow_k", 1.0))
	var brow_tilt: float = float(lk.get("brow_tilt", 6.0))
	var blind := str(lk.get("blind_eye", ""))
	var blank_eyes: bool = lk.get("blank_eyes", false)
	var lips_raw = lk.get("lips")
	var lips_col: Color
	if fem:
		var l0: Color = lips_raw if lips_raw is Color else sk.lerp(Color(0.82, 0.34, 0.40), 0.5)
		lips_col = Color.from_hsv(l0.h, minf(1.0, l0.s * 1.28), clampf(l0.v * 0.96, 0.15, 0.92))
	else:
		lips_col = sk.darkened(0.46) if not (lips_raw is Color) else (lips_raw as Color).darkened(0.25)
	var beard_raw: Color = lk.get("beard_col", lk["hair"])
	var beard_col: Color = Looks.hair_lift(beard_raw).darkened(0.16)
	var stubble_col: Color = sk.darkened(0.15).lerp(beard_col, 0.16)
	var shadow_col: Color = lk.get("shadow", Color(0.56, 0.36, 0.42))
	var bruise_raw = lk.get("bruise")
	var mask_col: Color = lk["mask"] if has_mask else Color.WHITE
	var scar_list: Array = []
	var sc = lk.get("scar", false)
	if sc is String or (sc is bool and sc):
		for s in (str(sc) if sc is String else "cheek_l").split("+"):
			if s != "" and s != "head":
				scar_list.append(s)
	var scar_c: Color = Looks.scar_col(lk)
	var ep := str(lk.get("eyepatch", "")) if lk.get("eyepatch") != null else ""

	# 표정별 변형값
	var eye_scale_y := 1.0
	var brow_drop := 0.0
	var brow_ang_add := 0.0
	if expr == 1:                  # 전투/분노: 눈매 날카롭게 · 눈썹 찌푸림
		eye_scale_y = 0.82
		brow_drop = 0.025
		brow_ang_add = 0.22
	elif expr == 2:                # 피격/고통
		brow_drop = 0.03
		brow_ang_add = 0.18

	var eh := (0.078 if sharp else 0.090) if fem else (0.036 if slit else (0.056 if sharp else 0.068))
	eh *= eye_scale_y
	var ew := 0.128 if fem else 0.122
	var eye_x := 0.215 if fem else 0.228
	var eye_y := 0.025 if fem else 0.012

	for py in QUAD:
		# fy: -1(정수리) .. 0(눈 높이) .. +1(턱 끝)
		var fy := ((float(py) + 0.5) / float(QUAD) - 0.5) * 2.0
		for px in QUAD:
			# fx: -1(왼귀 -X) .. 0(코 -Z) .. +1(오른귀 +X)
			var fx := ((float(px) + 0.5) / float(QUAD) - 0.5) * 2.0
			var c := sk

			# 1. 얼굴 입체 음영(볼 윤곽 · 턱선 · 이마 음영)
			if not has_mask:
				var edge_shade := smoothstep(0.55, 0.96, absf(fx)) * 0.10 + smoothstep(0.52, 0.92, fy) * 0.12
				c = c.lerp(sk.darkened(0.24).lerp(Color(0.55, 0.30, 0.28), 0.18), edge_shade)
				if fem:
					# 은은한 핑크빛 볼 터치
					for sx: float in [-1.0, 1.0]:
						var bd := Vector2((fx - 0.32 * sx) / 0.17, (fy - 0.19) / 0.10).length()
						var bl := (1.0 - smoothstep(0.15, 1.0, bd)) * 0.30
						c = c.lerp(Color(0.96, 0.48, 0.54), bl)
				else:
					# 남성 광대 · 턱 밑 각진 음영
					var cheek_sh := (1.0 - smoothstep(0.05, 0.24, absf(absf(fx) - 0.42))) * smoothstep(-0.02, 0.18, fy) * (1.0 - smoothstep(0.24, 0.45, fy))
					c = c.lerp(sk.darkened(0.16), cheek_sh * 0.35)
					# 수염 그늘 · 짧은 수염
					if lk.get("stubble", false):
						var sd := Vector2(fx / 0.38, (fy - 0.52) / 0.26).length()
						c = c.lerp(stubble_col, (1.0 - smoothstep(0.55, 1.0, sd)) * 0.72)
						var md := Vector2(fx / 0.14, (fy - 0.24) / 0.045).length()
						c = c.lerp(stubble_col, (1.0 - smoothstep(0.45, 1.0, md)) * 0.65)
					if lk.get("beard", false):
						var bd2 := Vector2(fx / 0.40, (fy - 0.54) / 0.28).length()
						c = c.lerp(beard_col, (1.0 - smoothstep(0.68, 0.95, bd2)) * 0.92)
						var md2 := Vector2(fx / 0.16, (fy - 0.24) / 0.048).length()
						c = c.lerp(beard_col, (1.0 - smoothstep(0.55, 0.9, md2)) * 0.90)
					if lk.get("sideburns", false):
						for sx: float in [-1.0, 1.0]:
							var sbd := _seg_dist(Vector2(fx, fy), Vector2(0.58 * sx, -0.02), Vector2(0.44 * sx, 0.44))
							c = c.lerp(beard_col, 1.0 - smoothstep(0.032, 0.052, sbd))
							if lk.get("goatee", false):
								var jbd := _seg_dist(Vector2(fx, fy), Vector2(0.44 * sx, 0.44), Vector2(0.10 * sx, 0.60))
								c = c.lerp(beard_col, 1.0 - smoothstep(0.024, 0.042, jbd))
			else:
				# 복면 · 가면(DS 습격조 / 하회탈 / 붉은점 가면)
				c = mask_col
				var is_balaclava: bool = mask_col.get_luminance() < 0.15
				if is_balaclava:
					# 눈 구멍만 살빛
					var slit_d := Vector2(fx / 0.42, (fy - eye_y) / 0.105).length()
					var in_slit := 1.0 - smoothstep(0.84, 0.98, slit_d)
					c = c.lerp(sk, in_slit)
				else:
					# 하회탈 / 붉은점 가면: 눈 구멍 어둡게 + 가면 특유 무늬
					var is_redspot: bool = mask_col.get_luminance() > 0.80
					if is_redspot:
						var dot_d := Vector2(fx, fy + 0.24).length()
						c = c.lerp(Color(0.82, 0.10, 0.10), 1.0 - smoothstep(0.065, 0.088, dot_d))
					else:
						# 하회탈 굵은 눈썹 · 웃는 주름
						for sx: float in [-1.0, 1.0]:
							var hb := _seg_dist(Vector2(fx, fy), Vector2(0.10 * sx, -0.18), Vector2(0.36 * sx, -0.22))
							c = c.lerp(Color(0.16, 0.10, 0.06), 1.0 - smoothstep(0.022, 0.036, hb))
							var cr := _seg_dist(Vector2(fx, fy), Vector2(0.12 * sx, 0.16), Vector2(0.30 * sx, 0.34))
							c = c.lerp(mask_col.darkened(0.45), (1.0 - smoothstep(0.014, 0.028, cr)) * 0.8)
						var sm := _seg_dist(Vector2(fx, fy), Vector2(-0.18, 0.34), Vector2(0.18, 0.34))
						c = c.lerp(Color(0.14, 0.08, 0.05), 1.0 - smoothstep(0.020, 0.032, sm))
					for sx: float in [-1.0, 1.0]:
						var ed_m := Vector2((fx - 0.22 * sx) / 0.10, (fy - eye_y) / 0.036).length()
						c = c.lerp(Color(0.05, 0.04, 0.05), 1.0 - smoothstep(0.75, 1.0, ed_m))

			# 2. 눈 & 눈썹 (가면 제외, 복면은 눈만 그림)
			var draw_eyes := (not has_mask) or mask_col.get_luminance() < 0.15
			if draw_eyes:
				for sx: float in [-1.0, 1.0]:
					var side_ch := "l" if sx < 0.0 else "r"
					if ep == side_ch:
						continue
					var lx: float = (fx - eye_x * sx) * sx       # 안쪽(-), 바깥쪽(+)
					var ly: float = fy - eye_y                   # 위(-), 아래(+)
					var tilt_e: float = -0.09 if fem else -0.06
					var ry_t: float = ly - lx * tilt_e

					if expr == 3:
						# 눈 감음(기절 · 잠 · 누움): 우아하게 아래로 휜 속눈썹 곡선
						var curve_y := 0.018 * (1.0 - (lx / ew) * (lx / ew))
						var ld := absf(ry_t - curve_y)
						var in_x := 1.0 - smoothstep(ew * 0.85, ew * 1.08, absf(lx))
						c = c.lerp(lash, (1.0 - smoothstep(0.008, 0.018, ld)) * in_x)
					elif expr == 2:
						# 피격/고통: 꽉 감은 > < 눈매
						var vy := -absf(lx + 0.015) * 0.42 + 0.015
						var d1 := absf(ly - vy)
						var d2 := absf(ly + vy * 0.85 - 0.01)
						var in_x := 1.0 - smoothstep(ew * 0.78, ew * 0.98, absf(lx))
						var w_line := maxf(1.0 - smoothstep(0.009, 0.018, d1), 1.0 - smoothstep(0.009, 0.018, d2)) * in_x
						c = c.lerp(lash, w_line)
					else:
						# 여성 눈두덩 음영(화장)
						if fem and not has_mask:
							var sh_d := Vector2((lx - 0.01) / (ew * 1.25), (ry_t + eh * 1.15) / (eh * 0.95)).length()
							c = c.lerp(sk.lerp(shadow_col, 0.58), (1.0 - smoothstep(0.2, 1.0, sh_d)) * 0.55)
						# 아몬드 눈 모양 SDF
						var ax := lx / ew
						var ay := ry_t / eh
						var almond := ax * ax + ay * ay * (1.0 + 0.35 * ax * ax)
						var in_eye := 1.0 - smoothstep(0.84, 1.02, almond)
						if in_eye > 0.001:
							var dead_eye: bool = blank_eyes or blind == side_ch
							var sclera := Color(0.97, 0.96, 0.95)
							# 윗눈꺼풀이 흰자 위쪽에 드리우는 그림자(웹툰 눈 입체감 핵심!)
							var top_sh := smoothstep(-0.15, -0.85, ay)
							sclera = sclera.lerp(Color(0.76, 0.78, 0.86), top_sh * 0.52)
							var ec := sclera
							if not blank_eyes:
								var ir_r := (0.066 if fem else 0.048)
								var idist := Vector2(lx + 0.004, ry_t - 0.002).length() / ir_r
								var in_iris := 1.0 - smoothstep(0.84, 1.02, idist)
								if in_iris > 0.001:
									var ic_base: Color = Color(0.70, 0.72, 0.75) if dead_eye else eye_col
									# 홍채 상단은 짙고 하단은 영롱하게 빛나는 2톤 그라데이션
									var grad_v := clampf((ry_t / ir_r) * 0.5 + 0.5, 0.0, 1.0)
									var ic := ic_base.darkened(0.42).lerp(ic_base.lightened(0.32 if fem else 0.18), grad_v)
									# 홍채 테두리 림
									ic = ic.lerp(ic_base.darkened(0.65), smoothstep(0.70, 0.95, idist))
									# 동공
									var in_pup := 1.0 - smoothstep(0.36, 0.52, idist)
									ic = ic.lerp(Color(0.03, 0.02, 0.03), in_pup * (0.25 if dead_eye else 0.92))
									ec = ec.lerp(ic, in_iris)
								if not dead_eye:
									# 주 하이라이트(눈빛) + 보조 하이라이트
									var h1 := Vector2(lx - 0.016, ry_t + 0.016).length()
									var h2 := Vector2(lx + 0.018, ry_t - 0.018).length()
									ec = ec.lerp(Color.WHITE, (1.0 - smoothstep(0.011, 0.020, h1)) * (0.95 if fem else 0.80))
									if fem:
										ec = ec.lerp(Color(0.95, 0.98, 1.0), (1.0 - smoothstep(0.006, 0.013, h2)) * 0.72)
							c = c.lerp(ec, in_eye)
						# 윗눈꺼풀 굵은 아이라인 + 올라간 눈꼬리
						var upper_y := -eh * sqrt(maxf(0.0, 1.0 - clampf(ax * ax, 0.0, 1.0)))
						var line_w := (0.020 if fem else 0.017) * (1.0 + 0.35 * smoothstep(0.0, 0.9, ax))
						var in_lid := (1.0 - smoothstep(line_w * 0.55, line_w * 1.15, absf(ry_t - upper_y))) * (1.0 - smoothstep(0.85, 1.12, absf(ax)))
						c = c.lerp(lash, in_lid * 0.96)
						# 바깥 눈꼬리 윙(여성은 위로 우아하게, 남성은 바깥으로 날카롭게)
						var wing_a := Vector2(ew * 0.92, 0.0)
						var wing_b := Vector2(ew * (1.38 if fem else 1.24), -eh * (0.62 if fem else 0.16))
						var wd := _seg_dist(Vector2(lx, ry_t), wing_a, wing_b)
						c = c.lerp(lash, (1.0 - smoothstep(0.008, 0.017, wd)) * 0.92)
						if fem:
							# 속눈썹 두 가닥 포인트
							for k in 2:
								var la := Vector2(ew * (0.62 + 0.24 * k), -eh * (0.76 - 0.22 * k))
								var lb := la + Vector2(0.032, -0.036)
								c = c.lerp(lash, (1.0 - smoothstep(0.005, 0.011, _seg_dist(Vector2(lx, ry_t), la, lb))) * 0.85)
						# 아랫눈꺼풀 옅은 선
						var lower_y := eh * sqrt(maxf(0.0, 1.0 - clampf(ax * ax, 0.0, 1.0)))
						var in_low := (1.0 - smoothstep(0.004, 0.011, absf(ry_t - lower_y))) * (1.0 - smoothstep(0.45, 0.88, absf(ax)))
						c = c.lerp(sk.darkened(0.42), in_low * (0.55 if fem else 0.42))

					# 눈썹(복면은 제외)
					if not has_mask:
						var by0 := (-0.130 if fem else -0.115) + brow_drop
						var bt := (deg_to_rad(brow_tilt * 0.55) if not fem else 0.08) + brow_ang_add
						var b_thick := (0.014 if fem else 0.023 * brow_k)
						var p0 := Vector2(eye_x * sx - 0.105 * sx, by0 + 0.015 + sin(bt) * 0.06)
						var p1 := Vector2(eye_x * sx + 0.015 * sx, by0 - (0.020 if fem else 0.008))
						var p2 := Vector2(eye_x * sx + 0.125 * sx, by0 + (0.016 if fem else -0.020 * signf(brow_tilt) - sin(bt) * 0.04))
						var bd_in := _seg_dist(Vector2(fx, fy), p0, p1)
						var bd_out := _seg_dist(Vector2(fx, fy), p1, p2)
						var b_mask := maxf(1.0 - smoothstep(b_thick * 0.65, b_thick * 1.18, bd_in),
							1.0 - smoothstep(b_thick * 0.42, b_thick * 0.90, bd_out))
						c = c.lerp(brow_col, b_mask * 0.92)

			# 3. 코 · 입 · 콧수염/염소수염 · 흉터 · 안대 (가면/복면 제외)
			if not has_mask:
				if fem:
					# 여성 작은 코 하이라이트 + 코끝 그늘
					var nh := Vector2(fx / 0.022, (fy - 0.145) / 0.052).length()
					c = c.lerp(sk.lightened(0.14), (1.0 - smoothstep(0.2, 1.0, nh)) * 0.45)
					var ns := Vector2(fx / 0.036, (fy - 0.210) / 0.012).length()
					c = c.lerp(sk.darkened(0.32), (1.0 - smoothstep(0.4, 1.0, ns)) * 0.65)
				else:
					# 남성 콧등 한쪽 웹툰 그림자 선 + 코끝 선 + 콧구멍 그늘
					var nline := _seg_dist(Vector2(fx, fy), Vector2(-0.045, 0.03), Vector2(-0.052, 0.185))
					c = c.lerp(sk.darkened(0.28), (1.0 - smoothstep(0.006, 0.016, nline)) * 0.72)
					var ntip := _seg_dist(Vector2(fx, fy), Vector2(-0.048, 0.210), Vector2(0.048, 0.210))
					c = c.lerp(sk.darkened(0.44), (1.0 - smoothstep(0.006, 0.015, ntip)) * 0.85)
					for sx: float in [-1.0, 1.0]:
						var nst := Vector2((fx - 0.038 * sx) / 0.020, (fy - 0.196) / 0.010).length()
						c = c.lerp(sk.darkened(0.40), (1.0 - smoothstep(0.4, 1.0, nst)) * 0.6)

				# 입술 / 표정별 입
				var my := 0.355
				if expr == 1 or expr == 2:
					# 전투/피격: 이를 악물거나 벌린 입
					var mw := 0.115 if expr == 1 else 0.105
					var mh := 0.028 if expr == 1 else 0.042
					var md_o := Vector2(fx / mw, (fy - my) / mh).length()
					var in_m := 1.0 - smoothstep(0.78, 1.0, md_o)
					if in_m > 0.001:
						var inside_c := Color(0.95, 0.94, 0.92) if expr == 1 else Color(0.28, 0.08, 0.09)
						c = c.lerp(inside_c, in_m)
					c = c.lerp(lash, (1.0 - smoothstep(0.14, 0.30, absf(md_o - 0.92))) * 0.85)
				elif fem:
					# 여성 도톰한 그라데이션 입술 + 광택 점
					var ul := Vector2(fx / 0.092, (fy - (my - 0.018)) / 0.024).length()
					var ll := Vector2(fx / 0.082, (fy - (my + 0.016)) / 0.030).length()
					c = c.lerp(lips_col.darkened(0.14), (1.0 - smoothstep(0.72, 1.0, ul)) * 0.94)
					c = c.lerp(lips_col, (1.0 - smoothstep(0.72, 1.0, ll)) * 0.94)
					var crease := _seg_dist(Vector2(fx, fy), Vector2(-0.085, my - 0.002), Vector2(0.085, my - 0.002))
					c = c.lerp(lips_col.darkened(0.55), (1.0 - smoothstep(0.005, 0.012, crease)) * 0.9)
					var gloss := Vector2((fx - 0.020) / 0.028, (fy - (my + 0.018)) / 0.010).length()
					c = c.lerp(lips_col.lightened(0.52), (1.0 - smoothstep(0.25, 1.0, gloss)) * 0.78)
				else:
					# 남성 단호한 일자 입 + 아랫입술 그늘
					var mline := _seg_dist(Vector2(fx, fy), Vector2(-0.105, my), Vector2(0.105, my))
					c = c.lerp(lips_col, (1.0 - smoothstep(0.008, 0.018, mline)) * 0.92)
					var lsh := Vector2(fx / 0.048, (fy - (my + 0.042)) / 0.011).length()
					c = c.lerp(sk.darkened(0.22), (1.0 - smoothstep(0.3, 1.0, lsh)) * 0.58)

				# 콧수염 · 염소수염
				if lk.get("mustache", false):
					var m1 := _seg_dist(Vector2(fx, fy), Vector2(-0.11, 0.235), Vector2(0.11, 0.235))
					c = c.lerp(beard_col, 1.0 - smoothstep(0.022, 0.036, m1))
					for sx: float in [-1.0, 1.0]:
						var m2 := _seg_dist(Vector2(fx, fy), Vector2(0.095 * sx, 0.238), Vector2(0.155 * sx, 0.345))
						c = c.lerp(beard_col, 1.0 - smoothstep(0.018, 0.032, m2))
				if lk.get("goatee", false):
					var g1 := Vector2(fx / 0.11, (fy - 0.52) / 0.09).length()
					var g2 := Vector2(fx / 0.036, (fy - 0.39) / 0.034).length()
					c = c.lerp(beard_col, maxf(1.0 - smoothstep(0.75, 1.0, g1), 1.0 - smoothstep(0.7, 1.0, g2)))

				# 의뢰인 멍 · 터진 입가
				if bruise_raw is Color:
					var br_d := Vector2((fx + 0.32) / 0.11, (fy - 0.09) / 0.085).length()
					c = c.lerp(sk.lerp(bruise_raw, 0.62), (1.0 - smoothstep(0.2, 1.0, br_d)) * 0.78)
					var cut_d := _seg_dist(Vector2(fx, fy), Vector2(0.075, my + 0.005), Vector2(0.11, my + 0.035))
					c = c.lerp(Color(0.55, 0.08, 0.09), 1.0 - smoothstep(0.008, 0.016, cut_d))

				# 흉터
				for skind in scar_list:
					var sd2 := _scar_dist(Vector2(fx, fy), str(skind))
					if sd2 < 0.024:
						c = c.lerp(scar_c, (1.0 - smoothstep(0.008, 0.020, sd2)) * 0.92)

				# 안대(남일호)
				if ep != "":
					var ex := -eye_x if ep == "l" else eye_x
					var ep_col := Color(0.05, 0.05, 0.06)
					var patch_d := maxf(absf(fx - ex) / 0.14, absf(fy - eye_y) / 0.115)
					c = c.lerp(ep_col, 1.0 - smoothstep(0.84, 1.0, patch_d))
					var strap1 := _seg_dist(Vector2(fx, fy), Vector2(ex * 0.25, -0.26), Vector2(ex * 2.6, -0.14))
					var strap2 := _seg_dist(Vector2(fx, fy), Vector2(ex, eye_y), Vector2(ex * 2.8, eye_y + 0.05))
					c = c.lerp(ep_col, 1.0 - smoothstep(0.012, 0.022, minf(strap1, strap2)))

			var idx := ((oy + py) * tex_size + (ox + px)) * 3
			data[idx] = clampi(roundi(c.r * 255.0), 0, 255)
			data[idx + 1] = clampi(roundi(c.g * 255.0), 0, 255)
			data[idx + 2] = clampi(roundi(c.b * 255.0), 0, 255)


static func _scar_dist(p: Vector2, kind: String) -> float:
	match kind:
		"cheek_l":
			return _seg_dist(p, Vector2(-0.28, 0.04), Vector2(-0.44, 0.28))
		"cheek_r":
			return _seg_dist(p, Vector2(0.28, 0.04), Vector2(0.44, 0.28))
		"chin":
			return _seg_dist(p, Vector2(0.06, 0.38), Vector2(0.07, 0.58))
		"nose":
			return minf(_seg_dist(p, Vector2(0.0, -0.12), Vector2(-0.42, 0.18)),
				_seg_dist(p, Vector2(0.06, 0.38), Vector2(0.07, 0.56)))
		"brow":
			return _seg_dist(p, Vector2(0.18, -0.44), Vector2(0.26, -0.12))
		"eye_l":
			return _seg_dist(p, Vector2(-0.24, -0.34), Vector2(-0.26, 0.22))
		"eye_r":
			return _seg_dist(p, Vector2(0.24, -0.34), Vector2(0.26, 0.22))
		"x":
			var m := Vector2(0.0, -0.05)
			return minf(minf(_seg_dist(p, Vector2(0.32, -0.42), m), _seg_dist(p, m, Vector2(-0.38, 0.24))),
				minf(_seg_dist(p, Vector2(-0.14, -0.28), m), _seg_dist(p, m, Vector2(0.38, 0.26))))
		"double":
			return minf(_seg_dist(p, Vector2(-0.24, 0.02), Vector2(-0.46, 0.22)),
				_seg_dist(p, Vector2(-0.31, 0.10), Vector2(-0.52, 0.30)))
	return 10.0


static func _seg_dist(p: Vector2, a: Vector2, b: Vector2) -> float:
	var ab := b - a
	var l2 := ab.length_squared()
	if l2 < 1e-8:
		return p.distance_to(a)
	var t := clampf((p - a).dot(ab) / l2, 0.0, 1.0)
	return p.distance_to(a + ab * t)
