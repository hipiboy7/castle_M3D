extends "res://tests/helpers.gd"
## 원작 2D 웹툰 포트레이트 레지스트리(src/view/portraits.gd) · 스탠딩/대사창/컷인 레이아웃(src/ui/webtoon_stage.gd) ·
## 프롤로그 리빌 장면 로직(src/combat/scene.gd) 순수 함수 단위 테스트.

const Portraits = preload("res://src/view/portraits.gd")
const WebtoonStage = preload("res://src/ui/webtoon_stage.gd")
const Stage = preload("res://src/combat/stage.gd")
const Scene = preload("res://src/combat/scene.gd")


func test_portrait_aliases_and_paths() -> void:
	check(Portraits.key_of("kimshin") == "kimshin", "김신 id 매핑")
	check(Portraits.key_of("kim_coat_a") == "kimshin", "김신 코트 _a 접미사 매핑")
	check(Portraits.key_of("kim_p1_blade") == "kimshin", "김신 1부 단검 매핑")
	check(Portraits.key_of("kimshin_shadow") == "kimshin_shadow", "김신 프롤로그 어둠 리빌 매핑")
	check(Portraits.key_of("baek") == "baekdochan", "백도찬 look 매핑")
	check(Portraits.key_of("risa_p1") == "risa", "리사 프롤로그 매핑")
	check(Portraits.key_of("jintae") == "jintae", "서진태 매핑")
	check(Portraits.key_of("ojiin") == "ojiin", "오지인 매핑")
	check(Portraits.key_of("client_woman") == "client_woman", "의뢰인 여성 매핑")
	check(Portraits.key_of("woojin") == "woojin", "피우진 매핑")
	check(Portraits.key_of("shingen") == "shingen", "신겐 매핑")
	check(Portraits.key_of("unknown_mob") == "", "미등록 인물은 빈 문자열")
	check(Portraits.key_by_name("김신") == "kimshin", "한글 이름 김신 매핑")
	check(Portraits.key_by_name("리사") == "risa", "한글 이름 리사 매핑")
	check(Portraits.key_by_name("백도찬") == "baekdochan", "한글 이름 백도찬 매핑")
	check(Portraits.key_by_name("피우진") == "woojin", "한글 이름 피우진 매핑")
	check(Portraits.key_by_name("윤덕수") == "yundeoksu", "한글 이름 윤덕수 매핑")
	check(Portraits.SPECS.size() >= 100, "전 챕터 원작 인물 100명 이상 등록 (%d)" % Portraits.SPECS.size())
	for k in ["kimshin", "kimshin_shadow", "baekdochan", "risa", "jintae", "ojiin", "client_woman", "woojin", "gunter", "yundeoksu", "namgunghyuk", "shingen"]:
		check(Portraits.has_stand(k) and Portraits.has_hud(k), "%s 스탠딩 · HUD 등록" % k)
		check(FileAccess.file_exists(Portraits.stand_path(k)), "%s 스탠딩 JPG 존재" % k)
		check(FileAccess.file_exists(Portraits.hud_path(k)), "%s HUD JPG 존재" % k)
	for ck in ["kimshin", "kimshin_shadow", "baekdochan", "jintae", "ojiin", "woojin", "gunter", "shingen", "yundeoksu", "namgunghyuk"]:
		check(Portraits.has_cutin(ck) and FileAccess.file_exists(Portraits.cutin_path(ck)), "%s 컷인 JPG 존재" % ck)


func test_portrait_side_and_facing() -> void:
	check(Portraits.side_of("kimshin", 0) == -1, "아군 김신은 왼쪽")
	check(Portraits.side_of("baekdochan", 1) == 1, "적 백도찬은 오른쪽")
	check(Portraits.side_of("risa", 0) == 1, "리사는 오른쪽 선호")
	check(Portraits.side_of("client_woman", 0) == -1, "의뢰인은 왼쪽")
	check(Portraits.should_flip("kimshin", -1) == true, "왼쪽 김신은 오른쪽을 보도록 반전")
	check(Portraits.should_flip("baekdochan", 1) == false, "오른쪽 백도찬은 원래 왼쪽/정면을 봄")
	check(Portraits.should_flip("risa", 1) == true, "오른쪽 리사(바 앉은 컷 오른쪽 향함)는 중앙(왼쪽)을 보도록 반전")
	check(Portraits.should_flip("client_woman", -1) == true, "왼쪽 의뢰인은 중앙(오른쪽)을 보도록 반전")
	check(Portraits.should_flip("jintae", -1) == false, "왼쪽 서진태는 원래 오른쪽을 봄")
	check(Portraits.should_flip("jintae", 1) == true, "오른쪽 서진태는 왼쪽을 보도록 반전")


