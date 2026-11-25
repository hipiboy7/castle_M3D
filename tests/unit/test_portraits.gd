extends "res://tests/helpers.gd"
## 2D 웹툰 포트레이트 레지스트리(src/view/portraits.gd) 및 스탠딩/컷인 레이아웃(src/ui/webtoon_stage.gd) 순수 함수 단위 테스트.

const Portraits = preload("res://src/view/portraits.gd")
const WebtoonStage = preload("res://src/ui/webtoon_stage.gd")


func test_portrait_aliases_and_paths() -> void:
	check(Portraits.key_of("kimshin") == "kimshin", "김신 id 매핑")
	check(Portraits.key_of("kim_coat_a") == "kimshin", "김신 코트 _a 접미사 매핑")
	check(Portraits.key_of("kim_p1_blade") == "kimshin", "김신 1부 단검 매핑")
	check(Portraits.key_of("baek") == "baekdochan", "백도찬 look 매핑")
	check(Portraits.key_of("risa_p1") == "risa", "리사 프롤로그 매핑")
	check(Portraits.key_of("jintae") == "jintae", "서진태 매핑")
	check(Portraits.key_of("ojiin") == "ojiin", "오지인 매핑")
	check(Portraits.key_of("client_woman") == "client_woman", "의뢰인 여성 매핑")
	check(Portraits.key_of("unknown_mob") == "", "미등록 인물은 빈 문자열")
	for k in ["kimshin", "baekdochan", "risa", "jintae", "ojiin", "client_woman"]:
		check(Portraits.has_stand(k) and Portraits.has_hud(k), "%s 스탠딩 · HUD 등록" % k)
		check(FileAccess.file_exists(Portraits.stand_path(k)), "%s 스탠딩 PNG 존재" % k)
		check(FileAccess.file_exists(Portraits.hud_path(k)), "%s HUD PNG 존재" % k)
	for ck in ["kimshin", "baekdochan", "jintae", "ojiin"]:
		check(Portraits.has_cutin(ck) and FileAccess.file_exists(Portraits.cutin_path(ck)), "%s 컷인 PNG 존재" % ck)


func test_portrait_side_and_facing() -> void:
	check(Portraits.side_of("kimshin", 0) == -1, "아군 김신은 왼쪽")
	check(Portraits.side_of("baekdochan", 1) == 1, "적 백도찬은 오른쪽")
	check(Portraits.side_of("risa", 0) == 1, "리사는 오른쪽 선호")
	check(Portraits.side_of("client_woman", 0) == -1, "의뢰인은 왼쪽")
	# 모든 인물이 화면 안쪽을 바라보도록 반전 여부 일관성 확인
	check(Portraits.should_flip("kimshin", -1) == true, "왼쪽 김신은 오른쪽을 보도록 반전")
	check(Portraits.should_flip("baekdochan", 1) == false, "오른쪽 백도찬은 원래 왼쪽을 봄")
	check(Portraits.should_flip("risa", 1) == false, "오른쪽 리사는 원래 왼쪽을 봄")
	check(Portraits.should_flip("client_woman", -1) == false, "왼쪽 의뢰인은 원래 오른쪽을 봄")
	check(Portraits.should_flip("jintae", -1) == false, "왼쪽 서진태는 원래 오른쪽을 봄")
	check(Portraits.should_flip("jintae", 1) == true, "오른쪽 서진태는 왼쪽을 보도록 반전")


func test_webtoon_stage_layout_and_style() -> void:
	check(WebtoonStage.style_of("(속말이다)") == "think", "괄호 대사는 think")
	check(WebtoonStage.style_of("죽여주마!") == "shout", "느낌표 대사는 shout")
	check(WebtoonStage.style_of("돌아가요.") == "talk", "일반 대사는 talk")
	for sa in [Rect2(0, 0, 1280, 720), Rect2(44, 0, 1800, 700), Rect2(0, 0, 1280, 1067)]:
		var lr := WebtoonStage.stand_rect(sa, -1)
		var rr := WebtoonStage.stand_rect(sa, 1)
		check(lr.position.x >= sa.position.x and rr.end.x <= sa.end.x, "좌우 스탠딩 안전 영역 안 %s" % sa)
		check(not lr.intersects(rr), "좌우 스탠딩 안 겹침 %s" % sa)
		var cr := WebtoonStage.cutin_rect(sa)
		check(cr.position.y >= sa.position.y + 84.0 and cr.end.y <= sa.end.y - 120.0,
			"컷인 띠가 보스 바 아래 · 하단 조작 위 %s %s" % [sa, cr])


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