func test_webtoon_stage_layout_style_and_parry_rule() -> void:
	check(WebtoonStage.style_of("(속말이다)") == "think", "괄호 대사는 think")
	check(WebtoonStage.style_of("죽여주마!") == "shout", "느낌표 대사는 shout")
	check(WebtoonStage.style_of("돌아가요.") == "talk", "일반 대사는 talk")
	check(WebtoonStage.should_cutin_parry(1) == true, "첫 쳐내기 성공 시 사선 컷인 발동")
	check(WebtoonStage.should_cutin_parry(2) == false, "2번째 쳐내기부터 컷인 도배 방지")
	check(WebtoonStage.should_cutin_parry(5) == false, "반복 쳐내기 컷인 미발동")
	for sa in [Rect2(0, 0, 1280, 720), Rect2(44, 0, 1800, 700), Rect2(0, 0, 1280, 1067)]:
		var lr := WebtoonStage.stand_rect(sa, -1)
		var rr := WebtoonStage.stand_rect(sa, 1)
		var dlg := WebtoonStage.dialogue_rect(sa)
		var cdlg := WebtoonStage.combat_dialogue_rect(sa)
		check(lr.position.x >= sa.position.x and rr.end.x <= sa.end.x, "좌우 스탠딩 안전 영역 안 %s" % sa)
		check(not lr.intersects(rr), "좌우 스탠딩 안 겹침 %s" % sa)
		check(sa.encloses(dlg), "하단 장면 대사창 안전 영역 안 %s" % sa)
		check(sa.encloses(cdlg), "전투 중 컴팩트 대사 토스트 안전 영역 안 %s" % sa)
		check(cdlg.position.y >= sa.position.y + 120.0 and cdlg.end.y <= sa.end.y - 300.0,
			"전투 중 대사 토스트가 보스 바 아래 · 하단 터치 위 %s %s" % [sa, cdlg])
		var cr := WebtoonStage.cutin_rect(sa)
		check(cr.position.y >= sa.position.y + 84.0 and cr.end.y <= sa.end.y - 120.0,
			"컷인 띠가 보스 바 아래 · 하단 조작 위 %s %s" % [sa, cr])


func test_prologue_camera_and_kimshin_reveal() -> void:
	var d := Stage.make(1, {"chapter": "ch0", "room": 0})
	var ks = Scene.who_of(d, "kimshin", true)
	var cw = Scene.who_of(d, "client_woman", true)
	check(ks != null and cw != null, "프롤로그 주점 김신 · 의뢰인 존재")
	check(Scene.hidden(d).has(ks), "시작 시 김신은 어둠 속에 숨김 상태")
	check(not Scene.hidden(d).has(cw), "의뢰인은 시작부터 보임")
	# INTRO_T 경과 → bar_request 시작, 의뢰인 걷는 동안 카메라가 의뢰인을 추적
	for _i in 95:
		Stage.step(d, {})
	check(Scene.active(d), "주점 장면 시작")
	check(Scene.speaker(d) == cw, "의뢰인이 걸어 들어올 때 카메라 포커스는 의뢰인 (%s)" % [Scene.speaker(d).char_id if Scene.speaker(d) != null else "null"])
	check(Scene.hidden(d).has(ks), "의뢰인 입장 중 김신은 아직 숨김")
	# 끝까지 넘기기 → 리사 멘트 뒤 김신 리빌 이벤트 발생 확인
	var saw_reveal := false
	var saw_cutin := false
	for _k in 6000:
		var evs: Array = d["world"].events
		for ev in evs:
			if ev[0] == "reveal" and ev[1] == ks and bool(ev[2]):
				saw_reveal = true
			elif ev[0] == "cutin" and str(ev[1]) == "kimshin_shadow":
				saw_cutin = true
		d["world"].events.clear()
		Stage.step(d, {"attack": _k % 15 == 0})
		if saw_reveal and not Scene.hidden(d).has(ks):
			break
	check(saw_reveal and not Scene.hidden(d).has(ks), "리사 멘트 뒤 김신 스포트라이트 리빌 실행")
	check(saw_cutin, "김신 어둠 리빌 컷인 신호 발생")


func test_hud_portrait_boxes_no_overlap() -> void:
	const Hud = preload("res://src/ui/hud.gd")
	for sa in [Rect2(0, 0, 1280, 720), Rect2(44, 0, 1800, 700), Rect2(0, 0, 1280, 1067)]:
		var bx := Hud.portrait_boxes(sa)
		var hp: Rect2 = bx["hero_panel"]
		var bb: Rect2 = bx["boss_bar"]
		var bp: Rect2 = bx["boss_port"]
		check(sa.encloses(hp) and sa.encloses(bb) and sa.encloses(bp), "HUD 초상화 안전 영역 안 %s" % sa)
		check(not hp.intersects(bb), "조작 인물 패널(초상화 포함)이 보스 바와 안 겹침 %s" % sa)
		check(not bb.intersects(bp), "보스 초상화가 보스 바와 안 겹침 %s" % sa)
		check(bp.end.x <= sa.end.x - 160.0, "보스 초상화가 우측 상단 메뉴/FPS 와 안 겹침 %s" % sa)
